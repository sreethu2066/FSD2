package com.cargo.controller;

import com.cargo.util.DBConnection;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.*;
import java.util.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

/**
 * Admin Vehicle Management Servlet.
 * Supports CRUD operations for vehicles conforming to the 11-table schema:
 * vehicles (vehicle_id, vehicle_number, vehicle_type, capacity_kg, status).
 */
@WebServlet("/admin/vehicles")
public class AdminVehicleServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private boolean isAdmin(HttpServletRequest request, HttpServletResponse response) throws IOException {
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

        if (!isAdmin(request, response)) {
            return;
        }

        String action = request.getParameter("action");

        try (Connection con = DBConnection.getConnection()) {

            if ("edit".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT vehicle_id, vehicle_number, vehicle_type, capacity_kg, status FROM vehicles WHERE vehicle_id=?")) {
                    ps.setInt(1, id);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            response.sendRedirect(request.getContextPath() + "/admin/vehicles?error=notfound");
                            return;
                        }
                        request.setAttribute("vehicleId", rs.getInt("vehicle_id"));
                        request.setAttribute("vehicleNumber", rs.getString("vehicle_number"));
                        request.setAttribute("vehicleType", rs.getString("vehicle_type"));
                        request.setAttribute("capacity", rs.getBigDecimal("capacity_kg"));
                        request.setAttribute("status", rs.getString("status"));
                    }
                }
                request.getRequestDispatcher("/admin/vehicle-form.jsp").forward(request, response);
                return;
            } else if ("add".equals(action)) {
                request.getRequestDispatcher("/admin/vehicle-form.jsp").forward(request, response);
                return;
            }

            // Default: List all vehicles
            List<Map<String, Object>> vehicles = new ArrayList<>();
            String sql = "SELECT vehicle_id, vehicle_number, vehicle_type, capacity_kg, status FROM vehicles ORDER BY vehicle_id DESC";
            try (PreparedStatement ps = con.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> v = new HashMap<>();
                    v.put("vehicleId", rs.getInt("vehicle_id"));
                    v.put("vehicleNumber", rs.getString("vehicle_number"));
                    v.put("vehicleType", rs.getString("vehicle_type"));
                    v.put("capacity", rs.getBigDecimal("capacity_kg"));
                    v.put("status", rs.getString("status"));
                    vehicles.add(v);
                }
            }

            request.setAttribute("vehicles", vehicles);
            request.getRequestDispatcher("/admin/vehicles.jsp").forward(request, response);

        } catch (Exception e) {
            System.err.println("AdminVehicleServlet doGet error: " + e.getMessage());
            throw new ServletException("Unable to load vehicles.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!isAdmin(request, response)) {
            return;
        }

        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");

        try (Connection con = DBConnection.getConnection()) {

            if ("delete".equals(action)) {
                int id = Integer.parseInt(request.getParameter("vehicleId"));

                // Do not delete a vehicle that has active or past shipment records
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT COUNT(*) FROM shipments WHERE vehicle_id=?")) {
                    ps.setInt(1, id);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next() && rs.getInt(1) > 0) {
                            response.sendRedirect(request.getContextPath() + "/admin/vehicles?error=shipment");
                            return;
                        }
                    }
                }

                try (PreparedStatement ps = con.prepareStatement("DELETE FROM vehicles WHERE vehicle_id=?")) {
                    ps.setInt(1, id);
                    ps.executeUpdate();
                }
                response.sendRedirect(request.getContextPath() + "/admin/vehicles?success=deleted");
                return;

            } else if ("add".equals(action) || "update".equals(action)) {

                String number = request.getParameter("vehicleNumber");
                String type = request.getParameter("vehicleType");
                String capacityText = request.getParameter("capacity");
                String status = request.getParameter("status");

                if (number == null || number.trim().isEmpty()
                        || type == null || type.trim().isEmpty()
                        || capacityText == null || capacityText.trim().isEmpty()) {
                    response.sendRedirect(request.getContextPath() + "/admin/vehicles?error=required");
                    return;
                }

                BigDecimal capacity;
                try {
                    capacity = new BigDecimal(capacityText.trim());
                    if (capacity.compareTo(BigDecimal.ZERO) <= 0) {
                        response.sendRedirect(request.getContextPath() + "/admin/vehicles?error=capacity");
                        return;
                    }
                } catch (Exception e) {
                    response.sendRedirect(request.getContextPath() + "/admin/vehicles?error=capacity");
                    return;
                }

                if (!"AVAILABLE".equals(status) && !"ASSIGNED".equals(status) && !"MAINTENANCE".equals(status)) {
                    status = "AVAILABLE";
                }

                if ("add".equals(action)) {
                    String sql = "INSERT INTO vehicles (vehicle_number, vehicle_type, capacity_kg, status) VALUES (?, ?, ?, ?)";
                    try (PreparedStatement ps = con.prepareStatement(sql)) {
                        ps.setString(1, number.trim().toUpperCase());
                        ps.setString(2, type.trim());
                        ps.setBigDecimal(3, capacity);
                        ps.setString(4, status);
                        ps.executeUpdate();
                    }
                    response.sendRedirect(request.getContextPath() + "/admin/vehicles?success=added");
                    return;

                } else {
                    int id = Integer.parseInt(request.getParameter("vehicleId"));
                    String sql = "UPDATE vehicles SET vehicle_number=?, vehicle_type=?, capacity_kg=?, status=? WHERE vehicle_id=?";
                    try (PreparedStatement ps = con.prepareStatement(sql)) {
                        ps.setString(1, number.trim().toUpperCase());
                        ps.setString(2, type.trim());
                        ps.setBigDecimal(3, capacity);
                        ps.setString(4, status);
                        ps.setInt(5, id);
                        ps.executeUpdate();
                    }
                    response.sendRedirect(request.getContextPath() + "/admin/vehicles?success=updated");
                    return;
                }
            }

            response.sendRedirect(request.getContextPath() + "/admin/vehicles");

        } catch (SQLIntegrityConstraintViolationException e) {
            response.sendRedirect(request.getContextPath() + "/admin/vehicles?error=duplicate");
        } catch (Exception e) {
            System.err.println("AdminVehicleServlet doPost error: " + e.getMessage());
            throw new ServletException("Unable to save vehicle details.", e);
        }
    }
}
