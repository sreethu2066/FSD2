<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List,java.util.Map" %>
<%
    if (session.getAttribute("userId") == null || !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    String ctx = request.getContextPath();
    List<Map<String, Object>> vehicles = (List<Map<String, Object>>) request.getAttribute("vehicles");
    String error = request.getParameter("error");
    String success = request.getParameter("success");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fleet Vehicles Management | CTMS Admin</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        body { background: #f1f5f9; color: #1e293b; }
        .navbar { background: #0f172a; color: white; padding: 18px 6%; display: flex; justify-content: space-between; align-items: center; }
        .navbar h2 { font-size: 20px; font-weight: 700; color: #38bdf8; }
        .nav-links a { color: #cbd5e1; text-decoration: none; margin-left: 18px; font-weight: 500; font-size: 14px; }
        .nav-links a:hover { color: white; }
        .container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
        .header-action { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; }
        .header-action h1 { font-size: 24px; color: #0f172a; }
        .btn { display: inline-block; padding: 10px 18px; border-radius: 8px; font-weight: 600; text-decoration: none; cursor: pointer; border: none; font-size: 14px; }
        .btn-primary { background: #0284c7; color: white; }
        .btn-primary:hover { background: #0369a1; }
        .btn-edit { background: #f8fafc; color: #0284c7; border: 1px solid #cbd5e1; padding: 6px 12px; font-size: 13px; }
        .btn-edit:hover { background: #e0f2fe; }
        .btn-delete { background: #fef2f2; color: #dc2626; border: 1px solid #fecaca; padding: 6px 12px; font-size: 13px; margin-left: 6px; }
        .btn-delete:hover { background: #fee2e2; }
        .alert { padding: 14px 18px; border-radius: 8px; margin-bottom: 20px; font-size: 14px; }
        .alert-success { background: #dcfce7; color: #166534; border: 1px solid #bbf7d0; }
        .alert-error { background: #fee2e2; color: #991b1b; border: 1px solid #fecaca; }
        .table-wrap { background: white; border-radius: 12px; overflow-x: auto; box-shadow: 0 4px 15px rgba(0,0,0,.04); border: 1px solid #e2e8f0; }
        table { width: 100%; border-collapse: collapse; text-align: left; font-size: 14px; }
        th { background: #f8fafc; color: #475569; font-weight: 600; padding: 14px 16px; border-bottom: 1px solid #e2e8f0; }
        td { padding: 14px 16px; border-bottom: 1px solid #f1f5f9; vertical-align: middle; }
        tr:hover { background: #f8fafc; }
        .status-badge { display: inline-block; padding: 4px 10px; border-radius: 12px; font-size: 12px; font-weight: 600; }
        .badge-available { background: #dcfce7; color: #15803d; }
        .badge-assigned { background: #e0f2fe; color: #0369a1; }
        .badge-maintenance { background: #fee2e2; color: #b91c1c; }
    </style>
</head>
<body>

<div class="navbar">
    <h2>CTMS Admin Fleet</h2>
    <div class="nav-links">
        <a href="<%= ctx %>/admin/dashboard.jsp">Dashboard</a>
        <a href="<%= ctx %>/admin/bookings">Bookings</a>
        <a href="<%= ctx %>/admin/shipments">Shipments</a>
        <a href="<%= ctx %>/admin/drivers">Drivers</a>
        <a href="<%= ctx %>/admin/vehicles" style="color:white; font-weight:bold;">Vehicles</a>
        <a href="<%= ctx %>/admin/payments">Payments</a>
        <a href="<%= ctx %>/admin/feedback">Feedback</a>
        <a href="<%= ctx %>/logout">Logout</a>
    </div>
</div>

<div class="container">
    <div class="header-action">
        <div>
            <h1>Fleet Vehicles Management</h1>
            <p style="color:#64748b; font-size:14px; margin-top:4px;">Register, configure capacity (kg), and track status across all transport vehicles.</p>
        </div>
        <a class="btn btn-primary" href="<%= ctx %>/admin/vehicles?action=add">+ Add Vehicle</a>
    </div>

    <% if ("added".equals(success)) { %>
        <div class="alert alert-success">Vehicle registered successfully into fleet.</div>
    <% } else if ("updated".equals(success)) { %>
        <div class="alert alert-success">Vehicle details updated successfully.</div>
    <% } else if ("deleted".equals(success)) { %>
        <div class="alert alert-success">Vehicle deleted successfully.</div>
    <% } %>

    <% if ("duplicate".equals(error)) { %>
        <div class="alert alert-error">Error: A vehicle with this registration number already exists.</div>
    <% } else if ("shipment".equals(error)) { %>
        <div class="alert alert-error">Cannot delete: This vehicle has linked shipment records. Set status to MAINTENANCE instead.</div>
    <% } else if ("capacity".equals(error)) { %>
        <div class="alert alert-error">Error: Vehicle capacity must be a positive number in kg.</div>
    <% } else if ("required".equals(error)) { %>
        <div class="alert alert-error">Error: Please provide all required vehicle details.</div>
    <% } %>

    <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Vehicle Number</th>
                    <th>Vehicle Type</th>
                    <th>Capacity (kg)</th>
                    <th>Current Status</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
            <% if (vehicles != null && !vehicles.isEmpty()) {
                for (Map<String, Object> v : vehicles) { 
                    String st = String.valueOf(v.get("status"));
                    String badgeClass = "badge-available";
                    if ("ASSIGNED".equalsIgnoreCase(st)) badgeClass = "badge-assigned";
                    else if ("MAINTENANCE".equalsIgnoreCase(st)) badgeClass = "badge-maintenance";
            %>
                <tr>
                    <td><strong>#<%= v.get("vehicleId") %></strong></td>
                    <td><strong style="color:#0f172a;"><%= v.get("vehicleNumber") %></strong></td>
                    <td><%= v.get("vehicleType") %></td>
                    <td><strong><%= v.get("capacity") %></strong> kg</td>
                    <td><span class="status-badge <%= badgeClass %>"><%= st %></span></td>
                    <td>
                        <a class="btn btn-edit" href="<%= ctx %>/admin/vehicles?action=edit&id=<%= v.get("vehicleId") %>">Edit</a>
                        <form method="post" action="<%= ctx %>/admin/vehicles" style="display:inline" onsubmit="return confirm('Are you sure you want to delete this vehicle?');">
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="vehicleId" value="<%= v.get("vehicleId") %>">
                            <button class="btn btn-delete" type="submit">Delete</button>
                        </form>
                    </td>
                </tr>
            <%  }
               } else { %>
                <tr><td colspan="6" style="text-align:center; padding:30px; color:#64748b;">No vehicles registered in fleet yet.</td></tr>
            <% } %>
            </tbody>
        </table>
    </div>
</div>

</body>
</html>
