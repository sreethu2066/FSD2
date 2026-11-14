package com.cargo.filter;

import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Centralized Role-Based Access Control (RBAC) Filter.
 * Restricts /admin/*, /customer/*, and /driver/* paths based on authenticated user session.
 * Adds anti-caching headers so users cannot view protected pages after logout.
 */
@WebFilter(urlPatterns = {"/admin/*", "/customer/*", "/driver/*"})
public class AuthFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {}

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;

        // Prevent browser caching for all protected routes
        res.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        res.setHeader("Pragma", "no-cache");
        res.setDateHeader("Expires", 0);

        String uri = req.getRequestURI();
        String ctx = req.getContextPath();
        String path = uri.substring(ctx.length());

        HttpSession session = req.getSession(false);

        boolean isLoggedIn = (session != null && session.getAttribute("userId") != null && session.getAttribute("role") != null);

        if (!isLoggedIn) {
            // Not authenticated at all -> redirect to login with unauthorized error
            res.sendRedirect(ctx + "/login.jsp?error=unauthorized");
            return;
        }

        String role = String.valueOf(session.getAttribute("role")).toUpperCase();

        // 1. Admin URL protection
        if (path.startsWith("/admin/")) {
            if (!"ADMIN".equals(role)) {
                res.sendRedirect(ctx + "/login.jsp?error=forbidden");
                return;
            }
        }
        // 2. Customer URL protection
        else if (path.startsWith("/customer/")) {
            if (!"CUSTOMER".equals(role)) {
                res.sendRedirect(ctx + "/login.jsp?error=forbidden");
                return;
            }
        }
        // 3. Driver URL protection
        else if (path.startsWith("/driver/")) {
            if (!"DRIVER".equals(role)) {
                res.sendRedirect(ctx + "/login.jsp?error=forbidden");
                return;
            }

            // Restrict active delivery operations if driver is INACTIVE / PENDING approval
            String driverStatus = (String) session.getAttribute("driverStatus");
            if ("INACTIVE".equalsIgnoreCase(driverStatus)) {
                // Allow viewing read-only profile, but block active dashboard dispatch and status updates
                if (!path.startsWith("/driver/profile") && !path.startsWith("/driver/update-profile")) {
                    res.sendRedirect(ctx + "/driver-approval-pending.jsp");
                    return;
                }
            }
        }

        // Access authorized -> continue filter chain
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {}
}
