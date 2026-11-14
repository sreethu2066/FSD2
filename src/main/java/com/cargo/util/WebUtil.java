package com.cargo.util;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Common web and security utility methods for CTMS Servlets and JSPs.
 */
public class WebUtil {

    /**
     * Checks if user is authenticated and has the required role.
     * @param request HTTP request
     * @param requiredRole Role string ("ADMIN", "CUSTOMER", "DRIVER") or null for any logged-in user
     * @return true if authorized, false otherwise
     */
    public static boolean requireLogin(HttpServletRequest request, String requiredRole) {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            return false;
        }
        if (requiredRole != null) {
            String role = String.valueOf(session.getAttribute("role"));
            return requiredRole.equalsIgnoreCase(role);
        }
        return true;
    }

    /**
     * Convenience method: checks access and redirects unauthorized requests to login page.
     */
    public static boolean checkAccess(HttpServletRequest request, HttpServletResponse response, String requiredRole) throws IOException {
        if (!requireLogin(request, requiredRole)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
            return false;
        }
        return true;
    }

    /**
     * Returns the logged-in user's user_id from session, or -1 if unauthenticated.
     */
    public static int userId(HttpServletRequest request) {
        HttpSession s = request.getSession(false);
        if (s == null || s.getAttribute("userId") == null) return -1;
        try {
            return Integer.parseInt(String.valueOf(s.getAttribute("userId")));
        } catch (NumberFormatException e) {
            return -1;
        }
    }

    /**
     * Returns the customer_id associated with the logged-in user.
     * Caches in session for subsequent calls.
     */
    public static Integer customerId(HttpServletRequest request) {
        HttpSession s = request.getSession(false);
        if (s == null) return null;
        Object cidObj = s.getAttribute("customerId");
        if (cidObj != null) {
            try {
                return Integer.parseInt(String.valueOf(cidObj));
            } catch (NumberFormatException ignored) {}
        }
        int uid = userId(request);
        if (uid > 0) {
            try (Connection c = DBConnection.getConnection();
                 PreparedStatement p = c.prepareStatement("SELECT customer_id FROM customers WHERE user_id=?")) {
                p.setInt(1, uid);
                try (ResultSet r = p.executeQuery()) {
                    if (r.next()) {
                        int cid = r.getInt("customer_id");
                        s.setAttribute("customerId", cid);
                        return cid;
                    }
                }
            } catch (SQLException ignored) {}
        }
        return null;
    }

    /**
     * Returns the driver_id associated with the logged-in user.
     * Caches in session for subsequent calls.
     */
    public static Integer driverId(HttpServletRequest request) {
        HttpSession s = request.getSession(false);
        if (s == null) return null;
        Object didObj = s.getAttribute("driverId");
        if (didObj != null) {
            try {
                return Integer.parseInt(String.valueOf(didObj));
            } catch (NumberFormatException ignored) {}
        }
        int uid = userId(request);
        if (uid > 0) {
            try (Connection c = DBConnection.getConnection();
                 PreparedStatement p = c.prepareStatement("SELECT driver_id FROM drivers WHERE user_id=?")) {
                p.setInt(1, uid);
                try (ResultSet r = p.executeQuery()) {
                    if (r.next()) {
                        int did = r.getInt("driver_id");
                        s.setAttribute("driverId", did);
                        return did;
                    }
                }
            } catch (SQLException ignored) {}
        }
        return null;
    }

    /**
     * HTML entity escaping for XSS protection.
     */
    public static String h(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    /**
     * Safely parse BigDecimal with default fallback.
     */
    public static BigDecimal parseBigDecimal(String val, BigDecimal defaultVal) {
        if (val == null || val.trim().isEmpty()) return defaultVal;
        try {
            return new BigDecimal(val.trim());
        } catch (Exception e) {
            return defaultVal;
        }
    }
}
