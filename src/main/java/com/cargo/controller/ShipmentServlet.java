package com.cargo.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.cargo.util.DBConnection;
import com.cargo.util.WebUtil;

/**
 * Customer Shipments Servlet.
 * Lists customer shipments with real-time transit status, assigned vehicle & driver details,
 * and loads complete lifecycle tracking history from the shipment_status audit table.
 */
@WebServlet("/customer/shipments")
public class ShipmentServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!WebUtil.checkAccess(request, response, "CUSTOMER")) {
            return;
        }

        int userId = WebUtil.userId(request);
        List<Shipment> shipmentList = new ArrayList<>();

        String sql =
            "SELECT s.shipment_id, s.booking_id, s.tracking_number, " +
            "s.current_location, s.shipment_status, s.shipped_date, s.delivered_date, " +
            "v.vehicle_number, v.vehicle_type, d.driver_name, d.phone AS driver_phone, " +
            "cg.cargo_type, cg.weight_kg, pa.city AS pickup_city, da.city AS delivery_city " +
            "FROM shipments s " +
            "JOIN bookings b ON s.booking_id = b.booking_id " +
            "JOIN customers c ON b.customer_id = c.customer_id " +
            "JOIN cargo cg ON b.cargo_id = cg.cargo_id " +
            "JOIN addresses pa ON b.pickup_address_id = pa.address_id " +
            "JOIN addresses da ON b.delivery_address_id = da.address_id " +
            "LEFT JOIN vehicles v ON s.vehicle_id = v.vehicle_id " +
            "LEFT JOIN drivers d ON s.driver_id = d.driver_id " +
            "WHERE c.user_id = ? " +
            "ORDER BY s.shipment_id DESC";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Shipment s = new Shipment();
                    s.id = rs.getInt("shipment_id");
                    s.bookingId = rs.getInt("booking_id");
                    s.trackingNumber = rs.getString("tracking_number");
                    s.location = rs.getString("current_location");
                    s.status = rs.getString("shipment_status");
                    s.shippedDate = rs.getTimestamp("shipped_date");
                    s.deliveredDate = rs.getTimestamp("delivered_date");
                    s.vehicleNumber = rs.getString("vehicle_number");
                    s.vehicleType = rs.getString("vehicle_type");
                    s.driverName = rs.getString("driver_name");
                    s.driverPhone = rs.getString("driver_phone");
                    s.cargoType = rs.getString("cargo_type");
                    s.weightKg = rs.getBigDecimal("weight_kg");
                    s.pickupCity = rs.getString("pickup_city");
                    s.deliveryCity = rs.getString("delivery_city");

                    // Load status history timeline from delivery_status table
                    String statusSql = "SELECT status, location, remarks, updated_at FROM delivery_status " +
                                       "WHERE shipment_id = ? ORDER BY status_id ASC";
                    try (PreparedStatement psStatus = con.prepareStatement(statusSql)) {
                        psStatus.setInt(1, s.id);
                        try (ResultSet rsStatus = psStatus.executeQuery()) {
                            while (rsStatus.next()) {
                                StatusLog log = new StatusLog();
                                log.status = rsStatus.getString("status");
                                log.location = rsStatus.getString("location");
                                log.remarks = rsStatus.getString("remarks");
                                log.updatedAt = rsStatus.getTimestamp("updated_at");
                                s.statusHistory.add(log);
                            }
                        }
                    }

                    shipmentList.add(s);
                }
            }

        } catch (SQLException e) {
            System.err.println("ShipmentServlet error: " + e.getMessage());
            throw new ServletException("Unable to load customer shipments.", e);
        }

        request.setAttribute("shipmentList", shipmentList);
        request.getRequestDispatcher("/customer/shipments.jsp").forward(request, response);
    }

    public static class Shipment {
        public int id;
        public int bookingId;
        public String trackingNumber;
        public String location;
        public String status;
        public java.sql.Timestamp shippedDate;
        public java.sql.Timestamp deliveredDate;
        public String vehicleNumber;
        public String vehicleType;
        public String driverName;
        public String driverPhone;
        public String cargoType;
        public java.math.BigDecimal weightKg;
        public String pickupCity;
        public String deliveryCity;
        public List<StatusLog> statusHistory = new ArrayList<>();
    }

    public static class StatusLog {
        public String status;
        public String location;
        public String remarks;
        public java.sql.Timestamp updatedAt;
    }
}
