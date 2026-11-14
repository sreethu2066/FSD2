
package com.cargo.controller;

import com.cargo.util.DBConnection;

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
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/admin/reports")
public class AdminReportsServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private boolean isAdmin(HttpServletRequest request) {
        HttpSession session = request.getSession(false);

        return session != null
            && "admin".equalsIgnoreCase(
                String.valueOf(session.getAttribute("role"))
            );
    }

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        if (!isAdmin(request)) {
            response.sendRedirect(
                request.getContextPath() + "/login.jsp"
            );
            return;
        }

        Map<String, Object> stats = new HashMap<>();
        List<Map<String, Object>> recentBookings = new ArrayList<>();
        List<Map<String, Object>> shipmentStats = new ArrayList<>();

        String statsSql =
            "SELECT COUNT(*) AS total_bookings, " +
            "COALESCE(SUM(CASE WHEN booking_status='PENDING' " +
            "THEN 1 ELSE 0 END),0) AS pending_bookings, " +
            "COALESCE(SUM(CASE WHEN booking_status='CONFIRMED' " +
            "THEN 1 ELSE 0 END),0) AS confirmed_bookings, " +
            "COALESCE(SUM(CASE WHEN booking_status='COMPLETED' " +
            "THEN 1 ELSE 0 END),0) AS completed_bookings, " +
            "COALESCE(SUM(CASE WHEN booking_status='CANCELLED' " +
            "THEN 1 ELSE 0 END),0) AS cancelled_bookings, " +
            "COALESCE(SUM(total_amount),0) AS total_booking_amount " +
            "FROM bookings";

        String paymentSql =
            "SELECT COALESCE(SUM(amount),0) AS total_revenue " +
            "FROM payments WHERE payment_status='SUCCESS'";

        String recentSql =
            "SELECT booking_id, customer_id, booking_date, " +
            "booking_status, total_amount " +
            "FROM bookings ORDER BY booking_id DESC LIMIT 10";

        String shipmentSql =
            "SELECT shipment_status, COUNT(*) AS total " +
            "FROM shipments GROUP BY shipment_status " +
            "ORDER BY shipment_status";

        try (Connection con = DBConnection.getConnection()) {

            try (PreparedStatement ps = con.prepareStatement(statsSql);
                 ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    stats.put("totalBookings",
                            rs.getInt("total_bookings"));
                    stats.put("pendingBookings",
                            rs.getInt("pending_bookings"));
                    stats.put("confirmedBookings",
                            rs.getInt("confirmed_bookings"));
                    stats.put("completedBookings",
                            rs.getInt("completed_bookings"));
                    stats.put("cancelledBookings",
                            rs.getInt("cancelled_bookings"));
                    stats.put("totalBookingAmount",
                            rs.getBigDecimal("total_booking_amount"));
                }
            }

            try (PreparedStatement ps = con.prepareStatement(paymentSql);
                 ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    stats.put("totalRevenue",
                            rs.getBigDecimal("total_revenue"));
                }
            }

            try (PreparedStatement ps = con.prepareStatement(recentSql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("bookingId", rs.getInt("booking_id"));
                    row.put("customerId", rs.getInt("customer_id"));
                    row.put("bookingDate", rs.getTimestamp("booking_date"));
                    row.put("status", rs.getString("booking_status"));
                    row.put("amount", rs.getBigDecimal("total_amount"));
                    recentBookings.add(row);
                }
            }

            try (PreparedStatement ps =
                    con.prepareStatement(shipmentSql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("status", rs.getString("shipment_status"));
                    row.put("total", rs.getInt("total"));
                    shipmentStats.add(row);
                }
            }

        } catch (Exception e) {
            throw new ServletException(
                "Unable to generate admin reports.", e
            );
        }

        request.setAttribute("stats", stats);
        request.setAttribute("recentBookings", recentBookings);
        request.setAttribute("shipmentStats", shipmentStats);

        request.getRequestDispatcher("/admin/reports.jsp")
               .forward(request, response);
    }
}
