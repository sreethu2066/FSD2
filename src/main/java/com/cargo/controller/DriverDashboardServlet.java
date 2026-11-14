package com.cargo.controller;

import com.cargo.util.DBConnection;
import com.cargo.util.WebUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
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
 * Driver Dashboard Servlet.
 * Displays assigned deliveries, current active vehicle, delivery route information,
 * and enables quick status transitions (PICKED_UP, IN_TRANSIT, OUT_FOR_DELIVERY, DELIVERED).
 */
@WebServlet("/driver/dashboard")
public class DriverDashboardServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!WebUtil.checkAccess(request, response, "DRIVER")) {
            return;
        }

        int userId = WebUtil.userId(request);
        HttpSession session = request.getSession(false);

        Map<String, Object> driverInfo = new HashMap<>();
        Map<String, Object> vehicleInfo = new HashMap<>();
        List<Map<String, Object>> activeDeliveries = new ArrayList<>();
        List<Map<String, Object>> completedDeliveries = new ArrayList<>();
        List<Map<String, Object>> driverReviews = new ArrayList<>();
        int driverReviewCount = 0;
        double driverAvgRating = 5.0;

        try (Connection con = DBConnection.getConnection()) {

            // 1. Fetch Driver Details
            int driverId = -1;
            String driverSql = "SELECT driver_id, driver_name, phone, license_number, experience_years, status FROM drivers WHERE user_id = ?";
            try (PreparedStatement ps = con.prepareStatement(driverSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        driverId = rs.getInt("driver_id");
                        driverInfo.put("driverId", driverId);
                        driverInfo.put("name", rs.getString("driver_name"));
                        driverInfo.put("phone", rs.getString("phone"));
                        driverInfo.put("license", rs.getString("license_number"));
                        driverInfo.put("experience", rs.getInt("experience_years"));
                        driverInfo.put("status", rs.getString("status"));
                        session.setAttribute("driverId", driverId);
                        session.setAttribute("driverStatus", rs.getString("status"));
                    }
                }
            }

            if (driverId != -1) {
                // 2. Fetch Assigned Vehicle from current active shipment
                String vehicleSql =
                    "SELECT v.vehicle_id, v.vehicle_number, v.vehicle_type, v.capacity_kg, v.status " +
                    "FROM shipments s " +
                    "JOIN vehicles v ON s.vehicle_id = v.vehicle_id " +
                    "WHERE s.driver_id = ? AND s.shipment_status NOT IN ('DELIVERED', 'FAILED') " +
                    "ORDER BY s.shipment_id DESC LIMIT 1";

                try (PreparedStatement ps = con.prepareStatement(vehicleSql)) {
                    ps.setInt(1, driverId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            vehicleInfo.put("vehicleId", rs.getInt("vehicle_id"));
                            vehicleInfo.put("number", rs.getString("vehicle_number"));
                            vehicleInfo.put("type", rs.getString("vehicle_type"));
                            vehicleInfo.put("model", rs.getString("vehicle_type")); // fallback alias
                            vehicleInfo.put("capacity", rs.getBigDecimal("capacity_kg"));
                            vehicleInfo.put("status", rs.getString("status"));
                        }
                    }
                }

                // 3. Fetch Active Deliveries Assigned to Driver
                String activeSql =
                    "SELECT s.shipment_id, s.tracking_number, s.shipment_status, s.current_location, s.shipped_date, " +
                    "b.booking_id, b.booking_date, b.pickup_date, b.expected_delivery_date, b.total_amount, " +
                    "c.full_name AS customer_name, c.phone AS customer_phone, " +
                    "cg.cargo_type, cg.weight_kg, cg.quantity, cg.fragile, cg.description, " +
                    "pa.address_line AS pickup_line, pa.city AS pickup_city, pa.pincode AS pickup_pincode, " +
                    "da.address_line AS delivery_line, da.city AS delivery_city, da.pincode AS delivery_pincode, " +
                    "v.vehicle_number, v.vehicle_type " +
                    "FROM shipments s " +
                    "JOIN bookings b ON s.booking_id = b.booking_id " +
                    "JOIN customers c ON b.customer_id = c.customer_id " +
                    "JOIN cargo cg ON b.cargo_id = cg.cargo_id " +
                    "JOIN addresses pa ON b.pickup_address_id = pa.address_id " +
                    "JOIN addresses da ON b.delivery_address_id = da.address_id " +
                    "LEFT JOIN vehicles v ON s.vehicle_id = v.vehicle_id " +
                    "WHERE s.driver_id = ? AND s.shipment_status NOT IN ('DELIVERED', 'FAILED') " +
                    "ORDER BY s.shipment_id DESC";

                try (PreparedStatement ps = con.prepareStatement(activeSql)) {
                    ps.setInt(1, driverId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            Map<String, Object> del = new HashMap<>();
                            del.put("shipmentId", rs.getInt("shipment_id"));
                            del.put("trackingNumber", rs.getString("tracking_number"));
                            del.put("status", rs.getString("shipment_status"));
                            del.put("currentLocation", rs.getString("current_location"));
                            del.put("shippedDate", rs.getTimestamp("shipped_date"));
                            del.put("bookingId", rs.getInt("booking_id"));
                            del.put("bookingDate", rs.getTimestamp("booking_date"));
                            del.put("pickupDate", rs.getDate("pickup_date"));
                            del.put("expectedDate", rs.getDate("expected_delivery_date"));
                            del.put("customerName", rs.getString("customer_name"));
                            del.put("customerPhone", rs.getString("customer_phone"));
                            del.put("cargoType", rs.getString("cargo_type"));
                            del.put("weight", rs.getBigDecimal("weight_kg"));
                            del.put("quantity", rs.getInt("quantity"));
                            del.put("fragile", rs.getBoolean("fragile"));
                            del.put("description", rs.getString("description"));
                            del.put("pickupAddress", rs.getString("pickup_line") + ", " + rs.getString("pickup_city") + " - " + rs.getString("pickup_pincode"));
                            del.put("deliveryAddress", rs.getString("delivery_line") + ", " + rs.getString("delivery_city") + " - " + rs.getString("delivery_pincode"));
                            del.put("vehicleNumber", rs.getString("vehicle_number"));
                            del.put("vehicleType", rs.getString("vehicle_type"));
                            activeDeliveries.add(del);
                        }
                    }
                }

                // 4. Fetch Completed Deliveries Assigned to Driver
                String compSql =
                    "SELECT s.shipment_id, s.tracking_number, s.shipment_status, s.delivered_date, " +
                    "b.booking_id, c.full_name AS customer_name, cg.cargo_type, cg.weight_kg, " +
                    "pa.city AS pickup_city, da.city AS delivery_city " +
                    "FROM shipments s " +
                    "JOIN bookings b ON s.booking_id = b.booking_id " +
                    "JOIN customers c ON b.customer_id = c.customer_id " +
                    "JOIN cargo cg ON b.cargo_id = cg.cargo_id " +
                    "JOIN addresses pa ON b.pickup_address_id = pa.address_id " +
                    "JOIN addresses da ON b.delivery_address_id = da.address_id " +
                    "WHERE s.driver_id = ? AND s.shipment_status = 'DELIVERED' " +
                    "ORDER BY s.delivered_date DESC LIMIT 10";

                try (PreparedStatement ps = con.prepareStatement(compSql)) {
                    ps.setInt(1, driverId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            Map<String, Object> del = new HashMap<>();
                            del.put("shipmentId", rs.getInt("shipment_id"));
                            del.put("trackingNumber", rs.getString("tracking_number"));
                            del.put("status", rs.getString("shipment_status"));
                            del.put("deliveredDate", rs.getTimestamp("delivered_date"));
                            del.put("bookingId", rs.getInt("booking_id"));
                            del.put("customerName", rs.getString("customer_name"));
                            del.put("cargoType", rs.getString("cargo_type"));
                            del.put("weight", rs.getBigDecimal("weight_kg"));
                            del.put("pickupCity", rs.getString("pickup_city"));
                            del.put("deliveryCity", rs.getString("delivery_city"));
                            completedDeliveries.add(del);
                        }
                    }
                }

                // 5. Fetch Feedback / Reviews for this driver's shipments
                String reviewSql =
                    "SELECT f.rating, f.comments, f.feedback_date, c.full_name AS customer_name " +
                    "FROM feedback f " +
                    "JOIN bookings b ON f.booking_id = b.booking_id " +
                    "JOIN shipments s ON b.booking_id = s.booking_id " +
                    "JOIN customers c ON f.customer_id = c.customer_id " +
                    "WHERE s.driver_id = ? ORDER BY f.feedback_date DESC LIMIT 5";

                int ratingSum = 0;
                try (PreparedStatement ps = con.prepareStatement(reviewSql)) {
                    ps.setInt(1, driverId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            Map<String, Object> rev = new HashMap<>();
                            int r = rs.getInt("rating");
                            rev.put("rating", r);
                            rev.put("comments", rs.getString("comments"));
                            rev.put("date", rs.getTimestamp("feedback_date"));
                            rev.put("customerName", rs.getString("customer_name"));
                            driverReviews.add(rev);
                            ratingSum += r;
                            driverReviewCount++;
                        }
                    }
                }
                if (driverReviewCount > 0) {
                    driverAvgRating = Math.round(((double) ratingSum / driverReviewCount) * 10.0) / 10.0;
                }
            }

            request.setAttribute("driverInfo", driverInfo);
            request.setAttribute("driver", driverInfo);
            request.setAttribute("vehicleInfo", vehicleInfo);
            request.setAttribute("vehicle", vehicleInfo);
            request.setAttribute("activeDeliveries", activeDeliveries);
            request.setAttribute("completedDeliveries", completedDeliveries);
            request.setAttribute("driverReviews", driverReviews);
            request.setAttribute("driverReviewCount", driverReviewCount);
            request.setAttribute("driverAvgRating", driverAvgRating);
            request.setAttribute("activeCount", activeDeliveries.size());
            request.setAttribute("completedCount", completedDeliveries.size());

            request.getRequestDispatcher("/driver/dashboard.jsp").forward(request, response);

        } catch (SQLException e) {
            System.err.println("DriverDashboardServlet doGet error: " + e.getMessage());
            throw new ServletException("Unable to load driver dashboard.", e);
        }
    }
}
