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
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * Servlet for Admin to view, update, and delete Customer records.
 */
@WebServlet("/admin/customers")
public class AdminCustomerServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // Subclass for JSP view compatibility
    public static class Customer extends com.cargo.model.Customer {}

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Check Admin authorization
        if (!WebUtil.checkAccess(request, response, "ADMIN")) {
            return;
        }

        List<Customer> customers = new ArrayList<>();
        String sql = "SELECT c.customer_id, c.user_id, c.full_name, c.phone, c.gender, c.date_of_birth, " +
                     "u.username, u.email " +
                     "FROM customers c " +
                     "JOIN users u ON c.user_id = u.user_id " +
                     "ORDER BY c.customer_id DESC";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Customer c = new Customer();
                c.setCustomerId(rs.getInt("customer_id"));
                c.setUserId(rs.getInt("user_id"));
                c.setFullName(rs.getString("full_name"));
                c.setPhone(rs.getString("phone"));
                c.setGender(rs.getString("gender"));
                c.setDateOfBirth(rs.getDate("date_of_birth"));
                c.setUsername(rs.getString("username"));
                c.setEmail(rs.getString("email"));
                customers.add(c);
            }

            request.setAttribute("customers", customers);
            request.getRequestDispatcher("/admin/customers.jsp").forward(request, response);

        } catch (SQLException e) {
            throw new ServletException("Unable to load customers from database.", e);
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
        HttpSession session = request.getSession();

        try {
            int customerId = Integer.parseInt(request.getParameter("customerId"));

            if ("update".equals(action)) {
                String fullName = request.getParameter("fullName");
                String phone = request.getParameter("phone");
                String gender = request.getParameter("gender");
                String dobText = request.getParameter("dateOfBirth");

                Date dob = (dobText != null && !dobText.trim().isEmpty()) ? Date.valueOf(dobText.trim()) : null;

                String sql = "UPDATE customers SET full_name = ?, phone = ?, gender = ?, date_of_birth = ? WHERE customer_id = ?";
                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, fullName != null ? fullName.trim() : "");
                    ps.setString(2, phone != null ? phone.trim() : null);
                    ps.setString(3, gender != null ? gender.trim() : null);
                    ps.setDate(4, dob);
                    ps.setInt(5, customerId);
                    ps.executeUpdate();
                }
                session.setAttribute("customerMessage", "Customer details updated successfully.");

            } else if ("delete".equals(action)) {
                String sql = "DELETE FROM customers WHERE customer_id = ?";
                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setInt(1, customerId);
                    ps.executeUpdate();
                }
                session.setAttribute("customerMessage", "Customer profile deleted successfully.");
            }

        } catch (Exception e) {
            session.setAttribute("customerError", "Operation failed: " + e.getMessage());
        }

        response.sendRedirect(request.getContextPath() + "/admin/customers");
    }
}
