package com.cargo.controller;

import com.cargo.util.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.io.IOException;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Admin Shipment Management Servlet.
 * Handles fleet driver & vehicle assignment with strict capacity validation (vehicle.capacity_kg >= cargo.weight_kg),
 * lifecycle status tracking on shipments.shipment_status, and audit logging into delivery_status.
 */
@WebServlet("/admin/shipments")
public class AdminShipmentServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // Allowed ENUM values from MySQL schema for shipments.shipment_status
    private static final Set<String> VALID_STATUSES = new HashSet<>(Arrays.asList(
        "PENDING", "PICKED_UP", "IN_TRANSIT", "OUT_FOR_DELIVERY", "DELIVERED", "FAILED"
    ));

    private boolean isAdmin(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null
                || !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
            return false;
        }
        return true;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!isAdmin(request, response)) {
            return;
        }

        List<Map<String, Object>> shipments = new ArrayList<>();
        List<Map<String, Object>> availableVehicles = new ArrayList<>();
        List<Map<String, Object>> availableDrivers = new ArrayList<>();

        String shipmentSql =
            "SELECT s.shipment_id, s.booking_id, s.tracking_number, s.current_location, " +
            "s.shipment_status, s.shipped_date, s.delivered_date, s.vehicle_id, s.driver_id, " +
            "v.vehicle_number, v.vehicle_type, v.capacity_kg, " +
            "d.driver_name, d.phone AS driver_phone, " +
            "b.total_amount, cg.cargo_type, cg.weight_kg, " +
            "c.full_name AS customer_name, c.phone AS customer_phone, " +
            "pa.city AS pickup_city, da.city AS delivery_city " +
            "FROM shipments s " +
            "JOIN bookings b ON s.booking_id = b.booking_id " +
            "JOIN customers c ON b.customer_id = c.customer_id " +
            "JOIN cargo cg ON b.cargo_id = cg.cargo_id " +
            "JOIN addresses pa ON b.pickup_address_id = pa.address_id " +
            "JOIN addresses da ON b.delivery_address_id = da.address_id " +
            "LEFT JOIN vehicles v ON s.vehicle_id = v.vehicle_id " +
            "LEFT JOIN drivers d ON s.driver_id = d.driver_id " +
            "ORDER BY s.shipment_id DESC";

        String vehicleSql =
            "SELECT vehicle_id, vehicle_number, vehicle_type, capacity_kg FROM vehicles " +
            "WHERE status = 'AVAILABLE' ORDER BY capacity_kg ASC, vehicle_number ASC";

        String driverSql =
            "SELECT driver_id, driver_name, phone, license_number FROM drivers " +
            "WHERE status = 'AVAILABLE' ORDER BY driver_name ASC";

        try (Connection con = DBConnection.getConnection()) {

            try (PreparedStatement ps = con.prepareStatement(shipmentSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("shipmentId", rs.getInt("shipment_id"));
                    row.put("bookingId", rs.getInt("booking_id"));
                    row.put("trackingNumber", rs.getString("tracking_number"));
                    row.put("currentLocation", rs.getString("current_location"));
                    row.put("status", rs.getString("shipment_status"));
                    row.put("shippedDate", rs.getTimestamp("shipped_date"));
                    row.put("deliveredDate", rs.getTimestamp("delivered_date"));
                    row.put("vehicleId", rs.getObject("vehicle_id"));
                    row.put("driverId", rs.getObject("driver_id"));
                    row.put("vehicleNumber", rs.getString("vehicle_number"));
                    row.put("vehicleType", rs.getString("vehicle_type"));
                    row.put("vehicleCapacity", rs.getBigDecimal("capacity_kg"));
                    row.put("driverName", rs.getString("driver_name"));
                    row.put("driverPhone", rs.getString("driver_phone"));
                    row.put("totalAmount", rs.getBigDecimal("total_amount"));
                    row.put("cargoType", rs.getString("cargo_type"));
                    row.put("weightKg", rs.getBigDecimal("weight_kg"));
                    row.put("customerName", rs.getString("customer_name"));
                    row.put("customerPhone", rs.getString("customer_phone"));
                    row.put("pickupCity", rs.getString("pickup_city"));
                    row.put("deliveryCity", rs.getString("delivery_city"));
                    shipments.add(row);
                }
            }

            try (PreparedStatement ps = con.prepareStatement(vehicleSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("vehicleId", rs.getInt("vehicle_id"));
                    row.put("vehicleNumber", rs.getString("vehicle_number"));
                    row.put("vehicleType", rs.getString("vehicle_type"));
                    row.put("capacityKg", rs.getBigDecimal("capacity_kg"));
                    availableVehicles.add(row);
                }
            }

            try (PreparedStatement ps = con.prepareStatement(driverSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("driverId", rs.getInt("driver_id"));
                    row.put("driverName", rs.getString("driver_name"));
                    row.put("phone", rs.getString("phone"));
                    row.put("license", rs.getString("license_number"));
                    availableDrivers.add(row);
                }
            }

            request.setAttribute("shipments", shipments);
            request.setAttribute("availableVehicles", availableVehicles);
            request.setAttribute("availableDrivers", availableDrivers);

            request.getRequestDispatcher("/admin/shipments.jsp").forward(request, response);

        } catch (SQLException e) {
            System.err.println("AdminShipmentServlet doGet error: " + e.getMessage());
            throw new ServletException("Unable to load shipments.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!isAdmin(request, response)) {
            return;
        }

        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");

        try {
            if ("assign".equalsIgnoreCase(action)) {
                assignVehicleAndDriver(request);
                response.sendRedirect(request.getContextPath() + "/admin/shipments?success=assigned");
            } else if ("updateStatus".equalsIgnoreCase(action)) {
                updateShipmentStatus(request);
                response.sendRedirect(request.getContextPath() + "/admin/shipments?success=status_updated");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/shipments?error=invalid_action");
            }

        } catch (IllegalArgumentException e) {
            String errorMsg = URLEncoder.encode(e.getMessage(), StandardCharsets.UTF_8.toString());
            response.sendRedirect(request.getContextPath() + "/admin/shipments?error=" + errorMsg);
        } catch (SQLException e) {
            System.err.println("AdminShipmentServlet database error: " + e.getMessage());
            String errorMsg = URLEncoder.encode("Database error: " + e.getMessage(), StandardCharsets.UTF_8.toString());
            response.sendRedirect(request.getContextPath() + "/admin/shipments?error=" + errorMsg);
        } catch (Exception e) {
            System.err.println("AdminShipmentServlet unexpected error: " + e.getMessage());
            String errorMsg = URLEncoder.encode("An error occurred: " + e.getMessage(), StandardCharsets.UTF_8.toString());
            response.sendRedirect(request.getContextPath() + "/admin/shipments?error=" + errorMsg);
        }
    }

    private void assignVehicleAndDriver(HttpServletRequest request) throws SQLException {
        String shipmentIdStr = request.getParameter("shipmentId");
        String vehicleIdStr = request.getParameter("vehicleId");
        String driverIdStr = request.getParameter("driverId");

        if (shipmentIdStr == null || vehicleIdStr == null || driverIdStr == null
                || shipmentIdStr.trim().isEmpty() || vehicleIdStr.trim().isEmpty() || driverIdStr.trim().isEmpty()) {
            throw new IllegalArgumentException("Shipment ID, Vehicle, and Driver selection are required.");
        }

        int shipmentId = Integer.parseInt(shipmentIdStr.trim());
        int vehicleId = Integer.parseInt(vehicleIdStr.trim());
        int driverId = Integer.parseInt(driverIdStr.trim());

        try (Connection con = DBConnection.getConnection()) {
            con.setAutoCommit(false);
            try {
                // 1. Check vehicle availability and capacity
                BigDecimal vehicleCapacity;
                try (PreparedStatement ps = con.prepareStatement("SELECT capacity_kg, status FROM vehicles WHERE vehicle_id = ? FOR UPDATE")) {
                    ps.setInt(1, vehicleId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException("Selected vehicle does not exist.");
                        }
                        if (!"AVAILABLE".equals(rs.getString("status"))) {
                            throw new IllegalArgumentException("Selected vehicle is no longer available.");
                        }
                        vehicleCapacity = rs.getBigDecimal("capacity_kg");
                    }
                }

                // 2. Check driver availability
                try (PreparedStatement ps = con.prepareStatement("SELECT status FROM drivers WHERE driver_id = ? FOR UPDATE")) {
                    ps.setInt(1, driverId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException("Selected driver does not exist.");
                        }
                        if (!"AVAILABLE".equals(rs.getString("status"))) {
                            throw new IllegalArgumentException("Selected driver is no longer available.");
                        }
                    }
                }

                // 3. Fetch cargo weight and validate capacity (vehicle.capacity_kg >= cargo.weight_kg)
                BigDecimal cargoWeight;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT cg.weight_kg FROM shipments s " +
                        "JOIN bookings b ON s.booking_id = b.booking_id " +
                        "JOIN cargo cg ON b.cargo_id = cg.cargo_id " +
                        "WHERE s.shipment_id = ?")) {
                    ps.setInt(1, shipmentId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException("Shipment or cargo record not found.");
                        }
                        cargoWeight = rs.getBigDecimal("weight_kg");
                    }
                }

                if (vehicleCapacity != null && cargoWeight != null && vehicleCapacity.compareTo(cargoWeight) < 0) {
                    throw new IllegalArgumentException("Capacity validation failed: Vehicle capacity (" + vehicleCapacity +
                            " kg) is less than cargo weight (" + cargoWeight + " kg). Please select a higher-capacity vehicle.");
                }

                // 4. Update shipment with assigned driver and vehicle, advancing status to PICKED_UP
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE shipments SET vehicle_id = ?, driver_id = ?, shipment_status = 'PICKED_UP', " +
                        "shipped_date = COALESCE(shipped_date, NOW()), current_location = 'Dispatched from Hub' " +
                        "WHERE shipment_id = ?")) {
                    ps.setInt(1, vehicleId);
                    ps.setInt(2, driverId);
                    ps.setInt(3, shipmentId);
                    ps.executeUpdate();
                }

                // 5. Update vehicle status to IN_USE and driver status to ASSIGNED
                try (PreparedStatement ps = con.prepareStatement("UPDATE vehicles SET status = 'IN_USE' WHERE vehicle_id = ?")) {
                    ps.setInt(1, vehicleId);
                    ps.executeUpdate();
                }

                try (PreparedStatement ps = con.prepareStatement("UPDATE drivers SET status = 'ASSIGNED' WHERE driver_id = ?")) {
                    ps.setInt(1, driverId);
                    ps.executeUpdate();
                }

                // 6. Log into delivery_status audit trail table
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO delivery_status (shipment_id, status, location, remarks, updated_at) " +
                        "VALUES (?, 'PICKED_UP', 'Dispatched from Hub', 'Assigned driver and vehicle. Dispatched for delivery.', NOW())")) {
                    ps.setInt(1, shipmentId);
                    ps.executeUpdate();
                }

                con.commit();

            } catch (Exception e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    private void updateShipmentStatus(HttpServletRequest request) throws SQLException {
        String shipmentIdStr = request.getParameter("shipmentId");
        String status = request.getParameter("status");
        String location = request.getParameter("currentLocation");
        String remarks = request.getParameter("remarks");

        if (shipmentIdStr == null || shipmentIdStr.trim().isEmpty()) {
            throw new IllegalArgumentException("Shipment ID is required.");
        }
        if (status == null || status.trim().isEmpty()) {
            throw new IllegalArgumentException("Status cannot be empty.");
        }

        int shipmentId = Integer.parseInt(shipmentIdStr.trim());
        status = status.trim().toUpperCase();

        // Validate status enum value
        if (!VALID_STATUSES.contains(status)) {
            throw new IllegalArgumentException("Invalid shipment status: " + status + ". Allowed values: " + VALID_STATUSES);
        }

        if (location == null || location.trim().isEmpty()) {
            location = "In Transit";
        } else {
            location = location.trim();
        }

        if (remarks == null || remarks.trim().isEmpty()) {
            remarks = "Status updated to " + status + " by administrator";
        } else {
            remarks = remarks.trim();
        }

        try (Connection con = DBConnection.getConnection()) {
            con.setAutoCommit(false);
            try {
                if ("DELIVERED".equals(status)) {
                    // Update shipment to DELIVERED with delivered_date timestamp
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE shipments SET shipment_status = 'DELIVERED', delivered_date = NOW(), " +
                            "current_location = ? WHERE shipment_id = ?")) {
                        ps.setString(1, location);
                        ps.setInt(2, shipmentId);
                        ps.executeUpdate();
                    }

                    // Release vehicle to AVAILABLE
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE vehicles v JOIN shipments s ON v.vehicle_id = s.vehicle_id " +
                            "SET v.status = 'AVAILABLE' WHERE s.shipment_id = ?")) {
                        ps.setInt(1, shipmentId);
                        ps.executeUpdate();
                    }

                    // Release driver to AVAILABLE
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE drivers d JOIN shipments s ON d.driver_id = s.driver_id " +
                            "SET d.status = 'AVAILABLE' WHERE s.shipment_id = ?")) {
                        ps.setInt(1, shipmentId);
                        ps.executeUpdate();
                    }

                    // Mark related booking COMPLETED
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE bookings b JOIN shipments s ON b.booking_id = s.booking_id " +
                            "SET b.booking_status = 'COMPLETED' WHERE s.shipment_id = ?")) {
                        ps.setInt(1, shipmentId);
                        ps.executeUpdate();
                    }

                } else {
                    StringBuilder updateSql = new StringBuilder("UPDATE shipments SET shipment_status = ?, current_location = ?");
                    if ("PICKED_UP".equals(status)) {
                        updateSql.append(", shipped_date = COALESCE(shipped_date, NOW())");
                    }
                    updateSql.append(" WHERE shipment_id = ?");

                    try (PreparedStatement ps = con.prepareStatement(updateSql.toString())) {
                        ps.setString(1, status);
                        ps.setString(2, location);
                        ps.setInt(3, shipmentId);
                        ps.executeUpdate();
                    }
                }

                // Log into delivery_status audit table
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO delivery_status (shipment_id, status, location, remarks, updated_at) " +
                        "VALUES (?, ?, ?, ?, NOW())")) {
                    ps.setInt(1, shipmentId);
                    ps.setString(2, status);
                    ps.setString(3, location);
                    ps.setString(4, remarks);
                    ps.executeUpdate();
                }

                con.commit();

            } catch (Exception e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
    }
}
