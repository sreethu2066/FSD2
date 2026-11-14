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
import javax.servlet.http.HttpSession;

import com.cargo.model.Feedback;
import com.cargo.util.DBConnection;

/**
 * Servlet for Admin to view and delete customer feedback.
 */

public class AdminFeedbackServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // Alias for backward compatibility if needed
    public static class Feedback extends com.cargo.model.Feedback {}

    private boolean checkAdmin(HttpServletRequest request, HttpServletResponse response) throws IOException {
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

        if (!checkAdmin(request, response)) {
            return;
        }

        List<com.cargo.model.Feedback> feedbackList = new ArrayList<>();
        String ratingFilter = request.getParameter("rating");
        String search = request.getParameter("q");

        int totalCount = 0;
        int ratingSum = 0;
        int fiveStarCount = 0;
        int lowRatingCount = 0;

        StringBuilder sql = new StringBuilder(
            "SELECT f.feedback_id, f.customer_id, f.booking_id, f.rating, f.comments, f.feedback_date, " +
            "c.full_name AS customer_name, c.phone AS customer_phone, u.username AS customer_username, " +
            "cg.cargo_type, s.tracking_number " +
            "FROM feedback f " +
            "JOIN customers c ON f.customer_id = c.customer_id " +
            "JOIN users u ON c.user_id = u.user_id " +
            "JOIN bookings b ON f.booking_id = b.booking_id " +
            "LEFT JOIN cargo cg ON b.cargo_id = cg.cargo_id " +
            "LEFT JOIN shipments s ON b.booking_id = s.booking_id " +
            "WHERE 1=1 "
        );

        List<Object> params = new ArrayList<>();

        if (ratingFilter != null && !ratingFilter.trim().isEmpty() && !"ALL".equalsIgnoreCase(ratingFilter)) {
            try {
                params.add(Integer.parseInt(ratingFilter.trim()));
                sql.append("AND f.rating = ? ");
            } catch (NumberFormatException ignored) {}
        }

        if (search != null && !search.trim().isEmpty()) {
            sql.append("AND (c.full_name LIKE ? OR u.username LIKE ? OR CAST(f.booking_id AS CHAR) LIKE ? OR s.tracking_number LIKE ? OR f.comments LIKE ?) ");
            String pattern = "%" + search.trim() + "%";
            for (int i = 0; i < 5; i++) {
                params.add(pattern);
            }
        }

        sql.append("ORDER BY f.feedback_date DESC, f.feedback_id DESC");

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql.toString())) {

            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    com.cargo.model.Feedback f = new com.cargo.model.Feedback();
                    f.setFeedbackId(rs.getInt("feedback_id"));
                    f.setCustomerId(rs.getInt("customer_id"));
                    f.setBookingId(rs.getInt("booking_id"));
                    f.setRating(rs.getInt("rating"));
                    f.setComments(rs.getString("comments"));
                    f.setFeedbackDate(rs.getTimestamp("feedback_date"));
                    f.setCustomerName(rs.getString("customer_name"));
                    f.setCustomerPhone(rs.getString("customer_phone"));
                    f.setCustomerUsername(rs.getString("customer_username"));
                    f.setCargoType(rs.getString("cargo_type"));
                    f.setTrackingNumber(rs.getString("tracking_number"));

                    feedbackList.add(f);

                    totalCount++;
                    ratingSum += f.getRating();
                    if (f.getRating() == 5) {
                        fiveStarCount++;
                    } else if (f.getRating() <= 2) {
                        lowRatingCount++;
                    }
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
            throw new ServletException("Unable to load feedback from database.", e);
        }

        // Calculate average rating rounded to 1 decimal place
        double avgRating = totalCount > 0 ? Math.round(((double) ratingSum / totalCount) * 10.0) / 10.0 : 0.0;

        request.setAttribute("feedbackList", feedbackList);
        request.setAttribute("totalCount", totalCount);
        request.setAttribute("avgRating", avgRating);
        request.setAttribute("fiveStarCount", fiveStarCount);
        request.setAttribute("lowRatingCount", lowRatingCount);
        request.setAttribute("selectedRating", ratingFilter);
        request.setAttribute("searchTerm", search);

        request.getRequestDispatcher("/admin/feedback.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!checkAdmin(request, response)) {
            return;
        }

        String action = request.getParameter("action");
        String idValue = request.getParameter("feedbackId");

        if ("delete".equalsIgnoreCase(action) && idValue != null) {
            try {
                int feedbackId = Integer.parseInt(idValue.trim());
                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement("DELETE FROM feedback WHERE feedback_id = ?")) {
                    ps.setInt(1, feedbackId);
                    ps.executeUpdate();
                    response.sendRedirect(request.getContextPath() + "/admin/feedback?success=deleted");
                    return;
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        response.sendRedirect(request.getContextPath() + "/admin/feedback?error=invalid_action");
    }
}
