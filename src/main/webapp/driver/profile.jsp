<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.cargo.model.Driver" %>
<%@ page import="com.cargo.dao.UserDAO" %>

<%
    String role = (String) session.getAttribute("role");
    if (session.getAttribute("userId") == null || !"DRIVER".equalsIgnoreCase(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    String ctx = request.getContextPath();
    Driver driver = (Driver) request.getAttribute("driver");

    // Fallback if accessed directly: load driver strictly using session's userId
    if (driver == null) {
        int userId = (Integer) session.getAttribute("userId");
        UserDAO userDAO = new UserDAO();
        try {
            driver = userDAO.findDriverByUserId(userId);
        } catch (Exception e) {
            response.sendRedirect(ctx + "/login.jsp?error=server");
            return;
        }
    }

    if (driver == null) {
        response.sendRedirect(ctx + "/driver-approval-pending.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Driver Profile | Cargo Transportation System</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
    <style>
        .profile-container {
            max-width: 780px;
            margin: 30px auto;
        }

        .back-link {
            color: #0284c7;
            text-decoration: none;
            font-weight: 600;
            font-size: 14px;
            display: inline-block;
            margin-bottom: 18px;
        }

        .back-link:hover {
            text-decoration: underline;
        }

        .profile-card {
            background: white;
            padding: 30px;
            border-radius: 12px;
            border: 1px solid #e2e8f0;
            box-shadow: 0 4px 12px rgba(0,0,0,0.05);
        }

        .profile-header {
            display: flex;
            align-items: center;
            gap: 18px;
            border-bottom: 2px solid #f1f5f9;
            padding-bottom: 20px;
            margin-bottom: 24px;
        }

        .avatar-circle {
            width: 64px;
            height: 64px;
            border-radius: 50%;
            background: #e0f2fe;
            color: #0284c7;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 28px;
            font-weight: 700;
        }

        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }

        .form-group {
            margin-bottom: 18px;
        }

        .form-group.full-width {
            grid-column: 1 / -1;
        }

        label {
            display: block;
            margin-bottom: 6px;
            font-size: 13px;
            font-weight: 600;
            color: #334155;
        }

        input[type="text"],
        input[type="email"] {
            width: 100%;
            padding: 11px 14px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-size: 14px;
            box-sizing: border-box;
            background: #ffffff;
        }

        input[readonly] {
            background: #f8fafc;
            color: #64748b;
            cursor: not-allowed;
            border-color: #e2e8f0;
        }

        .status-badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 14px;
            font-size: 12px;
            font-weight: 700;
        }

        .badge-available { background: #dcfce7; color: #15803d; }
        .badge-assigned { background: #e0f2fe; color: #0369a1; }
        .badge-inactive { background: #fef3c7; color: #b45309; }

        .helper-text {
            font-size: 11px;
            color: #94a3b8;
            margin-top: 4px;
        }
    </style>
</head>
<body>

<header class="app-header">
    <div class="brand">
        CARGO <span>CTMS</span> | Driver Portal
    </div>
    <div>
        <a class="btn btn-secondary" href="<%= ctx %>/driver-dashboard.jsp">Dashboard</a>
        <a class="btn btn-danger" href="<%= ctx %>/logout" style="margin-left: 8px;">Logout</a>
    </div>
</header>

<div class="container profile-container">

    <a class="back-link" href="<%= ctx %>/driver-dashboard.jsp">Back to Dashboard</a>

    <%
        String success = request.getParameter("success");
        String error = request.getParameter("error");
        if ("updated".equals(success)) {
    %>
        <div class="alert alert-success">Profile details updated successfully!</div>
    <% } else if ("email_exists".equals(error)) { %>
        <div class="alert alert-error">That email address is already registered to another account.</div>
    <% } else if ("invalid_email".equals(error)) { %>
        <div class="alert alert-error">Please enter a valid email address.</div>
    <% } else if ("required".equals(error)) { %>
        <div class="alert alert-error">Phone and Email fields are required.</div>
    <% } else if (error != null) { %>
        <div class="alert alert-error">Failed to update profile: <%= error %></div>
    <% } %>

    <div class="profile-card">
        <div class="profile-header">
            <div class="avatar-circle"><%= driver.getDriverName() != null && !driver.getDriverName().isEmpty() ? driver.getDriverName().substring(0, 1).toUpperCase() : "D" %></div>
            <div>
                <h1 style="font-size: 22px; color: #0d3b66; margin-bottom: 4px;"><%= driver.getDriverName() %></h1>
                <div style="font-size: 13px; color: #64748b;">
                    Driver ID: <strong>#<%= driver.getDriverId() %></strong> • Username: <strong>@<%= driver.getUsername() %></strong>
                </div>
            </div>
        </div>

        <form action="<%= ctx %>/driver/update-profile" method="post" id="profileForm">
            <div class="form-grid">

                <!-- Read-Only Administrative Fields -->
                <div class="form-group">
                    <label>Driver ID (Protected)</label>
                    <input type="text" value="#<%= driver.getDriverId() %>" readonly>
                    <div class="helper-text">Assigned system identifier</div>
                </div>

                <div class="form-group">
                    <label>System Username (Protected)</label>
                    <input type="text" value="<%= driver.getUsername() %>" readonly>
                    <div class="helper-text">Unique login username</div>
                </div>

                <div class="form-group">
                    <label>Full Legal Name (Protected)</label>
                    <input type="text" value="<%= driver.getDriverName() %>" readonly>
                    <div class="helper-text">Official name registered on license</div>
                </div>

                <div class="form-group">
                    <label>Driving License Number (Protected)</label>
                    <input type="text" value="<%= driver.getLicenseNumber() %>" readonly>
                    <div class="helper-text">Verified state commercial license</div>
                </div>

                <div class="form-group">
                    <label>Driving Experience</label>
                    <input type="text" value="<%= driver.getExperienceYears() %> Years" readonly>
                    <div class="helper-text">Commercial freight experience</div>
                </div>

                <div class="form-group">
                    <label>Current Account Status (Protected)</label>
                    <div>
                        <%
                            String st = driver.getStatus() != null ? driver.getStatus().toUpperCase() : "INACTIVE";
                            String badgeClass = "badge-available";
                            if ("ASSIGNED".equals(st)) badgeClass = "badge-assigned";
                            else if ("INACTIVE".equals(st)) badgeClass = "badge-inactive";
                        %>
                        <span class="status-badge <%= badgeClass %>"><%= st %></span>
                    </div>
                    <div class="helper-text">Admin authorization status</div>
                </div>

                <div class="form-group full-width">
                    <label>Account Registration Date (Protected)</label>
                    <input type="text" value="<%= driver.getCreatedAt() != null ? driver.getCreatedAt() : "Recently registered" %>" readonly>
                </div>

                <!-- Editable Permitted Fields -->
                <div class="form-group full-width" style="border-top: 1px solid #e2e8f0; padding-top: 18px; margin-top: 8px;">
                    <h3 style="color: #0d3b66; font-size: 16px; margin-bottom: 6px;">Editable Contact Information</h3>
                    <p style="font-size: 13px; color: #64748b; margin-bottom: 16px;">
                        You are permitted to update your primary phone number and contact email.
                    </p>
                </div>

                <div class="form-group">
                    <label for="phone">Phone Number *</label>
                    <input type="text" id="phone" name="phone" value="<%= driver.getPhone() != null ? driver.getPhone() : "" %>" required maxlength="15">
                </div>

                <div class="form-group">
                    <label for="email">Email Address *</label>
                    <input type="email" id="email" name="email" value="<%= driver.getEmail() != null ? driver.getEmail() : "" %>" required maxlength="100">
                </div>

            </div>

            <div style="margin-top: 20px;">
                <button type="submit" class="btn btn-primary" style="padding: 11px 24px; font-size: 14px;">
                    Save Contact Changes
                </button>
            </div>
        </form>
    </div>

</div>

<footer class="app-footer">
    Cargo Transportation Management System • Driver Portal • LBRCE
</footer>

</body>
</html>
