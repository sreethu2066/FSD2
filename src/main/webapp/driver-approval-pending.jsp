<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.cargo.dao.UserDAO" %>
<%@ page import="com.cargo.model.Driver" %>
<%
    String role = (String) session.getAttribute("role");
    if (session.getAttribute("userId") == null || !"DRIVER".equalsIgnoreCase(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    int userId = (Integer) session.getAttribute("userId");
    UserDAO userDAO = new UserDAO();
    Driver driver = userDAO.findDriverByUserId(userId);

    // If driver is now active, redirect them to dashboard
    if (driver != null && !"INACTIVE".equalsIgnoreCase(driver.getStatus())) {
        session.setAttribute("driverStatus", driver.getStatus());
        response.sendRedirect(request.getContextPath() + "/driver-dashboard.jsp");
        return;
    }

    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Driver Account Pending Approval | Cargo Transportation System</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
    <style>
        .pending-card {
            background: white;
            max-width: 680px;
            margin: 40px auto;
            padding: 35px 30px;
            border-radius: 12px;
            border: 1px solid #e2e8f0;
            box-shadow: 0 4px 16px rgba(0,0,0,0.06);
            text-align: center;
        }

        .status-icon {
            font-size: 54px;
            margin-bottom: 15px;
        }

        .status-badge-pending {
            display: inline-block;
            background: #fef3c7;
            color: #92400e;
            padding: 6px 16px;
            border-radius: 20px;
            font-weight: 700;
            font-size: 13px;
            margin-bottom: 20px;
            border: 1px solid #fde68a;
        }

        .details-box {
            text-align: left;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 20px;
            margin: 25px 0;
            font-size: 14px;
        }

        .details-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px dashed #e2e8f0;
        }

        .details-row:last-child {
            border-bottom: none;
        }

        .details-label {
            color: #64748b;
            font-weight: 600;
        }

        .details-val {
            color: #0f172a;
            font-weight: 500;
        }

        .action-btns {
            display: flex;
            justify-content: center;
            gap: 14px;
            margin-top: 25px;
            flex-wrap: wrap;
        }
    </style>
</head>
<body>

<header class="app-header">
    <div class="brand">
        CARGO <span>CTMS</span> | Driver Portal
    </div>
    <div>
        <a class="btn btn-secondary" href="<%= ctx %>/driver/profile">My Profile</a>
        <a class="btn btn-danger" href="<%= ctx %>/logout" style="margin-left: 8px;">Logout</a>
    </div>
</header>

<div class="container">
    <div class="pending-card">
        <h1 style="color: #0d3b66; font-size: 24px; margin-bottom: 6px;">Application Pending Approval</h1>
        <div><span class="status-badge-pending">Status: PENDING ADMINISTRATOR REVIEW</span></div>

        <p style="color: #475569; font-size: 14px; line-height: 1.6;">
            Thank you for registering with the <strong>Cargo Transportation Management System</strong>.
            Your driver profile has been received. Restricted operations (such as accepting shipments and updating delivery routes)
            will remain locked until an administrator reviews and verifies your driving credentials.
        </p>

        <% if (driver != null) { %>
            <div class="details-box">
                <h3 style="color: #0d3b66; margin-bottom: 12px; font-size: 15px;">Submitted Profile Information (Read-Only)</h3>
                <div class="details-row">
                    <span class="details-label">Driver ID:</span>
                    <span class="details-val">#<%= driver.getDriverId() %></span>
                </div>
                <div class="details-row">
                    <span class="details-label">Full Name:</span>
                    <span class="details-val"><%= driver.getDriverName() %></span>
                </div>
                <div class="details-row">
                    <span class="details-label">Username:</span>
                    <span class="details-val">@<%= driver.getUsername() %></span>
                </div>
                <div class="details-row">
                    <span class="details-label">Email:</span>
                    <span class="details-val"><%= driver.getEmail() %></span>
                </div>
                <div class="details-row">
                    <span class="details-label">Phone:</span>
                    <span class="details-val"><%= driver.getPhone() %></span>
                </div>
                <div class="details-row">
                    <span class="details-label">License Number:</span>
                    <span class="details-val"><code><%= driver.getLicenseNumber() %></code></span>
                </div>
                <div class="details-row">
                    <span class="details-label">Experience:</span>
                    <span class="details-val"><%= driver.getExperienceYears() %> Years</span>
                </div>
                <div class="details-row">
                    <span class="details-label">Submission Date:</span>
                    <span class="details-val"><%= driver.getCreatedAt() != null ? driver.getCreatedAt() : "Recently" %></span>
                </div>
            </div>
        <% } %>

        <div class="action-btns">
            <a href="<%= ctx %>/driver-approval-pending.jsp" class="btn btn-primary" style="padding: 10px 20px;">
                Check Approval Status
            </a>
            <a href="<%= ctx %>/driver/profile" class="btn btn-secondary" style="padding: 10px 20px;">
                Manage Profile
            </a>
            <a href="<%= ctx %>/logout" class="btn btn-danger" style="padding: 10px 20px;">
                Logout
            </a>
        </div>
    </div>
</div>

<footer class="app-footer">
    Cargo Transportation Management System • Driver Portal • LBRCE
</footer>

</body>
</html>
