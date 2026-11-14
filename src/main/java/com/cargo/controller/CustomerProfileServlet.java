package com.cargo.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.cargo.util.DBConnection;

/**
 * Servlet for Customers to view and update their profile details.
 */
@WebServlet("/customer/profile")
public class CustomerProfileServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private boolean isCustomer(HttpSession session) {
        return session != null && "CUSTOMER".equals(session.getAttribute("role"))
                && session.getAttribute("userId") instanceof Integer;
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
        String sql = "SELECT customer_id, full_name, phone, gender, date_of_birth FROM customers WHERE user_id = ?";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    request.setAttribute("customerId", rs.getInt("customer_id"));
                    request.setAttribute("fullName", rs.getString("full_name"));
                    request.setAttribute("phone", rs.getString("phone"));
                    request.setAttribute("gender", rs.getString("gender"));
                    request.setAttribute("dateOfBirth", rs.getDate("date_of_birth"));
                }
            }

            request.getRequestDispatcher("/customer/profile.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            throw new ServletException("Unable to load customer profile.", e);
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
        String fullName = request.getParameter("fullName");
        String phone = request.getParameter("phone");
        String gender = request.getParameter("gender");
        String dobStr = request.getParameter("dateOfBirth");

        if (fullName == null || fullName.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/customer/profile?error=name");
            return;
        }

        Date dateOfBirth = null;
        if (dobStr != null && !dobStr.trim().isEmpty()) {
            try {
                dateOfBirth = Date.valueOf(dobStr.trim());
            } catch (IllegalArgumentException e) {
                response.sendRedirect(request.getContextPath() + "/customer/profile?error=date");
                return;
            }
        }

        try (Connection con = DBConnection.getConnection()) {
            // Check if profile record already exists
            boolean exists = false;
            String checkSql = "SELECT customer_id FROM customers WHERE user_id = ?";
            try (PreparedStatement check = con.prepareStatement(checkSql)) {
                check.setInt(1, userId);
                try (ResultSet rs = check.executeQuery()) {
                    exists = rs.next();
                }
            }

            if (exists) {
                String updateSql = "UPDATE customers SET full_name = ?, phone = ?, gender = ?, date_of_birth = ? WHERE user_id = ?";
                try (PreparedStatement ps = con.prepareStatement(updateSql)) {
                    ps.setString(1, fullName.trim());
                    ps.setString(2, phone != null && !phone.trim().isEmpty() ? phone.trim() : null);
                    ps.setString(3, gender != null && !gender.trim().isEmpty() ? gender.trim() : null);
                    ps.setDate(4, dateOfBirth);
                    ps.setInt(5, userId);
                    ps.executeUpdate();
                }
            } else {
                String insertSql = "INSERT INTO customers (user_id, full_name, phone, gender, date_of_birth) VALUES (?, ?, ?, ?, ?)";
                try (PreparedStatement ps = con.prepareStatement(insertSql)) {
                    ps.setInt(1, userId);
                    ps.setString(2, fullName.trim());
                    ps.setString(3, phone != null && !phone.trim().isEmpty() ? phone.trim() : null);
                    ps.setString(4, gender != null && !gender.trim().isEmpty() ? gender.trim() : null);
                    ps.setDate(5, dateOfBirth);
                    ps.executeUpdate();
                }
            }

            response.sendRedirect(request.getContextPath() + "/customer/profile?saved=success");

        } catch (SQLException e) {
            e.printStackTrace();
            throw new ServletException("Unable to save customer profile.", e);
        }
    }
}
