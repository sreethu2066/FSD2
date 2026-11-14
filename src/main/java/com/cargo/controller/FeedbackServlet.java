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

@WebServlet("/customer/feedback")
public class FeedbackServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    public static class EligibleBooking {
        private int bookingId;
        private String status;
        private String cargoType;
        private String trackingNumber;

        public int getBookingId() { return bookingId; }
        public void setBookingId(int bookingId) { this.bookingId = bookingId; }

        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }

        public String getCargoType() { return cargoType; }
        public void setCargoType(String cargoType) { this.cargoType = cargoType; }

        public String getTrackingNumber() { return trackingNumber; }
        public void setTrackingNumber(String trackingNumber) { this.trackingNumber = trackingNumber; }
    }

    private boolean isCustomer(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null
                || !"CUSTOMER".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
            return false;
        }
        return true;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!isCustomer(request, response)) {
            return;
        }

        HttpSession session = request.getSession(false);
        int userId = (Integer) session.getAttribute("userId");

        List<Feedback> feedbackList = new ArrayList<>();
        List<EligibleBooking> eligibleBookings = new ArrayList<>();
        int customerId = -1;

        try (Connection con = DBConnection.getConnection()) {
            // 1. Fetch customer_id for logged in user
            String customerSql = "SELECT customer_id FROM customers WHERE user_id = ?";
            try (PreparedStatement ps = con.prepareStatement(customerSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        customerId = rs.getInt("customer_id");
                    } else {
                        response.sendRedirect(request.getContextPath() + "/customer/profile?msg=complete_profile");
                        return;
                    }
                }
            }

            // 2. Fetch eligible completed bookings that haven't received feedback yet
            String eligibleSql =
                "SELECT b.booking_id, b.booking_status, cg.cargo_type, s.tracking_number " +
                "FROM bookings b " +
                "LEFT JOIN cargo cg ON b.cargo_id = cg.cargo_id " +
                "LEFT JOIN shipments s ON b.booking_id = s.booking_id " +
                "WHERE b.customer_id = ? " +
                "AND b.booking_status = 'COMPLETED' " +
                "AND NOT EXISTS (SELECT 1 FROM feedback f WHERE f.booking_id = b.booking_id) " +
                "ORDER BY b.booking_id DESC";

            try (PreparedStatement ps = con.prepareStatement(eligibleSql)) {
                ps.setInt(1, customerId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        EligibleBooking eb = new EligibleBooking();
                        eb.setBookingId(rs.getInt("booking_id"));
                        eb.setStatus(rs.getString("booking_status"));
                        eb.setCargoType(rs.getString("cargo_type"));
                        eb.setTrackingNumber(rs.getString("tracking_number"));
                        eligibleBookings.add(eb);
                    }
                }
            }

            // 3. Fetch past feedback submitted by this customer
            String feedbackSql =
                "SELECT f.feedback_id, f.customer_id, f.booking_id, f.rating, f.comments, f.feedback_date, " +
                "cg.cargo_type, s.tracking_number " +
                "FROM feedback f " +
                "JOIN bookings b ON f.booking_id = b.booking_id " +
                "LEFT JOIN cargo cg ON b.cargo_id = cg.cargo_id " +
                "LEFT JOIN shipments s ON b.booking_id = s.booking_id " +
                "WHERE f.customer_id = ? " +
                "ORDER BY f.feedback_date DESC, f.feedback_id DESC";

            try (PreparedStatement ps = con.prepareStatement(feedbackSql)) {
                ps.setInt(1, customerId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Feedback f = new Feedback();
                        f.setFeedbackId(rs.getInt("feedback_id"));
                        f.setCustomerId(rs.getInt("customer_id"));
                        f.setBookingId(rs.getInt("booking_id"));
                        f.setRating(rs.getInt("rating"));
                        f.setComments(rs.getString("comments"));
                        f.setFeedbackDate(rs.getTimestamp("feedback_date"));
                        f.setCargoType(rs.getString("cargo_type"));
                        f.setTrackingNumber(rs.getString("tracking_number"));
                        feedbackList.add(f);
                    }
                }
            }

            request.setAttribute("customerId", customerId);
            request.setAttribute("bookingList", eligibleBookings);
            request.setAttribute("feedbackList", feedbackList);

        } catch (SQLException e) {
            System.err.println("FeedbackServlet doGet error: " + e.getMessage());
            throw new ServletException("Unable to load customer feedback portal.", e);
        }

        request.getRequestDispatcher("/customer/feedback.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!isCustomer(request, response)) {
            return;
        }

        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession(false);
        int userId = (Integer) session.getAttribute("userId");

        String bookingIdParam = request.getParameter("bookingId");
        String ratingParam = request.getParameter("rating");
        String comments = request.getParameter("comments");

        if (bookingIdParam == null || bookingIdParam.trim().isEmpty() ||
            ratingParam == null || ratingParam.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/customer/feedback?error=missing_fields");
            return;
        }

        int bookingId;
        int rating;
        try {
            bookingId = Integer.parseInt(bookingIdParam.trim());
            rating = Integer.parseInt(ratingParam.trim());
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/customer/feedback?error=invalid_input");
            return;
        }

        // Validate rating range per database constraint (1 to 5)
        if (rating < 1 || rating > 5) {
            response.sendRedirect(request.getContextPath() + "/customer/feedback?error=invalid_rating");
            return;
        }

        if (comments != null) {
            comments = comments.trim();
            if (comments.length() > 2000) {
                comments = comments.substring(0, 2000);
            }
            if (comments.isEmpty()) {
                comments = null;
            }
        }

        try (Connection con = DBConnection.getConnection()) {
            // 1. Get customer ID
            int customerId;
            String customerSql = "SELECT customer_id FROM customers WHERE user_id = ?";
            try (PreparedStatement ps = con.prepareStatement(customerSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        customerId = rs.getInt("customer_id");
                    } else {
                        response.sendRedirect(request.getContextPath() + "/customer/profile");
                        return;
                    }
                }
            }

            // 2. Validate booking belongs to customer and is COMPLETED
            String verifyBookingSql =
                "SELECT booking_status FROM bookings WHERE booking_id = ? AND customer_id = ?";
            try (PreparedStatement ps = con.prepareStatement(verifyBookingSql)) {
                ps.setInt(1, bookingId);
                ps.setInt(2, customerId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        response.sendRedirect(request.getContextPath() + "/customer/feedback?error=unauthorized_booking");
                        return;
                    }
                    String status = rs.getString("booking_status");
                    if (!"COMPLETED".equalsIgnoreCase(status)) {
                        response.sendRedirect(request.getContextPath() + "/customer/feedback?error=not_completed");
                        return;
                    }
                }
            }

            // 3. Verify no duplicate feedback already exists for this booking
            String checkDuplicateSql = "SELECT feedback_id FROM feedback WHERE booking_id = ?";
            try (PreparedStatement ps = con.prepareStatement(checkDuplicateSql)) {
                ps.setInt(1, bookingId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        response.sendRedirect(request.getContextPath() + "/customer/feedback?error=duplicate");
                        return;
                    }
                }
            }

            // 4. Insert feedback
            String insertSql =
                "INSERT INTO feedback (customer_id, booking_id, rating, comments, feedback_date) " +
                "VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)";
            try (PreparedStatement ps = con.prepareStatement(insertSql)) {
                ps.setInt(1, customerId);
                ps.setInt(2, bookingId);
                ps.setInt(3, rating);
                ps.setString(4, comments);
                ps.executeUpdate();
            }

            response.sendRedirect(request.getContextPath() + "/customer/feedback?success=1");

        } catch (SQLException e) {
            System.err.println("FeedbackServlet doPost error: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/customer/feedback?error=db_error");
        }
    }
}
