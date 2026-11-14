package com.cargo.controller;

import com.cargo.dao.UserDAO;
import com.cargo.model.Driver;
import com.cargo.util.DBConnection;
import com.cargo.util.PasswordUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/**
 * Servlet for Admin to manage fleet drivers (listing, adding, editing, status toggle, password reset, and deletion).
 */
@WebServlet(urlPatterns = {"/admin/drivers", "/admin/add-driver"})
public class AdminDriverServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private final UserDAO userDAO = new UserDAO();

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

        String path = request.getServletPath();
        String action = request.getParameter("action");

        try {
            // Add new driver form
            if ("/admin/add-driver".equals(path) || "add".equalsIgnoreCase(action)) {
                request.setAttribute("genUsername", PasswordUtil.generateUsername(""));
                request.setAttribute("genPassword", PasswordUtil.generateTemporaryPassword());
                request.getRequestDispatcher("/admin/driver-form.jsp").forward(request, response);
                return;
            }

            // Edit driver form
            if ("edit".equalsIgnoreCase(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                Driver driver = userDAO.findDriverById(id);

                if (driver != null) {
                    request.setAttribute("driver", driver);
                    request.setAttribute("driverId", driver.getDriverId());
                    request.setAttribute("userId", driver.getUserId());
                    request.setAttribute("driverName", driver.getDriverName());
                    request.setAttribute("username", driver.getUsername());
                    request.setAttribute("email", driver.getEmail());
                    request.setAttribute("phone", driver.getPhone());
                    request.setAttribute("licenseNumber", driver.getLicenseNumber());
                    request.setAttribute("experienceYears", driver.getExperienceYears());
                    request.setAttribute("status", driver.getStatus());
                    request.setAttribute("createdAt", driver.getCreatedAt());

                    request.getRequestDispatcher("/admin/driver-form.jsp").forward(request, response);
                    return;
                }

                response.sendRedirect(request.getContextPath() + "/admin/drivers?error=notfound");
                return;
            }

            // Default: List all registered drivers with joined user and vehicle info
            List<Map<String, Object>> drivers = userDAO.findAllDriversWithUsers();
            request.setAttribute("drivers", drivers);
            request.getRequestDispatcher("/admin/drivers.jsp").forward(request, response);

        } catch (Exception e) {
            System.err.println("AdminDriverServlet doGet error: " + e.getMessage());
            throw new ServletException("Unable to load driver management.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!isAdmin(request, response)) {
            return;
        }

        request.setCharacterEncoding("UTF-8");
        String path = request.getServletPath();
        String action = request.getParameter("action");

        try {
            // Provision a new driver
            if ("/admin/add-driver".equals(path) || "add".equalsIgnoreCase(action)) {
                String name = request.getParameter("driverName");
                String username = request.getParameter("username");
                String password = request.getParameter("password");
                String email = request.getParameter("email");
                String phone = request.getParameter("phone");
                String license = request.getParameter("licenseNumber");
                String status = request.getParameter("status");
                String expStr = request.getParameter("experienceYears");

                if (name == null || username == null || password == null || phone == null || license == null
                        || name.trim().isEmpty() || username.trim().isEmpty() || password.trim().isEmpty()
                        || phone.trim().isEmpty() || license.trim().isEmpty()) {
                    response.sendRedirect(request.getContextPath() + "/admin/add-driver?error=required");
                    return;
                }

                if (userDAO.usernameExists(username.trim())) {
                    response.sendRedirect(request.getContextPath() + "/admin/add-driver?error=username_exists");
                    return;
                }

                if (email != null && !email.trim().isEmpty() && userDAO.emailExists(email.trim())) {
                    response.sendRedirect(request.getContextPath() + "/admin/add-driver?error=email_exists");
                    return;
                }

                if (userDAO.licenseExists(license.trim().toUpperCase())) {
                    response.sendRedirect(request.getContextPath() + "/admin/add-driver?error=license_exists");
                    return;
                }

                int experience = 0;
                try {
                    if (expStr != null && !expStr.trim().isEmpty()) {
                        experience = Integer.parseInt(expStr.trim());
                    }
                } catch (NumberFormatException ignored) {}

                if (!"AVAILABLE".equals(status) && !"ASSIGNED".equals(status) && !"INACTIVE".equals(status)) {
                    status = "AVAILABLE";
                }

                userDAO.registerDriver(username.trim(), email != null ? email.trim() : "", password.trim(),
                        name.trim(), phone.trim(), license.trim().toUpperCase(), experience, status);

                response.sendRedirect(request.getContextPath() + "/admin/drivers?success=driver_created");
                return;
            }

            if ("toggleStatus".equalsIgnoreCase(action)) {
                int driverId = Integer.parseInt(request.getParameter("driverId"));
                String currentStatus = request.getParameter("currentStatus");
                String newStatus = "AVAILABLE".equalsIgnoreCase(currentStatus) ? "INACTIVE" : "AVAILABLE";

                userDAO.updateDriverStatus(driverId, newStatus);
                response.sendRedirect(request.getContextPath() + "/admin/drivers?success=status_updated");
                return;

            } else if ("resetPassword".equalsIgnoreCase(action)) {
                int driverId = Integer.parseInt(request.getParameter("driverId"));
                String newPassword = request.getParameter("newPassword");

                if (newPassword == null || newPassword.trim().isEmpty()) {
                    newPassword = PasswordUtil.generateTemporaryPassword();
                } else {
                    newPassword = newPassword.trim();
                }

                userDAO.resetDriverPassword(driverId, newPassword);
                response.sendRedirect(request.getContextPath() + "/admin/drivers?success=password_reset&tempPass="
                        + URLEncoder.encode(newPassword, "UTF-8"));
                return;

            } else if ("update".equalsIgnoreCase(action)) {
                int id = Integer.parseInt(request.getParameter("driverId"));
                String name = request.getParameter("driverName");
                String email = request.getParameter("email");
                String phone = request.getParameter("phone");
                String license = request.getParameter("licenseNumber");
                String status = request.getParameter("status");
                String expStr = request.getParameter("experienceYears");

                if (name == null || phone == null || license == null
                        || name.trim().isEmpty() || phone.trim().isEmpty() || license.trim().isEmpty()) {
                    response.sendRedirect(request.getContextPath() + "/admin/drivers?action=edit&id=" + id + "&error=required");
                    return;
                }

                int experience = 0;
                try {
                    experience = Integer.parseInt(expStr);
                } catch (NumberFormatException ignored) {}

                if (!"AVAILABLE".equals(status) && !"ASSIGNED".equals(status) && !"INACTIVE".equals(status)) {
                    status = "AVAILABLE";
                }

                if (userDAO.licenseExistsExcludingDriver(license.trim().toUpperCase(), id)) {
                    response.sendRedirect(request.getContextPath() + "/admin/drivers?action=edit&id=" + id + "&error=license_exists");
                    return;
                }

                userDAO.updateDriverInfo(id, name.trim(), email, phone.trim(), license.trim().toUpperCase(), experience, status);
                response.sendRedirect(request.getContextPath() + "/admin/drivers?success=driver_updated");
                return;

            } else if ("delete".equalsIgnoreCase(action)) {
                int id = Integer.parseInt(request.getParameter("driverId"));

                try (Connection con = DBConnection.getConnection();
                     PreparedStatement check = con.prepareStatement(
                             "SELECT COUNT(*) FROM shipments WHERE driver_id=? AND shipment_status NOT IN ('DELIVERED', 'FAILED')")) {
                    check.setInt(1, id);
                    try (ResultSet rs = check.executeQuery()) {
                        if (rs.next() && rs.getInt(1) > 0) {
                            response.sendRedirect(request.getContextPath() + "/admin/drivers?error=shipmentassigned");
                            return;
                        }
                    }
                }

                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement("DELETE FROM drivers WHERE driver_id=?")) {
                    ps.setInt(1, id);
                    ps.executeUpdate();
                }

                response.sendRedirect(request.getContextPath() + "/admin/drivers?success=driver_deleted");
                return;
            }

            response.sendRedirect(request.getContextPath() + "/admin/drivers");

        } catch (Exception e) {
            System.err.println("AdminDriverServlet doPost error: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/admin/drivers?error=server");
        }
    }
}
