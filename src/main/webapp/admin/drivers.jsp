<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>

<%
    String role = (String) session.getAttribute("role");
    if (session.getAttribute("userId") == null || !"ADMIN".equalsIgnoreCase(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    if (request.getAttribute("drivers") == null) {
        response.sendRedirect(request.getContextPath() + "/admin/drivers");
        return;
    }

    List<Map<String, Object>> drivers = (List<Map<String, Object>>) request.getAttribute("drivers");
    String ctx = request.getContextPath();

    int totalDrivers = drivers != null ? drivers.size() : 0;
    int availableCount = 0;
    int assignedCount = 0;
    int inactiveCount = 0;

    if (drivers != null) {
        for (Map<String, Object> d : drivers) {
            String st = String.valueOf(d.get("status"));
            if ("AVAILABLE".equalsIgnoreCase(st)) availableCount++;
            else if ("ASSIGNED".equalsIgnoreCase(st)) assignedCount++;
            else if ("INACTIVE".equalsIgnoreCase(st)) inactiveCount++;
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Driver Fleet Management | Cargo Transportation System</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
    <style>
        .top-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 24px;
            flex-wrap: wrap;
            gap: 12px;
        }

        .back-link {
            color: #0284c7;
            text-decoration: none;
            font-weight: 600;
            font-size: 14px;
        }

        .back-link:hover {
            text-decoration: underline;
        }

        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 16px;
            margin-bottom: 25px;
        }

        .summary-card {
            background: white;
            padding: 18px 20px;
            border-radius: 10px;
            border: 1px solid #e2e8f0;
            box-shadow: 0 2px 6px rgba(0,0,0,0.04);
        }

        .summary-label {
            font-size: 12px;
            color: #64748b;
            text-transform: uppercase;
            font-weight: 600;
        }

        .summary-val {
            font-size: 24px;
            font-weight: 700;
            color: #0f172a;
            margin-top: 4px;
        }

        .status-badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
        }

        .badge-available { background: #dcfce7; color: #15803d; }
        .badge-assigned { background: #e0f2fe; color: #0369a1; }
        .badge-inactive { background: #fef3c7; color: #b45309; }

        .btn-action {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 600;
            text-decoration: none;
            border: none;
            cursor: pointer;
            transition: all 0.2s;
        }

        .btn-edit { background: #0284c7; color: white; }
        .btn-edit:hover { background: #0369a1; }

        .btn-activate { background: #16a34a; color: white; }
        .btn-activate:hover { background: #15803d; }

        .btn-deactivate { background: #d97706; color: white; }
        .btn-deactivate:hover { background: #b45309; }

        .btn-reset { background: #475569; color: white; }
        .btn-reset:hover { background: #334155; }

        .btn-delete { background: #dc2626; color: white; }
        .btn-delete:hover { background: #b91c1c; }

        .actions-cell {
            display: flex;
            align-items: center;
            gap: 6px;
            flex-wrap: wrap;
        }

        .cred-box {
            background: #ecfdf5;
            border: 1px solid #6ee7b7;
            padding: 14px 18px;
            border-radius: 8px;
            margin-bottom: 20px;
            color: #065f46;
            font-size: 14px;
        }
    </style>
</head>
<body>

<header class="app-header">
    <div class="brand">
        CARGO <span>CTMS</span> | Admin Management
    </div>
    <div>
        <a class="btn btn-secondary" href="<%= ctx %>/admin/dashboard.jsp">Dashboard</a>
        <a class="btn btn-danger" href="<%= ctx %>/logout" style="margin-left: 8px;">Logout</a>
    </div>
</header>

<div class="container">

    <div class="top-bar">
        <div>
            <a class="back-link" href="<%= ctx %>/admin/dashboard.jsp">Back to Admin Dashboard</a>
            <h1 style="margin-top: 8px;">Fleet Driver Management</h1>
            <p class="subtitle">Review registered drivers, approve self-registered applicants, provision driver accounts, and manage fleet assignments.</p>
        </div>
        <div>
            <a href="<%= ctx %>/admin/add-driver" class="btn btn-primary" style="padding: 10px 18px; font-size: 14px;">
                Add New Driver
            </a>
        </div>
    </div>

    <% 
        String success = request.getParameter("success");
        String error = request.getParameter("error");
        String createdUser = request.getParameter("createdUser");
        String createdPass = request.getParameter("createdPass");
        String tempPass = request.getParameter("tempPass");

        if ("driver_created".equals(success)) {
    %>
        <div class="cred-box">
            <strong>Driver Account Created Successfully!</strong><br>
            Please securely provide these login credentials to the driver:<br>
            • Username: <strong><%= createdUser != null ? createdUser : "" %></strong><br>
            • Temporary Password: <code><%= createdPass != null ? createdPass : "" %></code><br>
            • Role: <strong>DRIVER</strong>
        </div>
    <% } else if ("password_reset".equals(success)) { %>
        <div class="cred-box">
            <strong>Password Reset Successfully!</strong><br>
            New Temporary Password: <code><%= tempPass != null ? tempPass : "" %></code>
        </div>
    <% } else if ("status_updated".equals(success)) { %>
        <div class="alert alert-success">Driver status updated successfully!</div>
    <% } else if ("driver_updated".equals(success)) { %>
        <div class="alert alert-success">Driver information updated successfully.</div>
    <% } else if ("driver_deleted".equals(success)) { %>
        <div class="alert alert-success">Driver record deleted.</div>
    <% } else if ("vehicleassigned".equals(error)) { %>
        <div class="alert alert-error">Cannot delete driver: This driver is actively assigned to a fleet vehicle. Unassign the vehicle first.</div>
    <% } else if (error != null) { %>
        <div class="alert alert-error">Operation failed: <%= error %></div>
    <% } %>

    <!-- KPI Summary Grid -->
    <div class="summary-grid">
        <div class="summary-card">
            <div class="summary-label">Total Fleet Drivers</div>
            <div class="summary-val"><%= totalDrivers %></div>
        </div>
        <div class="summary-card">
            <div class="summary-label">Available on Duty</div>
            <div class="summary-val" style="color: #16a34a;"><%= availableCount %></div>
        </div>
        <div class="summary-card">
            <div class="summary-label">Assigned to Shipments</div>
            <div class="summary-val" style="color: #0284c7;"><%= assignedCount %></div>
        </div>
        <div class="summary-card">
            <div class="summary-label">Pending Approval / Inactive</div>
            <div class="summary-val" style="color: #d97706;"><%= inactiveCount %></div>
        </div>
    </div>

    <!-- Drivers Table -->
    <div class="table-responsive">
        <table>
            <thead>
                <tr>
                    <th>Driver ID</th>
                    <th>Driver Name & User</th>
                    <th>Contact Details</th>
                    <th>License Number</th>
                    <th>Experience</th>
                    <th>Vehicle Assigned</th>
                    <th>Status</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <% if (drivers != null && !drivers.isEmpty()) { 
                    for (Map<String, Object> d : drivers) {
                        String st = String.valueOf(d.get("status"));
                        String badgeClass = "badge-available";
                        if ("ASSIGNED".equalsIgnoreCase(st)) badgeClass = "badge-assigned";
                        else if ("INACTIVE".equalsIgnoreCase(st)) badgeClass = "badge-inactive";
                %>
                    <tr>
                        <td><strong>#<%= d.get("driverId") %></strong></td>
                        <td>
                            <strong><%= d.get("name") %></strong><br>
                            <small style="color: #64748b;">
                                @<%= d.get("username") != null ? d.get("username") : "driver_" + d.get("driverId") %>
                            </small>
                        </td>
                        <td>
                            Phone: <%= d.get("phone") %><br>
                            <small style="color: #64748b;">Email: <%= d.get("email") != null ? d.get("email") : "N/A" %></small>
                        </td>
                        <td>
                            <code><%= d.get("licenseNumber") %></code>
                        </td>
                        <td>
                            <%= d.get("experienceYears") %> Years
                        </td>
                        <td>
                            <% if (d.get("vehicleNumber") != null) { %>
                                <strong><%= d.get("vehicleNumber") %></strong><br>
                                <small style="color: #64748b;"><%= d.get("vehicleModel") %></small>
                            <% } else { %>
                                <span style="color: #94a3b8; font-style: italic;">None assigned</span>
                            <% } %>
                        </td>
                        <td>
                            <span class="status-badge <%= badgeClass %>"><%= st %></span>
                            <% if ("INACTIVE".equalsIgnoreCase(st)) { %>
                                <br><small style="color: #d97706; font-size: 10px;">Pending Approval</small>
                            <% } %>
                        </td>
                        <td>
                            <div class="actions-cell">
                                <!-- Quick Activate / Deactivate -->
                                <form action="<%= ctx %>/admin/drivers" method="post" style="display:inline;">
                                    <input type="hidden" name="action" value="toggleStatus">
                                    <input type="hidden" name="driverId" value="<%= d.get("driverId") %>">
                                    <input type="hidden" name="currentStatus" value="<%= st %>">
                                    <% if ("INACTIVE".equalsIgnoreCase(st)) { %>
                                        <button type="submit" class="btn-action btn-activate" title="Approve and activate driver">
                                            Activate
                                        </button>
                                    <% } else { %>
                                        <button type="submit" class="btn-action btn-deactivate" title="Deactivate driver" onclick="return confirm('Deactivate this driver account?');">
                                            Deactivate
                                        </button>
                                    <% } %>
                                </form>

                                <!-- Edit Driver -->
                                <a href="<%= ctx %>/admin/drivers?action=edit&id=<%= d.get("driverId") %>" class="btn-action btn-edit">
                                    Edit
                                </a>

                                <!-- Reset Password Form -->
                                <form action="<%= ctx %>/admin/drivers" method="post" style="display:inline;" onsubmit="return confirm('Reset password for driver @<%= d.get("username") %>?');">
                                    <input type="hidden" name="action" value="resetPassword">
                                    <input type="hidden" name="driverId" value="<%= d.get("driverId") %>">
                                    <button type="submit" class="btn-action btn-reset" title="Generate new password">
                                        Reset Password
                                    </button>
                                </form>

                                <!-- Delete Driver Form -->
                                <form action="<%= ctx %>/admin/drivers" method="post" style="display:inline;" onsubmit="return confirm('Permanently delete Driver #<%= d.get("driverId") %> (<%= d.get("name") %>)?');">
                                    <input type="hidden" name="action" value="delete">
                                    <input type="hidden" name="driverId" value="<%= d.get("driverId") %>">
                                    <button type="submit" class="btn-action btn-delete">
                                        Delete
                                    </button>
                                </form>
                            </div>
                        </td>
                    </tr>
                <%  } 
                   } else { %>
                    <tr>
                        <td colspan="8" style="text-align: center; padding: 40px; color: #64748b;">
                            <h3>No Driver Records Found</h3>
                            <p style="font-size: 13px;">No fleet drivers are currently registered in the database.</p>
                        </td>
                    </tr>
                <% } %>
            </tbody>
        </table>
    </div>

</div>

<footer class="app-footer">
    Cargo Transportation Management System • Driver Fleet Management • LBRCE
</footer>

</body>
</html>
