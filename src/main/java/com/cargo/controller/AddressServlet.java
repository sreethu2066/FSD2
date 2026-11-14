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

import com.cargo.util.DBConnection;

/**
 * Servlet for Customers to manage delivery and pickup addresses.
 */
@WebServlet("/customer/addresses")
public class AddressServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // Address model used by addresses.jsp
    public static class Address {
        public int id;
        public String type;
        public String addressLine;
        public String city;
        public String state;
        public String pincode;
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
        List<Address> addresses = new ArrayList<>();

        try (Connection con = DBConnection.getConnection()) {
            int customerId = getCustomerId(con, userId);
            if (customerId == -1) {
                response.sendRedirect(request.getContextPath() + "/customer/profile");
                return;
            }

            String sql = "SELECT address_id, address_type, address_line, city, state, pincode "
                       + "FROM addresses WHERE customer_id = ? ORDER BY address_id DESC";

            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, customerId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Address addr = new Address();
                        addr.id = rs.getInt("address_id");
                        addr.type = rs.getString("address_type");
                        addr.addressLine = rs.getString("address_line");
                        addr.city = rs.getString("city");
                        addr.state = rs.getString("state");
                        addr.pincode = rs.getString("pincode");
                        addresses.add(addr);
                    }
                }
            }

            request.setAttribute("addresses", addresses);
            request.getRequestDispatcher("/customer/addresses.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            throw new ServletException("Unable to load customer addresses.", e);
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

            // Handle Delete Address
            if ("delete".equalsIgnoreCase(action)) {
                try {
                    int addressId = Integer.parseInt(request.getParameter("addressId"));
                    String sql = "DELETE FROM addresses WHERE address_id = ? AND customer_id = ?";
                    try (PreparedStatement ps = con.prepareStatement(sql)) {
                        ps.setInt(1, addressId);
                        ps.setInt(2, customerId);
                        ps.executeUpdate();
                    }
                    response.sendRedirect(request.getContextPath() + "/customer/addresses?deleted=success");
                    return;
                } catch (Exception e) {
                    response.sendRedirect(request.getContextPath() + "/customer/addresses?error=invalid");
                    return;
                }
            }

            // Handle Add Address
            if ("add".equalsIgnoreCase(action)) {
                String type = request.getParameter("addressType");
                String addressLine = request.getParameter("addressLine");
                String city = request.getParameter("city");
                String state = request.getParameter("state");
                String pincode = request.getParameter("pincode");

                if (type == null || addressLine == null || city == null || state == null || pincode == null
                        || addressLine.trim().isEmpty() || city.trim().isEmpty() || state.trim().isEmpty() || pincode.trim().isEmpty()) {
                    response.sendRedirect(request.getContextPath() + "/customer/addresses?error=invalid");
                    return;
                }

                String sql = "INSERT INTO addresses (customer_id, address_type, address_line, city, state, pincode) "
                           + "VALUES (?, ?, ?, ?, ?, ?)";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setInt(1, customerId);
                    ps.setString(2, type.trim().toUpperCase());
                    ps.setString(3, addressLine.trim());
                    ps.setString(4, city.trim());
                    ps.setString(5, state.trim());
                    ps.setString(6, pincode.trim());
                    ps.executeUpdate();
                }

                response.sendRedirect(request.getContextPath() + "/customer/addresses?saved=success");
                return;
            }

            response.sendRedirect(request.getContextPath() + "/customer/addresses?error=invalid");

        } catch (SQLException e) {
            e.printStackTrace();
            throw new ServletException("Unable to save or delete address.", e);
        }
    }
}
