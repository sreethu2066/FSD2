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
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Customer Dashboard Home Servlet.
 * Displays key shipment KPIs, active deliveries, and recent booking activities for the logged-in customer.
 */
@WebServlet("/customer/dashboard")
public class CustomerHomeServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!WebUtil.checkAccess(req, resp, "CUSTOMER")) {
            return;
        }

        Integer customerId = WebUtil.customerId(req);
        if (customerId == null) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp?error=customer_profile_missing");
            return;
        }

        try (Connection con = DBConnection.getConnection()) {
            // 1. Fetch customer details
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT c.customer_id, c.full_name, c.phone, c.gender, c.date_of_birth, u.username, u.email " +
                    "FROM customers c JOIN users u ON u.user_id = c.user_id WHERE c.customer_id = ?")) {
                ps.setInt(1, customerId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        req.setAttribute("customerId", rs.getInt("customer_id"));
                        req.setAttribute("fullName", rs.getString("full_name"));
                        req.setAttribute("phone", rs.getString("phone"));
                        req.setAttribute("gender", rs.getString("gender"));
                        req.setAttribute("dob", rs.getDate("date_of_birth"));
                        req.setAttribute("username", rs.getString("username"));
                        req.setAttribute("email", rs.getString("email"));
                    }
                }
            }

            // 2. Aggregate KPI counts
            int totalBookings = 0;
            int activeShipments = 0;
            int completedDeliveries = 0;
            double totalSpent = 0.0;

            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT " +
                    "  COUNT(*) AS total_bookings, " +
                    "  SUM(CASE WHEN booking_status = 'COMPLETED' THEN 1 ELSE 0 END) AS completed_bookings, " +
                    "  SUM(CASE WHEN booking_status IN ('CONFIRMED', 'PENDING') THEN 1 ELSE 0 END) AS active_bookings, " +
                    "  COALESCE(SUM(CASE WHEN booking_status != 'CANCELLED' THEN total_amount ELSE 0 END), 0) AS total_spent " +
                    "FROM bookings WHERE customer_id = ?")) {
                ps.setInt(1, customerId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        totalBookings = rs.getInt("total_bookings");
                        completedDeliveries = rs.getInt("completed_bookings");
                        totalSpent = rs.getDouble("total_spent");
                    }
                }
            }

            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COUNT(*) FROM shipments sh " +
                    "JOIN bookings b ON b.booking_id = sh.booking_id " +
                    "WHERE b.customer_id = ? AND sh.shipment_status IN ('PENDING', 'PICKED_UP', 'IN_TRANSIT', 'OUT_FOR_DELIVERY')")) {
                ps.setInt(1, customerId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        activeShipments = rs.getInt(1);
                    }
                }
            }

            req.setAttribute("totalBookings", totalBookings);
            req.setAttribute("activeShipments", activeShipments);
            req.setAttribute("completedDeliveries", completedDeliveries);
            req.setAttribute("totalSpent", totalSpent);

            // 3. Recent Bookings (Limit 5)
            List<Map<String, Object>> recentBookings = new ArrayList<>();
            String recentSql =
                    "SELECT b.booking_id, b.booking_date, b.booking_status, b.total_amount, " +
                    "       ca.cargo_type, ca.weight_kg, " +
                    "       pa.city AS pickup_city, da.city AS delivery_city, " +
                    "       sh.tracking_number, sh.shipment_status, sh.current_location " +
                    "FROM bookings b " +
                    "JOIN cargo ca ON ca.cargo_id = b.cargo_id " +
                    "JOIN addresses pa ON pa.address_id = b.pickup_address_id " +
                    "JOIN addresses da ON da.address_id = b.delivery_address_id " +
                    "LEFT JOIN shipments sh ON sh.booking_id = b.booking_id " +
                    "WHERE b.customer_id = ? ORDER BY b.booking_id DESC LIMIT 5";

            try (PreparedStatement ps = con.prepareStatement(recentSql)) {
                ps.setInt(1, customerId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> row = new HashMap<>();
                        row.put("bookingId", rs.getInt("booking_id"));
                        row.put("bookingDate", rs.getTimestamp("booking_date"));
                        row.put("bookingStatus", rs.getString("booking_status"));
                        row.put("totalAmount", rs.getBigDecimal("total_amount"));
                        row.put("cargoType", rs.getString("cargo_type"));
                        row.put("weightKg", rs.getBigDecimal("weight_kg"));
                        row.put("pickupCity", rs.getString("pickup_city"));
                        row.put("deliveryCity", rs.getString("delivery_city"));
                        row.put("trackingNumber", rs.getString("tracking_number"));
                        row.put("shipmentStatus", rs.getString("shipment_status"));
                        row.put("currentLocation", rs.getString("current_location"));
                        recentBookings.add(row);
                    }
                }
            }
            req.setAttribute("recentBookings", recentBookings);

        } catch (SQLException e) {
            System.err.println("CustomerHomeServlet error: " + e.getMessage());
            throw new ServletException("Unable to load customer dashboard data", e);
        }

        req.getRequestDispatcher("/customer/dashboard.jsp").forward(req, resp);
    }
}
