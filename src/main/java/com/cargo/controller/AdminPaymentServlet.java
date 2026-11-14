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
 * Servlet for Admin to view and update customer payment records.
 */

public class AdminPaymentServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // Subclass for JSP view compatibility
    public static class Payment extends com.cargo.model.Payment {
        public Payment() { super(); }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Check Admin authorization
        if (!WebUtil.checkAccess(request, response, "ADMIN")) {
            return;
        }

        List<Payment> payments = new ArrayList<>();
        String statusFilter = request.getParameter("status");
        String search = request.getParameter("q");

        StringBuilder sql = new StringBuilder(
            "SELECT p.payment_id, p.booking_id, p.amount, p.payment_method, p.payment_date, " +
            "p.payment_status, p.transaction_id, c.full_name AS customer_name, c.phone AS customer_phone, cg.cargo_type " +
            "FROM payments p " +
            "JOIN bookings b ON p.booking_id = b.booking_id " +
            "JOIN customers c ON b.customer_id = c.customer_id " +
            "JOIN cargo cg ON b.cargo_id = cg.cargo_id " +
            "WHERE 1=1 "
        );

        List<Object> params = new ArrayList<>();

        if (statusFilter != null && !statusFilter.trim().isEmpty() && !"ALL".equalsIgnoreCase(statusFilter)) {
            sql.append("AND p.payment_status = ? ");
            params.add(statusFilter.trim().toUpperCase());
        }

        if (search != null && !search.trim().isEmpty()) {
            sql.append("AND (p.transaction_id LIKE ? OR CAST(p.booking_id AS CHAR) LIKE ? OR c.full_name LIKE ?) ");
            String pattern = "%" + search.trim() + "%";
            params.add(pattern);
            params.add(pattern);
            params.add(pattern);
        }

        sql.append("ORDER BY p.payment_id DESC");

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql.toString())) {

            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Payment p = new Payment();
                    p.setPaymentId(rs.getInt("payment_id"));
                    p.setBookingId(rs.getInt("booking_id"));
                    p.setAmount(rs.getBigDecimal("amount"));
                    p.setPaymentMethod(rs.getString("payment_method"));
                    p.setPaymentDate(rs.getTimestamp("payment_date"));
                    p.setPaymentStatus(rs.getString("payment_status"));
                    p.setTransactionId(rs.getString("transaction_id"));
                    p.setCustomerName(rs.getString("customer_name"));
                    p.setCustomerPhone(rs.getString("customer_phone"));
                    p.setCargoType(rs.getString("cargo_type"));
                    payments.add(p);
                }
            }

            // Summary stats for KPI cards
            java.math.BigDecimal totalRevenue = java.math.BigDecimal.ZERO;
            int successCount = 0;
            int pendingCount = 0;

            for (Payment p : payments) {
                if ("SUCCESS".equalsIgnoreCase(p.getPaymentStatus())) {
                    successCount++;
                    if (p.getAmount() != null) {
                        totalRevenue = totalRevenue.add(p.getAmount());
                    }
                } else if ("PENDING".equalsIgnoreCase(p.getPaymentStatus())) {
                    pendingCount++;
                }
            }

            request.setAttribute("payments", payments);
            request.setAttribute("totalSuccessAmount", totalRevenue);
            request.setAttribute("successCount", successCount);
            request.setAttribute("pendingCount", pendingCount);
            request.setAttribute("selectedStatus", statusFilter != null ? statusFilter : "ALL");
            request.setAttribute("searchTerm", search != null ? search : "");

            request.getRequestDispatcher("/admin/payments.jsp").forward(request, response);

        } catch (SQLException e) {
            throw new ServletException("Unable to load payment records from database.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!WebUtil.checkAccess(request, response, "ADMIN")) {
            return;
        }

        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");

        try {
            if ("updateStatus".equals(action)) {
                int paymentId = Integer.parseInt(request.getParameter("paymentId"));
                String status = request.getParameter("status");

                String sql = "UPDATE payments SET payment_status = ? WHERE payment_id = ?";
                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, status);
                    ps.setInt(2, paymentId);
                    ps.executeUpdate();
                }
                response.sendRedirect(request.getContextPath() + "/admin/payments?success=updated");
                return;

            } else if ("delete".equals(action)) {
                int paymentId = Integer.parseInt(request.getParameter("paymentId"));

                String sql = "DELETE FROM payments WHERE payment_id = ?";
                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setInt(1, paymentId);
                    ps.executeUpdate();
                }
                response.sendRedirect(request.getContextPath() + "/admin/payments?success=deleted");
                return;
            }

        } catch (Exception e) {
            response.sendRedirect(request.getContextPath() + "/admin/payments?error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
            return;
        }

        response.sendRedirect(request.getContextPath() + "/admin/payments");
    }
}
