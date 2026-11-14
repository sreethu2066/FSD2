package com.cargo.controller;

import com.cargo.util.DBConnection;
import com.cargo.util.WebUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Driver Shipment Status Update Servlet.
 * Allows assigned drivers to advance delivery status (PICKED_UP, IN_TRANSIT, OUT_FOR_DELIVERY, DELIVERED),
 * automatically recording audit history in shipment_status, completing bookings upon delivery,
 * and returning the driver and vehicle to AVAILABLE status.
 */
@WebServlet("/driver/update-status")
public class DriverShipmentServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!WebUtil.checkAccess(request, response, "DRIVER")) {
            return;
        }

        request.setCharacterEncoding("UTF-8");
        int userId = WebUtil.userId(request);

        String shipmentIdStr = request.getParameter("shipmentId");
        String newStatus = request.getParameter("newStatus");
        String location = request.getParameter("location");
        String remarks = request.getParameter("remarks");

        if (shipmentIdStr == null || newStatus == null || shipmentIdStr.trim().isEmpty() || newStatus.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/driver/dashboard?error=invalid_input");
            return;
        }

        int shipmentId = Integer.parseInt(shipmentIdStr.trim());
        newStatus = newStatus.trim().toUpperCase();

        try (Connection con = DBConnection.getConnection()) {
            // 1. Resolve Driver ID
            int driverId = -1;
            String driverSql = "SELECT driver_id FROM drivers WHERE user_id = ?";
            try (PreparedStatement ps = con.prepareStatement(driverSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        driverId = rs.getInt("driver_id");
                    }
                }
            }

            if (driverId == -1) {
                response.sendRedirect(request.getContextPath() + "/driver/dashboard?error=driver_not_found");
                return;
            }

            // 2. Verify Shipment belongs to this driver
            int bookingId = -1;
            Integer vehicleId = null;

            String checkSql = "SELECT booking_id, vehicle_id, shipment_status FROM shipments WHERE shipment_id = ? AND driver_id = ?";
            try (PreparedStatement ps = con.prepareStatement(checkSql)) {
                ps.setInt(1, shipmentId);
                ps.setInt(2, driverId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        bookingId = rs.getInt("booking_id");
                        vehicleId = (Integer) rs.getObject("vehicle_id");
                    } else {
                        response.sendRedirect(request.getContextPath() + "/driver/dashboard?error=unauthorized_shipment");
                        return;
                    }
                }
            }

            // 3. Begin atomic transaction for status update
            con.setAutoCommit(false);
            try {
                String loc = (location != null && !location.trim().isEmpty()) ? location.trim() : "In Transit";
                String rem = (remarks != null && !remarks.trim().isEmpty()) ? remarks.trim() : "Status updated by driver";

                // Log into delivery_status audit table
                String logSql = "INSERT INTO delivery_status (shipment_id, status, location, remarks, updated_at) VALUES (?, ?, ?, ?, NOW())";
                try (PreparedStatement psLog = con.prepareStatement(logSql)) {
                    psLog.setInt(1, shipmentId);
                    psLog.setString(2, newStatus);
                    psLog.setString(3, loc);
                    psLog.setString(4, rem);
                    psLog.executeUpdate();
                }

                // Update shipments table
                if ("DELIVERED".equals(newStatus)) {
                    String updateShipment = "UPDATE shipments SET shipment_status = 'DELIVERED', current_location = ?, delivered_date = NOW() WHERE shipment_id = ?";
                    try (PreparedStatement psShip = con.prepareStatement(updateShipment)) {
                        psShip.setString(1, loc);
                        psShip.setInt(2, shipmentId);
                        psShip.executeUpdate();
                    }

                    // Complete booking
                    if (bookingId > 0) {
                        try (PreparedStatement psBook = con.prepareStatement("UPDATE bookings SET booking_status = 'COMPLETED' WHERE booking_id = ?")) {
                            psBook.setInt(1, bookingId);
                            psBook.executeUpdate();
                        }
                    }

                    // Release vehicle to AVAILABLE
                    if (vehicleId != null) {
                        try (PreparedStatement psVeh = con.prepareStatement("UPDATE vehicles SET status = 'AVAILABLE' WHERE vehicle_id = ?")) {
                            psVeh.setInt(1, vehicleId);
                            psVeh.executeUpdate();
                        }
                    }

                    // Release driver to AVAILABLE
                    try (PreparedStatement psDrv = con.prepareStatement("UPDATE drivers SET status = 'AVAILABLE' WHERE driver_id = ?")) {
                        psDrv.setInt(1, driverId);
                        psDrv.executeUpdate();
                    }

                } else {
                    StringBuilder updateShipment = new StringBuilder("UPDATE shipments SET shipment_status = ?, current_location = ?");
                    if ("PICKED_UP".equals(newStatus)) {
                        updateShipment.append(", shipped_date = COALESCE(shipped_date, NOW())");
                    }
                    updateShipment.append(" WHERE shipment_id = ?");

                    try (PreparedStatement psShip = con.prepareStatement(updateShipment.toString())) {
                        psShip.setString(1, newStatus);
                        psShip.setString(2, loc);
                        psShip.setInt(3, shipmentId);
                        psShip.executeUpdate();
                    }
                }

                con.commit();
                response.sendRedirect(request.getContextPath() + "/driver/dashboard?updated=success");

            } catch (SQLException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }

        } catch (SQLException e) {
            System.err.println("Driver shipment update error: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/driver/dashboard?error=server");
        }
    }
}
