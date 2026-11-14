<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Authenticate driver
    String role = (String) session.getAttribute("role");
    if (session.getAttribute("userId") == null || !"DRIVER".equalsIgnoreCase(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    String driverStatus = (String) session.getAttribute("driverStatus");
    if ("INACTIVE".equalsIgnoreCase(driverStatus)) {
        response.sendRedirect(request.getContextPath() + "/driver-approval-pending.jsp");
        return;
    }

    // Forward to DriverDashboardServlet to load live database data
    response.sendRedirect(request.getContextPath() + "/driver/dashboard");
%>
