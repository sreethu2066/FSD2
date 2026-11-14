package com.cargo.controller;

import com.cargo.dao.UserDAO;
import com.cargo.model.Driver;
import com.cargo.util.WebUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * Driver Profile Servlet.
 * Allows authenticated drivers to view their account and license details and update contact information.
 */
@WebServlet(urlPatterns = {"/driver/profile", "/driver/update-profile"})
public class DriverProfileServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private final UserDAO userDAO = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!WebUtil.checkAccess(req, resp, "DRIVER")) {
            return;
        }

        int userId = WebUtil.userId(req);

        try {
            Driver driver = userDAO.findDriverByUserId(userId);
            if (driver == null) {
                resp.sendRedirect(req.getContextPath() + "/driver-approval-pending.jsp");
                return;
            }

            req.setAttribute("driver", driver);
            req.getRequestDispatcher("/driver/profile.jsp").forward(req, resp);

        } catch (Exception e) {
            e.printStackTrace();
            throw new ServletException("Unable to load driver profile.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!WebUtil.checkAccess(req, resp, "DRIVER")) {
            return;
        }

        req.setCharacterEncoding("UTF-8");
        int userId = WebUtil.userId(req);

        String phone = req.getParameter("phone");
        String email = req.getParameter("email");

        if (phone == null || phone.trim().isEmpty() || email == null || email.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/driver/profile?error=required");
            return;
        }

        try {
            // Check if email is already taken by another user
            if (userDAO.emailExistsExcludingUser(email.trim(), userId)) {
                resp.sendRedirect(req.getContextPath() + "/driver/profile?error=email_exists");
                return;
            }

            userDAO.updateDriverSelfProfile(userId, phone.trim(), email.trim());
            resp.sendRedirect(req.getContextPath() + "/driver/profile?success=1");

        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/driver/profile?error=server");
        }
    }
}
