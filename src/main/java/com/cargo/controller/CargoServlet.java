package com.cargo.controller;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.cargo.util.DBConnection;

/**
 * Servlet for Customers to manage their Cargo items.
 */
@WebServlet("/customer/cargo")
public class CargoServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // Data model used by cargo.jsp
    public static class Cargo {
        public int id;
        public String type;
        public String description;
        public BigDecimal weight;
        public int quantity;
        public boolean fragile;
        public Timestamp createdAt;
    }

    private boolean isCustomer(HttpSession session) {
        return session != null && "CUSTOMER".equals(session.getAttribute("role"))
                && session.getAttribute("userId") instanceof Integer;
    }

    private int getCustomerId(Connection con, int userId) throws SQLException {
        String sql = "SELECT customer_id FROM customers WHERE user_id = ?";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("customer_id");
                }
            }
        }
        return -1;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (!isCustomer(session)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        int userId = (Integer) session.getAttribute("userId");
        List<Cargo> cargoList = new ArrayList<>();

        try (Connection con = DBConnection.getConnection()) {
            int customerId = getCustomerId(con, userId);
            if (customerId == -1) {
                response.sendRedirect(request.getContextPath() + "/customer/profile");
                return;
            }

            String sql = "SELECT cargo_id, cargo_type, description, weight_kg, quantity, fragile, created_at "
                       + "FROM cargo WHERE customer_id = ? ORDER BY cargo_id DESC";

            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, customerId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Cargo item = new Cargo();
                        item.id = rs.getInt("cargo_id");
                        item.type = rs.getString("cargo_type");
                        item.description = rs.getString("description");
                        item.weight = rs.getBigDecimal("weight_kg");
                        item.quantity = rs.getInt("quantity");
                        item.fragile = rs.getBoolean("fragile");
                        item.createdAt = rs.getTimestamp("created_at");
                        cargoList.add(item);
                    }
                }
            }

            request.setAttribute("cargoList", cargoList);
            request.getRequestDispatcher("/customer/cargo.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            throw new ServletException("Unable to load cargo records.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession(false);

        if (!isCustomer(session)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        int userId = (Integer) session.getAttribute("userId");
        String action = request.getParameter("action");

        try (Connection con = DBConnection.getConnection()) {
            int customerId = getCustomerId(con, userId);
            if (customerId == -1) {
                response.sendRedirect(request.getContextPath() + "/customer/profile");
                return;
            }

            // Handle Delete Action
            if ("delete".equalsIgnoreCase(action)) {
                try {
                    int cargoId = Integer.parseInt(request.getParameter("cargoId"));
                    String sql = "DELETE FROM cargo WHERE cargo_id = ? AND customer_id = ?";
                    try (PreparedStatement ps = con.prepareStatement(sql)) {
                        ps.setInt(1, cargoId);
                        ps.setInt(2, customerId);
                        ps.executeUpdate();
                    }
                    response.sendRedirect(request.getContextPath() + "/customer/cargo?deleted=success");
                    return;
                } catch (Exception e) {
                    response.sendRedirect(request.getContextPath() + "/customer/cargo?error=invalid");
                    return;
                }
            }

            // Handle Add Action
            if ("add".equalsIgnoreCase(action)) {
                String type = request.getParameter("cargoType");
                String description = request.getParameter("description");
                String weightText = request.getParameter("weightKg");
                String quantityText = request.getParameter("quantity");
                boolean fragile = "on".equalsIgnoreCase(request.getParameter("fragile"))
                        || "true".equalsIgnoreCase(request.getParameter("fragile"));

                if (type == null || type.trim().isEmpty() || weightText == null || quantityText == null) {
                    response.sendRedirect(request.getContextPath() + "/customer/cargo?error=invalid");
                    return;
                }

                try {
                    BigDecimal weight = new BigDecimal(weightText.trim());
                    int quantity = Integer.parseInt(quantityText.trim());

                    if (weight.compareTo(BigDecimal.ZERO) <= 0 || quantity <= 0) {
                        response.sendRedirect(request.getContextPath() + "/customer/cargo?error=invalid");
                        return;
                    }

                    String sql = "INSERT INTO cargo (customer_id, cargo_type, description, weight_kg, quantity, fragile) "
                               + "VALUES (?, ?, ?, ?, ?, ?)";
                    try (PreparedStatement ps = con.prepareStatement(sql)) {
                        ps.setInt(1, customerId);
                        ps.setString(2, type.trim());
                        if (description != null && !description.trim().isEmpty()) {
                            ps.setString(3, description.trim());
                        } else {
                            ps.setNull(3, Types.VARCHAR);
                        }
                        ps.setBigDecimal(4, weight);
                        ps.setInt(5, quantity);
                        ps.setBoolean(6, fragile);
                        ps.executeUpdate();
                    }

                    response.sendRedirect(request.getContextPath() + "/customer/cargo?saved=success");
                    return;
                } catch (Exception e) {
                    response.sendRedirect(request.getContextPath() + "/customer/cargo?error=invalid");
                    return;
                }
            }

            response.sendRedirect(request.getContextPath() + "/customer/cargo?error=invalid");

        } catch (SQLException e) {
            e.printStackTrace();
            throw new ServletException("Unable to process cargo operation.", e);
        }
    }
}
