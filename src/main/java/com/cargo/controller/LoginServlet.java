package com.cargo.controller;

import com.cargo.dao.UserDAO;
import com.cargo.model.User;
import com.cargo.util.PasswordUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Login Controller for Cargo Transportation Management System.
 * Authenticates Users, Customers, Drivers, and Administrators using BCrypt hashes,
 * initializes session role attributes, and routes users to appropriate role dashboards.
 */
@WebServlet(urlPatterns = {"/login", "/LoginServlet"})
public class LoginServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private final UserDAO userDAO = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session != null && session.getAttribute("userId") != null && session.getAttribute("role") != null) {
            String role = String.valueOf(session.getAttribute("role")).toUpperCase();
            redirectByRole(request, response, role);
            return;
        }
        request.getRequestDispatcher("/login.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String username = request.getParameter("username");
        String password = request.getParameter("password");
        String selectedRole = request.getParameter("role");

        if (username == null || password == null
                || username.trim().isEmpty() || password.isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=invalid");
            return;
        }

        try {
            User user = userDAO.findByUsername(username.trim());

            if (user != null && user.getPassword() != null) {
                boolean authenticated = PasswordUtil.verifyPassword(password, user.getPassword());

                // Legacy plain-text auto-upgrade to BCrypt
                if (authenticated && !user.getPassword().startsWith("$2")) {
                    try {
                        String newHash = PasswordUtil.hashPassword(password);
                        userDAO.updatePassword(user.getUserId(), newHash);
                    } catch (Exception ignored) {}
                }

                if (authenticated) {
                    // Check role selection if provided
                    if (selectedRole != null && !selectedRole.trim().isEmpty() && !"ANY".equalsIgnoreCase(selectedRole)) {
                        if (!selectedRole.trim().equalsIgnoreCase(user.getRole())) {
                            response.sendRedirect(request.getContextPath() + "/login.jsp?error=role_mismatch");
                            return;
                        }
                    }

                    HttpSession session = request.getSession(true);
                    session.setAttribute("userId", user.getUserId());
                    session.setAttribute("username", user.getUsername());
                    session.setAttribute("email", user.getEmail());
                    session.setAttribute("role", user.getRole().toUpperCase());

                    if ("CUSTOMER".equalsIgnoreCase(user.getRole())) {
                        Integer custId = userDAO.getCustomerIdByUserId(user.getUserId());
                        if (custId != null) {
                            session.setAttribute("customerId", custId);
                        }
                        response.sendRedirect(request.getContextPath() + "/customer/dashboard");
                        return;

                    } else if ("DRIVER".equalsIgnoreCase(user.getRole())) {
                        Integer drvId = userDAO.getDriverIdByUserId(user.getUserId());
                        String drvStatus = userDAO.getDriverStatusByUserId(user.getUserId());
                        if (drvId != null) {
                            session.setAttribute("driverId", drvId);
                        }
                        session.setAttribute("driverStatus", drvStatus != null ? drvStatus : "INACTIVE");

                        // If driver account is INACTIVE (pending admin review), route to pending notice page
                        if ("INACTIVE".equalsIgnoreCase(drvStatus)) {
                            response.sendRedirect(request.getContextPath() + "/driver-approval-pending.jsp");
                            return;
                        }

                        response.sendRedirect(request.getContextPath() + "/driver/dashboard");
                        return;

                    } else if ("ADMIN".equalsIgnoreCase(user.getRole())) {
                        response.sendRedirect(request.getContextPath() + "/admin/dashboard.jsp");
                        return;
                    } else {
                        response.sendRedirect(request.getContextPath() + "/login.jsp");
                        return;
                    }
                }
            }

            // Authentication failed
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=invalid");

        } catch (SQLException e) {
            System.err.println("LoginServlet database error: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=server");
        } catch (Exception e) {
            System.err.println("LoginServlet unexpected error: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=server");
        }
    }

    private void redirectByRole(HttpServletRequest request, HttpServletResponse response, String role)
            throws IOException {
        String ctx = request.getContextPath();
        if ("ADMIN".equalsIgnoreCase(role)) {
            response.sendRedirect(ctx + "/admin/dashboard.jsp");
        } else if ("DRIVER".equalsIgnoreCase(role)) {
            HttpSession session = request.getSession(false);
            String drvStatus = session != null ? (String) session.getAttribute("driverStatus") : null;
            if ("INACTIVE".equalsIgnoreCase(drvStatus)) {
                response.sendRedirect(ctx + "/driver-approval-pending.jsp");
            } else {
                response.sendRedirect(ctx + "/driver/dashboard");
            }
        } else if ("CUSTOMER".equalsIgnoreCase(role)) {
            response.sendRedirect(ctx + "/customer/dashboard");
        } else {
            response.sendRedirect(ctx + "/login.jsp");
        }
    }
}
