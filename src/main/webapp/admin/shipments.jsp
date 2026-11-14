<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%
    if (session.getAttribute("userId") == null || !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    String ctx = request.getContextPath();
    List<Map<String, Object>> shipments = (List<Map<String, Object>>) request.getAttribute("shipments");
    List<Map<String, Object>> availableVehicles = (List<Map<String, Object>>) request.getAttribute("availableVehicles");
    List<Map<String, Object>> availableDrivers = (List<Map<String, Object>>) request.getAttribute("availableDrivers");

    String success = request.getParameter("success");
    String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Shipment Dispatch & Tracking | CTMS Admin</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        body { background: #f1f5f9; color: #1e293b; }
        .navbar { background: #0f172a; color: white; padding: 18px 6%; display: flex; justify-content: space-between; align-items: center; }
        .navbar h2 { font-size: 20px; font-weight: 700; color: #38bdf8; }
        .nav-links a { color: #cbd5e1; text-decoration: none; margin-left: 18px; font-weight: 500; font-size: 14px; }
        .nav-links a:hover { color: white; }
        .container { max-width: 1450px; margin: 30px auto; padding: 0 20px; }
        .header-title { margin-bottom: 24px; }
        .header-title h1 { font-size: 24px; color: #0f172a; }
        .header-title p { color: #64748b; font-size: 14px; margin-top: 4px; }
        .alert { padding: 14px 18px; border-radius: 8px; margin-bottom: 20px; font-size: 14px; }
        .alert-success { background: #dcfce7; color: #166534; border: 1px solid #bbf7d0; }
        .alert-error { background: #fee2e2; color: #991b1b; border: 1px solid #fecaca; }
        .table-wrap { background: white; border-radius: 12px; overflow-x: auto; box-shadow: 0 4px 15px rgba(0,0,0,.04); border: 1px solid #e2e8f0; }
        table { width: 100%; border-collapse: collapse; text-align: left; font-size: 13px; }
        th { background: #f8fafc; color: #475569; font-weight: 600; padding: 14px 12px; border-bottom: 1px solid #e2e8f0; }
        td { padding: 14px 12px; border-bottom: 1px solid #f1f5f9; vertical-align: top; }
        tr:hover { background: #f8fafc; }
        .status-badge { display: inline-block; padding: 4px 10px; border-radius: 12px; font-size: 11px; font-weight: 700; text-transform: uppercase; }
        .badge-pending { background: #fef3c7; color: #b45309; }
        .badge-picked { background: #e0f2fe; color: #0369a1; }
        .badge-transit { background: #f3e8ff; color: #7e22ce; }
        .badge-out { background: #fed7aa; color: #c2410c; }
        .badge-delivered { background: #dcfce7; color: #15803d; }
        .badge-failed { background: #fee2e2; color: #b91c1c; }
        .form-control { width: 100%; padding: 7px 10px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 12px; margin-bottom: 6px; box-sizing: border-box; }
        .btn-assign { background: #0284c7; color: white; border: none; padding: 8px 12px; border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 12px; width: 100%; }
        .btn-assign:hover { background: #0369a1; }
        .btn-update { background: #0f766e; color: white; border: none; padding: 7px 10px; border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 12px; width: 100%; }
        .btn-update:hover { background: #115e59; }
        .cargo-box { background: #f8fafc; padding: 8px; border-radius: 6px; border: 1px solid #e2e8f0; }
    </style>
</head>
<body>

<div class="navbar">
    <h2>CTMS Admin Dispatch</h2>
    <div class="nav-links">
        <a href="<%= ctx %>/admin/dashboard.jsp">Dashboard</a>
        <a href="<%= ctx %>/admin/bookings">Bookings</a>
        <a href="<%= ctx %>/admin/shipments" style="color:white; font-weight:bold;">Shipments</a>
        <a href="<%= ctx %>/admin/drivers">Drivers</a>
        <a href="<%= ctx %>/admin/vehicles">Vehicles</a>
        <a href="<%= ctx %>/admin/payments">Payments</a>
        <a href="<%= ctx %>/admin/feedback">Feedback</a>
        <a href="<%= ctx %>/logout">Logout</a>
    </div>
</div>

<div class="container">
    <div class="header-title">
        <h1>Shipment Dispatch &amp; Fleet Assignment</h1>
        <p>Assign available drivers and vehicles (with automated capacity check: vehicle capacity >= cargo weight) and track live delivery status.</p>
    </div>

    <% if ("1".equals(success)) { %>
        <div class="alert alert-success">Shipment updated successfully.</div>
    <% } %>

    <% if (error != null && !error.trim().isEmpty()) { %>
        <div class="alert alert-error"><%= error %></div>
    <% } %>

    <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <th>Shipment / Tracking</th>
                    <th>Customer &amp; Route</th>
                    <th>Cargo Details</th>
                    <th>Status &amp; Location</th>
                    <th style="min-width: 240px;">Driver &amp; Vehicle Assignment</th>
                    <th style="min-width: 200px;">Status Transition</th>
                    <th>Timeline</th>
                </tr>
            </thead>
            <tbody>
            <% if (shipments != null && !shipments.isEmpty()) {
                for (Map<String, Object> s : shipments) {
                    String st = String.valueOf(s.get("status"));
                    String badgeClass = "badge-pending";
                    if ("PICKED_UP".equals(st)) badgeClass = "badge-picked";
                    else if ("IN_TRANSIT".equals(st)) badgeClass = "badge-transit";
                    else if ("OUT_FOR_DELIVERY".equals(st)) badgeClass = "badge-out";
                    else if ("DELIVERED".equals(st)) badgeClass = "badge-delivered";
                    else if ("FAILED".equals(st)) badgeClass = "badge-failed";

                    boolean hasVehicle = (s.get("vehicleId") != null);
                    boolean hasDriver = (s.get("driverId") != null);
                    boolean isDelivered = "DELIVERED".equals(st);
            %>
                <tr>
                    <td>
                        <strong style="color:#0284c7; font-size:14px;"><%= s.get("trackingNumber") %></strong><br>
                        <small style="color:#64748b;">Shipment #<%= s.get("shipmentId") %> | Booking #<%= s.get("bookingId") %></small>
                    </td>

                    <td>
                        <strong><%= s.get("customerName") %></strong><br>
                        <small>Phone: <%= s.get("customerPhone") %></small><br>
                        <span style="color:#475569;"><%= s.get("pickupCity") %> to <%= s.get("deliveryCity") %></span>
                    </td>

                    <td>
                        <div class="cargo-box">
                            <strong><%= s.get("cargoType") %></strong><br>
                            Weight: <strong style="color:#dc2626;"><%= s.get("weightKg") %> kg</strong><br>
                            Amount: ₹<%= s.get("totalAmount") %>
                        </div>
                    </td>

                    <td>
                        <span class="status-badge <%= badgeClass %>"><%= st %></span><br>
                        <small style="display:inline-block; margin-top:4px; color:#475569;">
                            Location: <%= s.get("currentLocation") != null ? s.get("currentLocation") : "Processing Center" %>
                        </small>
                    </td>

                    <td>
                        <% if (!hasVehicle || !hasDriver) { %>
                            <form method="post" action="<%= ctx %>/admin/shipments">
                                <input type="hidden" name="action" value="assign">
                                <input type="hidden" name="shipmentId" value="<%= s.get("shipmentId") %>">

                                <label style="font-size:11px; font-weight:600; color:#475569;">Assign Vehicle (&gt;= <%= s.get("weightKg") %> kg):</label>
                                <select name="vehicleId" class="form-control" required>
                                    <option value="">-- Choose Available Vehicle --</option>
                                    <% if (availableVehicles != null) {
                                        for (Map<String, Object> v : availableVehicles) { %>
                                            <option value="<%= v.get("vehicleId") %>">
                                                <%= v.get("vehicleNumber") %> (<%= v.get("vehicleType") %> - <%= v.get("capacityKg") %> kg)
                                            </option>
                                    <%  }
                                       } %>
                                </select>

                                <label style="font-size:11px; font-weight:600; color:#475569;">Assign Driver:</label>
                                <select name="driverId" class="form-control" required>
                                    <option value="">-- Choose Available Driver --</option>
                                    <% if (availableDrivers != null) {
                                        for (Map<String, Object> d : availableDrivers) { %>
                                            <option value="<%= d.get("driverId") %>">
                                                <%= d.get("driverName") %> (Phone: <%= d.get("phone") %>)
                                            </option>
                                    <%  }
                                       } %>
                                </select>

                                <button type="submit" class="btn-assign">Assign &amp; Dispatch</button>
                            </form>
                        <% } else { %>
                            <div style="background:#f0fdf4; padding:8px; border-radius:6px; border:1px solid #bbf7d0;">
                                <strong style="color:#166534;">Vehicle: <%= s.get("vehicleNumber") %></strong> (<%= s.get("vehicleType") %>, <%= s.get("vehicleCapacity") %> kg)<br>
                                <strong style="color:#1e3a8a;">Driver: <%= s.get("driverName") %></strong><br>
                                <small>Phone: <%= s.get("driverPhone") %></small>
                            </div>
                        <% } %>
                    </td>

                    <td>
                        <% if (!isDelivered) { %>
                            <form method="post" action="<%= ctx %>/admin/shipments">
                                <input type="hidden" name="action" value="updateStatus">
                                <input type="hidden" name="shipmentId" value="<%= s.get("shipmentId") %>">

                                <select name="status" class="form-control" required>
                                    <option value="PICKED_UP" <%= "PICKED_UP".equals(st) ? "selected" : "" %>>PICKED_UP</option>
                                    <option value="IN_TRANSIT" <%= "IN_TRANSIT".equals(st) ? "selected" : "" %>>IN_TRANSIT</option>
                                    <option value="OUT_FOR_DELIVERY" <%= "OUT_FOR_DELIVERY".equals(st) ? "selected" : "" %>>OUT_FOR_DELIVERY</option>
                                    <option value="DELIVERED" <%= "DELIVERED".equals(st) ? "selected" : "" %>>DELIVERED</option>
                                    <option value="FAILED" <%= "FAILED".equals(st) ? "selected" : "" %>>FAILED</option>
                                </select>

                                <input type="text" name="currentLocation" class="form-control" placeholder="Update Location"
                                       value="<%= s.get("currentLocation") != null ? s.get("currentLocation") : "" %>">

                                <input type="text" name="remarks" class="form-control" placeholder="Remarks (optional)">

                                <button type="submit" class="btn-update">Update Status</button>
                            </form>
                        <% } else { %>
                            <span style="color:#15803d; font-weight:600;">Completed &amp; Closed</span>
                        <% } %>
                    </td>

                    <td>
                        <small style="color:#64748b;">
                            Dispatched:<br><strong><%= s.get("shippedDate") != null ? s.get("shippedDate") : "Not dispatched" %></strong><br><br>
                            Delivered:<br><strong><%= s.get("deliveredDate") != null ? s.get("deliveredDate") : "—" %></strong>
                        </small>
                    </td>
                </tr>
            <%  }
               } else { %>
                <tr><td colspan="7" style="text-align:center; padding:40px; color:#64748b;">No active shipments found. Confirm bookings from the Bookings page to generate shipments.</td></tr>
            <% } %>
            </tbody>
        </table>
    </div>
</div>

</body>
</html>
