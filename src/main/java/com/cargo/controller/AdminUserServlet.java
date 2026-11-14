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
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * Servlet for Admin to view user accounts, change user roles, and delete accounts.
 */
@WebServlet("/admin/users")
public class AdminUserServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // Subclass for JSP view compatibility
    public static class User extends com.cargo.model.User {
        public User(int userId, String username, String email, String role) {
            super(userId, username, email, null, role, null);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Check Admin authorization
        if (!WebUtil.checkAccess(request, response, "ADMIN")) {
            return;
        }

        List<User> users = new ArrayList<>();
        String sql = "SELECT user_id, username, email, role FROM users ORDER BY user_id DESC";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                User u = new User(
                    rs.getInt("user_id"),
                    rs.getString("username"),
                    rs.getString("email"),
                    rs.getString("role")
                );
                users.add(u);
            }

            request.setAttribute("users", users);
            request.getRequestDispatcher("/admin/users.jsp").forward(request, response);

        } catch (SQLException e) {
            throw new ServletException("Unable to load user accounts from database.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!WebUtil.checkAccess(request, response, "ADMIN")) {
            return;
        }

        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession();
        String action = request.getParameter("action");
        int loggedInUserId = WebUtil.userId(request);

        try {
            int userId = Integer.parseInt(request.getParameter("userId"));

            // Prevent admin from modifying or deleting their own current session account
            if (userId == loggedInUserId) {
                session.setAttribute("userError", "You cannot modify or delete your own active administrator account.");
                response.sendRedirect(request.getContextPath() + "/admin/users");
                return;
            }

            if ("updateRole".equals(action)) {
                String newRole = request.getParameter("role");
                if (newRole != null) {
                    newRole = newRole.trim().toUpperCase();
                    if (newRole.equals("ADMIN") || newRole.equals("CUSTOMER") || newRole.equals("DRIVER")) {
                        String sql = "UPDATE users SET role = ? WHERE user_id = ?";
                        try (Connection con = DBConnection.getConnection();
                             PreparedStatement ps = con.prepareStatement(sql)) {
                            ps.setString(1, newRole);
                            ps.setInt(2, userId);
                            ps.executeUpdate();
                        }
                        session.setAttribute("userMessage", "User role updated successfully.");
                    }
                }

            } else if ("delete".equals(action)) {
                String sql = "DELETE FROM users WHERE user_id = ?";
                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setInt(1, userId);
                    ps.executeUpdate();
                }
                session.setAttribute("userMessage", "User deleted successfully.");
            }

        } catch (Exception e) {
            session.setAttribute("userError", "Operation failed. Note: Users with linked bookings/shipments cannot be deleted: " + e.getMessage());
        }

        response.sendRedirect(request.getContextPath() + "/admin/users");
    }
}
