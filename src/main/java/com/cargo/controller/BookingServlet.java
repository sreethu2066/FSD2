package com.cargo.controller;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
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
 * Servlet for Customers to manage their bookings (create booking, view bookings, cancel booking).
 */
@WebServlet("/customer/bookings")
public class BookingServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    public static class CargoOption {
        public int id;
        public String type;
        public BigDecimal weight;
        public int quantity;
    }

    public static class AddressOption {
        public int id;
        public String type;
        public String line;
        public String city;
        public String state;
        public String pincode;
    }

    public static class Booking {
        public int id;
        public int cargoId;
        public int pickupAddressId;
        public int deliveryAddressId;
        public String cargoType;
        public String pickupCity;
        public String deliveryCity;
        public Timestamp bookingDate;
        public Date pickupDate;
        public Date expectedDate;
        public String status;
        public BigDecimal amount;
    }

    private int getCustomerId(Connection con, int userId) throws SQLException {
        String sql = "SELECT customer_id FROM customers WHERE user_id = ?";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt("customer_id");
            }
        }
        return -1;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null
                || !"CUSTOMER".equals(session.getAttribute("role"))) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        int userId = (Integer) session.getAttribute("userId");

        try (Connection con = DBConnection.getConnection()) {
            int customerId = getCustomerId(con, userId);
            if (customerId == -1) {
                response.sendRedirect(request.getContextPath() + "/customer/profile");
                return;
            }

            // 1. Fetch available cargo items
            List<CargoOption> cargoList = new ArrayList<>();
            String cargoSql = "SELECT cargo_id, cargo_type, weight_kg, quantity FROM cargo WHERE customer_id = ? ORDER BY cargo_id DESC";
            try (PreparedStatement ps = con.prepareStatement(cargoSql)) {
                ps.setInt(1, customerId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        CargoOption cargo = new CargoOption();
                        cargo.id = rs.getInt("cargo_id");
                        cargo.type = rs.getString("cargo_type");
                        cargo.weight = rs.getBigDecimal("weight_kg");
                        cargo.quantity = rs.getInt("quantity");
                        cargoList.add(cargo);
                    }
                }
            }

            // 2. Fetch customer addresses
            List<AddressOption> addressList = new ArrayList<>();
            String addrSql = "SELECT address_id, address_type, address_line, city, state, pincode FROM addresses WHERE customer_id = ? ORDER BY address_id DESC";
            try (PreparedStatement ps = con.prepareStatement(addrSql)) {
                ps.setInt(1, customerId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        AddressOption addr = new AddressOption();
                        addr.id = rs.getInt("address_id");
                        addr.type = rs.getString("address_type");
                        addr.line = rs.getString("address_line");
                        addr.city = rs.getString("city");
                        addr.state = rs.getString("state");
                        addr.pincode = rs.getString("pincode");
                        addressList.add(addr);
                    }
                }
            }

            // 3. Fetch past bookings
            List<Booking> bookingList = new ArrayList<>();
            String bookingSql = "SELECT b.booking_id, b.cargo_id, b.pickup_address_id, b.delivery_address_id, "
                              + "b.booking_date, b.pickup_date, b.expected_delivery_date, b.booking_status, b.total_amount, "
                              + "c.cargo_type, pa.city AS pickup_city, da.city AS delivery_city "
                              + "FROM bookings b "
                              + "JOIN cargo c ON b.cargo_id = c.cargo_id "
                              + "JOIN addresses pa ON b.pickup_address_id = pa.address_id "
                              + "JOIN addresses da ON b.delivery_address_id = da.address_id "
                              + "WHERE b.customer_id = ? ORDER BY b.booking_id DESC";

            try (PreparedStatement ps = con.prepareStatement(bookingSql)) {
                ps.setInt(1, customerId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Booking b = new Booking();
                        b.id = rs.getInt("booking_id");
                        b.cargoId = rs.getInt("cargo_id");
                        b.pickupAddressId = rs.getInt("pickup_address_id");
                        b.deliveryAddressId = rs.getInt("delivery_address_id");
                        b.cargoType = rs.getString("cargo_type");
                        b.pickupCity = rs.getString("pickup_city");
                        b.deliveryCity = rs.getString("delivery_city");
                        b.bookingDate = rs.getTimestamp("booking_date");
                        b.pickupDate = rs.getDate("pickup_date");
                        b.expectedDate = rs.getDate("expected_delivery_date");
                        b.status = rs.getString("booking_status");
                        b.amount = rs.getBigDecimal("total_amount");
                        bookingList.add(b);
                    }
                }
            }

            request.setAttribute("cargoList", cargoList);
            request.setAttribute("addressList", addressList);
            request.setAttribute("bookingList", bookingList);
            request.getRequestDispatcher("/customer/bookings.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            throw new ServletException("Unable to load bookings.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null
                || !"CUSTOMER".equals(session.getAttribute("role"))) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        request.setCharacterEncoding("UTF-8");
        int userId = (Integer) session.getAttribute("userId");
        String action = request.getParameter("action");
        String contextPath = request.getContextPath();

        try (Connection con = DBConnection.getConnection()) {
            int customerId = getCustomerId(con, userId);
            if (customerId == -1) {
                response.sendRedirect(contextPath + "/customer/profile");
                return;
            }

            // Cancel Booking
            if ("cancel".equalsIgnoreCase(action)) {
                int bookingId = Integer.parseInt(request.getParameter("bookingId"));
                String cancelSql = "UPDATE bookings SET booking_status = 'CANCELLED' "
                                 + "WHERE booking_id = ? AND customer_id = ? AND booking_status = 'PENDING'";
                try (PreparedStatement ps = con.prepareStatement(cancelSql)) {
                    ps.setInt(1, bookingId);
                    ps.setInt(2, customerId);
                    ps.executeUpdate();
                }
                response.sendRedirect(contextPath + "/customer/bookings");
                return;
            }

            // Create New Booking
            int cargoId = Integer.parseInt(request.getParameter("cargoId"));
            int pickupAddressId = Integer.parseInt(request.getParameter("pickupAddressId"));
            int deliveryAddressId = Integer.parseInt(request.getParameter("deliveryAddressId"));
            Date pickupDate = Date.valueOf(request.getParameter("pickupDate"));
            Date expectedDate = Date.valueOf(request.getParameter("expectedDeliveryDate"));
            BigDecimal amount = new BigDecimal(request.getParameter("totalAmount"));

            if (amount.compareTo(BigDecimal.ZERO) < 0 || expectedDate.before(pickupDate) || pickupAddressId == deliveryAddressId) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Check dates, amount, and distinct addresses.");
                return;
            }

            // Verify cargo belongs to customer
            String cargoCheck = "SELECT 1 FROM cargo WHERE cargo_id = ? AND customer_id = ?";
            try (PreparedStatement ps = con.prepareStatement(cargoCheck)) {
                ps.setInt(1, cargoId);
                ps.setInt(2, customerId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid cargo selection.");
                        return;
                    }
                }
            }

            // Verify addresses belong to customer
            String addrCheck = "SELECT COUNT(*) FROM addresses WHERE customer_id = ? AND address_id IN (?, ?)";
            try (PreparedStatement ps = con.prepareStatement(addrCheck)) {
                ps.setInt(1, customerId);
                ps.setInt(2, pickupAddressId);
                ps.setInt(3, deliveryAddressId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next() || rs.getInt(1) != 2) {
                        response.sendError(HttpServletResponse.SC_FORBIDDEN, "Select valid addresses belonging to your account.");
                        return;
                    }
                }
            }

            // Insert booking
            String insertSql = "INSERT INTO bookings (customer_id, cargo_id, pickup_address_id, delivery_address_id, "
                             + "pickup_date, expected_delivery_date, booking_status, total_amount) "
                             + "VALUES (?, ?, ?, ?, ?, ?, 'PENDING', ?)";
            try (PreparedStatement ps = con.prepareStatement(insertSql)) {
                ps.setInt(1, customerId);
                ps.setInt(2, cargoId);
                ps.setInt(3, pickupAddressId);
                ps.setInt(4, deliveryAddressId);
                ps.setDate(5, pickupDate);
                ps.setDate(6, expectedDate);
                ps.setBigDecimal(7, amount);
                ps.executeUpdate();
            }

            response.sendRedirect(contextPath + "/customer/bookings");

        } catch (IllegalArgumentException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid booking input.");
        } catch (SQLException e) {
            e.printStackTrace();
            throw new ServletException("Unable to process booking.", e);
        }
    }
}
