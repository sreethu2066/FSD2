package com.cargo.controller;

import java.io.IOException;
import java.math.BigDecimal;
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

import com.cargo.util.DBConnection;
import com.cargo.util.WebUtil;

/**
 * Customer Payments Servlet.
 * Displays past payment receipts and enables customers to pay for their transport bookings
 * via CASH, UPI, CARD, or NET_BANKING with unique transaction ID generation.
 */
@WebServlet("/customer/payments")
public class PaymentServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!WebUtil.checkAccess(request, response, "CUSTOMER")) {
            return;
        }

        int userId = WebUtil.userId(request);
        List<Payment> paymentList = new ArrayList<>();
        List<PayableBooking> payableBookings = new ArrayList<>();

        try (Connection con = DBConnection.getConnection()) {

            // 1. Fetch completed and past payment history
            String historySql =
                "SELECT p.payment_id, p.booking_id, p.amount, " +
                "p.payment_method, p.payment_date, p.payment_status, " +
                "p.transaction_id, cg.cargo_type " +
                "FROM payments p " +
                "JOIN bookings b ON p.booking_id = b.booking_id " +
                "JOIN customers c ON b.customer_id = c.customer_id " +
                "JOIN cargo cg ON b.cargo_id = cg.cargo_id " +
                "WHERE c.user_id = ? " +
                "ORDER BY p.payment_id DESC";

            try (PreparedStatement ps = con.prepareStatement(historySql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Payment p = new Payment();
                        p.id = rs.getInt("payment_id");
                        p.bookingId = rs.getInt("booking_id");
                        p.amount = rs.getBigDecimal("amount");
                        p.method = rs.getString("payment_method");
                        p.paymentDate = rs.getTimestamp("payment_date");
                        p.status = rs.getString("payment_status");
                        p.transactionId = rs.getString("transaction_id");
                        p.cargoType = rs.getString("cargo_type");
                        paymentList.add(p);
                    }
                }
            }

            // 2. Fetch pending bookings that require payment
            String payableSql =
                "SELECT b.booking_id, b.total_amount, b.booking_status, " +
                "cg.cargo_type, pa.city AS pickup_city, da.city AS delivery_city " +
                "FROM bookings b " +
                "JOIN customers c ON b.customer_id = c.customer_id " +
                "JOIN cargo cg ON b.cargo_id = cg.cargo_id " +
                "JOIN addresses pa ON b.pickup_address_id = pa.address_id " +
                "JOIN addresses da ON b.delivery_address_id = da.address_id " +
                "WHERE c.user_id = ? " +
                "AND b.booking_status != 'CANCELLED' " +
                "AND NOT EXISTS (SELECT 1 FROM payments p WHERE p.booking_id = b.booking_id AND p.payment_status = 'SUCCESS') " +
                "ORDER BY b.booking_id DESC";

            try (PreparedStatement ps = con.prepareStatement(payableSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        PayableBooking pb = new PayableBooking();
                        pb.bookingId = rs.getInt("booking_id");
                        pb.amount = rs.getBigDecimal("total_amount");
                        pb.status = rs.getString("booking_status");
                        pb.cargoType = rs.getString("cargo_type");
                        pb.pickupCity = rs.getString("pickup_city");
                        pb.deliveryCity = rs.getString("delivery_city");
                        payableBookings.add(pb);
                    }
                }
            }

        } catch (SQLException e) {
            System.err.println("PaymentServlet doGet error: " + e.getMessage());
            throw new ServletException("Unable to load payment history.", e);
        }

        request.setAttribute("paymentList", paymentList);
        request.setAttribute("payableBookings", payableBookings);
        request.getRequestDispatcher("/customer/payments.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!WebUtil.checkAccess(request, response, "CUSTOMER")) {
            return;
        }

        request.setCharacterEncoding("UTF-8");
        int userId = WebUtil.userId(request);

        String bookingIdParam = request.getParameter("bookingId");
        String paymentMethod = request.getParameter("paymentMethod");

        if (bookingIdParam == null || bookingIdParam.trim().isEmpty() || paymentMethod == null || paymentMethod.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/customer/payments?error=missing_input");
            return;
        }

        int bookingId;
        try {
            bookingId = Integer.parseInt(bookingIdParam.trim());
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/customer/payments?error=invalid_id");
            return;
        }

        paymentMethod = paymentMethod.trim().toUpperCase();
        if (!paymentMethod.equals("CASH") && !paymentMethod.equals("UPI") && !paymentMethod.equals("CARD") && !paymentMethod.equals("NET_BANKING")) {
            paymentMethod = "CASH";
        }

        try (Connection con = DBConnection.getConnection()) {
            // Verify booking belongs to this customer and retrieve total amount
            BigDecimal amount = null;
            String checkSql = "SELECT b.total_amount FROM bookings b JOIN customers c ON b.customer_id = c.customer_id WHERE b.booking_id = ? AND c.user_id = ?";
            try (PreparedStatement ps = con.prepareStatement(checkSql)) {
                ps.setInt(1, bookingId);
                ps.setInt(2, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        amount = rs.getBigDecimal("total_amount");
                    } else {
                        response.sendRedirect(request.getContextPath() + "/customer/payments?error=unauthorized_booking");
                        return;
                    }
                }
            }

            // Check if already paid
            String paidCheck = "SELECT 1 FROM payments WHERE booking_id = ? AND payment_status = 'SUCCESS'";
            try (PreparedStatement ps = con.prepareStatement(paidCheck)) {
                ps.setInt(1, bookingId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        response.sendRedirect(request.getContextPath() + "/customer/payments?error=already_paid");
                        return;
                    }
                }
            }

            // Generate unique transaction ID
            String transactionId = "TXN-" + System.currentTimeMillis() + "-" + (int) (Math.random() * 9000 + 1000);

            // Record payment
            String insertSql = "INSERT INTO payments (booking_id, amount, payment_method, payment_status, transaction_id, payment_date) " +
                               "VALUES (?, ?, ?, 'SUCCESS', ?, NOW())";
            try (PreparedStatement ps = con.prepareStatement(insertSql)) {
                ps.setInt(1, bookingId);
                ps.setBigDecimal(2, amount);
                ps.setString(3, paymentMethod);
                ps.setString(4, transactionId);
                ps.executeUpdate();
            }

            response.sendRedirect(request.getContextPath() + "/customer/payments?success=payment_successful&txn=" + transactionId);

        } catch (SQLException e) {
            System.err.println("PaymentServlet doPost error: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/customer/payments?error=server");
        }
    }

    public static class Payment {
        public int id;
        public int bookingId;
        public BigDecimal amount;
        public String method;
        public java.sql.Timestamp paymentDate;
        public String status;
        public String transactionId;
        public String cargoType;
    }

    public static class PayableBooking {
        public int bookingId;
        public BigDecimal amount;
        public String status;
        public String cargoType;
        public String pickupCity;
        public String deliveryCity;
    }
}
