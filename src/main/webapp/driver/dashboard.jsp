<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.List" %>

<%
    String role = (String) session.getAttribute("role");
    if (role == null || !"DRIVER".equalsIgnoreCase(role) || session.getAttribute("userId") == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    String username = (String) session.getAttribute("username");
    String ctx = request.getContextPath();

    // If driverInfo attribute isn't set, redirect to DriverDashboardServlet
    if (request.getAttribute("driverInfo") == null) {
        response.sendRedirect(ctx + "/driver/dashboard");
        return;
    }

    Map<String, Object> driver = (Map<String, Object>) request.getAttribute("driverInfo");
    Map<String, Object> vehicle = (Map<String, Object>) request.getAttribute("vehicleInfo");
    List<Map<String, Object>> activeDeliveries = (List<Map<String, Object>>) request.getAttribute("activeDeliveries");
    List<Map<String, Object>> completedDeliveries = (List<Map<String, Object>>) request.getAttribute("completedDeliveries");
    List<Map<String, Object>> driverReviews = (List<Map<String, Object>>) request.getAttribute("driverReviews");
    int driverReviewCount = request.getAttribute("driverReviewCount") != null ? (Integer) request.getAttribute("driverReviewCount") : 0;
    double driverAvgRating = request.getAttribute("driverAvgRating") != null ? (Double) request.getAttribute("driverAvgRating") : 5.0;
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Driver Dashboard | Cargo Transportation System</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }

        body {
            background: #f1f5f9;
            color: #1e293b;
        }

        header {
            background: linear-gradient(135deg, #0d3b66 0%, #1e3a5f 100%);
            color: white;
            padding: 18px 5%;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .brand {
            font-size: 22px;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .brand span {
            color: #38bdf8;
        }

        .header-right {
            display: flex;
            align-items: center;
            gap: 16px;
        }

        .user-tag {
            background: rgba(255, 255, 255, 0.15);
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 14px;
        }

        .btn-profile {
            color: white;
            text-decoration: none;
            background: #0284c7;
            padding: 7px 16px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 600;
            transition: background 0.2s;
        }

        .btn-profile:hover {
            background: #0369a1;
        }

        .btn-logout {
            color: white;
            text-decoration: none;
            background: #dc2626;
            padding: 7px 16px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 600;
            transition: background 0.2s;
        }

        .btn-logout:hover {
            background: #b91c1c;
        }

        main {
            max-width: 1200px;
            margin: 30px auto;
            padding: 0 20px;
        }

        .alert {
            padding: 14px 18px;
            border-radius: 8px;
            font-size: 14px;
            margin-bottom: 24px;
        }

        .alert-success {
            background: #d1fae5;
            color: #065f46;
            border: 1px solid #a7f3d0;
        }

        .alert-error {
            background: #fee2e2;
            color: #991b1b;
            border: 1px solid #fecaca;
        }

        /* Profile & Vehicle Overview Cards */
        .overview-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .panel {
            background: white;
            padding: 24px;
            border-radius: 12px;
            border: 1px solid #e2e8f0;
            box-shadow: 0 2px 8px rgba(0,0,0,0.04);
        }

        .panel h2 {
            font-size: 18px;
            color: #0d3b66;
            margin-bottom: 16px;
            display: flex;
            align-items: center;
            gap: 8px;
            border-bottom: 2px solid #e2e8f0;
            padding-bottom: 10px;
        }

        .info-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            font-size: 14px;
            border-bottom: 1px dashed #f1f5f9;
        }

        .info-label {
            color: #64748b;
            font-weight: 600;
        }

        .info-val {
            color: #0f172a;
            font-weight: 500;
        }

        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
        }

        .badge-success { background: #dcfce7; color: #15803d; }
        .badge-warning { background: #fef3c7; color: #b45309; }
        .badge-info { background: #e0f2fe; color: #0369a1; }
        .badge-purple { background: #f3e8ff; color: #7e22ce; }

        .section-title {
            font-size: 20px;
            color: #0d3b66;
            margin: 30px 0 16px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        /* Tables */
        .table-responsive {
            background: white;
            border-radius: 12px;
            border: 1px solid #e2e8f0;
            overflow-x: auto;
            box-shadow: 0 2px 8px rgba(0,0,0,0.04);
            margin-bottom: 30px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }

        th {
            background: #f8fafc;
            color: #475569;
            font-weight: 600;
            padding: 14px 16px;
            text-align: left;
            border-bottom: 1px solid #e2e8f0;
        }

        td {
            padding: 14px 16px;
            border-bottom: 1px solid #f1f5f9;
            vertical-align: middle;
        }

        tr:hover {
            background: #f8fafc;
        }

        .empty-state {
            text-align: center;
            padding: 35px 20px;
            color: #64748b;
            font-size: 14px;
        }

        /* Action Form */
        .status-form {
            display: flex;
            flex-direction: column;
            gap: 8px;
        }

        .status-form select,
        .status-form input {
            padding: 7px 10px;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            font-size: 12px;
        }

        .btn-update {
            background: #0284c7;
            color: white;
            border: none;
            padding: 8px 12px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.2s;
        }

        .btn-update:hover {
            background: #0369a1;
        }

        footer {
            margin-top: 50px;
            text-align: center;
            padding: 20px;
            color: #64748b;
            font-size: 13px;
            border-top: 1px solid #e2e8f0;
            background: white;
        }
    </style>
</head>

<body>

<header>
    <div class="brand">
        CARGO <span>CTMS</span> | Driver Portal
    </div>

    <div class="header-right">
        <span class="user-tag"><%= driver.get("name") != null ? driver.get("name") : username %></span>
        <a class="btn-profile" href="<%= ctx %>/driver/profile">My Profile</a>
        <a class="btn-logout" href="<%= ctx %>/logout">Logout</a>
    </div>
</header>

<main>

    <% 
        String updated = request.getParameter("updated");
        String error = request.getParameter("error");
        if ("success".equals(updated)) {
    %>
        <div class="alert alert-success">Delivery status updated successfully!</div>
    <% } else if (error != null) { %>
        <div class="alert alert-error">Failed to update status: <%= error %></div>
    <% } %>

    <!-- Driver & Vehicle Overview -->
    <div class="overview-grid">
        <!-- Driver Profile -->
        <div class="panel">
            <h2>Driver Profile</h2>
            <div class="info-row">
                <span class="info-label">Full Name:</span>
                <span class="info-val"><%= driver.get("name") != null ? driver.get("name") : "Not assigned" %></span>
            </div>
            <div class="info-row">
                <span class="info-label">Phone:</span>
                <span class="info-val"><%= driver.get("phone") != null ? driver.get("phone") : "N/A" %></span>
            </div>
            <div class="info-row">
                <span class="info-label">License Number:</span>
                <span class="info-val"><code><%= driver.get("license") != null ? driver.get("license") : "N/A" %></code></span>
            </div>
            <div class="info-row">
                <span class="info-label">Driving Experience:</span>
                <span class="info-val"><%= driver.get("experience") != null ? driver.get("experience") + " Years" : "N/A" %></span>
            </div>
            <div class="info-row">
                <span class="info-label">Current Duty Status:</span>
                <span class="info-val">
                    <span class="badge badge-success"><%= driver.get("status") != null ? driver.get("status") : "AVAILABLE" %></span>
                </span>
            </div>
            <div class="info-row">
                <span class="info-label">Customer Rating:</span>
                <span class="info-val">
                    <span class="badge badge-warning">Rating: <%= driverAvgRating %> / 5.0 (<%= driverReviewCount %> reviews)</span>
                </span>
            </div>
            <div style="margin-top: 16px; text-align: right;">
                <a href="<%= ctx %>/driver/profile" style="color: #0284c7; text-decoration: none; font-size: 13px; font-weight: 600;">View &amp; Update Profile</a>
            </div>
        </div>

        <!-- Assigned Vehicle -->
        <div class="panel">
            <h2>Assigned Vehicle</h2>
            <% if (vehicle != null && !vehicle.isEmpty()) { %>
                <div class="info-row">
                    <span class="info-label">Vehicle Number:</span>
                    <span class="info-val"><strong><%= vehicle.get("number") %></strong></span>
                </div>
                <div class="info-row">
                    <span class="info-label">Vehicle Type:</span>
                    <span class="info-val"><%= vehicle.get("type") %></span>
                </div>
                <div class="info-row">
                    <span class="info-label">Model:</span>
                    <span class="info-val"><%= vehicle.get("model") %></span>
                </div>
                <div class="info-row">
                    <span class="info-label">Load Capacity:</span>
                    <span class="info-val"><%= vehicle.get("capacity") %> KG</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Vehicle Status:</span>
                    <span class="info-val"><span class="badge badge-info"><%= vehicle.get("status") %></span></span>
                </div>
            <% } else { %>
                <div class="empty-state">
                    No fleet vehicle is assigned to you currently. Contact the Administrator.
                </div>
            <% } %>
        </div>
    </div>

    <!-- Active Deliveries -->
    <h2 class="section-title">Active Assigned Deliveries (<%= activeDeliveries != null ? activeDeliveries.size() : 0 %>)</h2>
    <div class="table-responsive">
        <table>
            <thead>
                <tr>
                    <th>Tracking #</th>
                    <th>Customer & Contact</th>
                    <th>Cargo Details</th>
                    <th>Route (Pickup to Drop)</th>
                    <th>Status</th>
                    <th>Update Status</th>
                </tr>
            </thead>
            <tbody>
                <% if (activeDeliveries != null && !activeDeliveries.isEmpty()) { 
                    for (Map<String, Object> d : activeDeliveries) {
                %>
                    <tr>
                        <td>
                            <strong><%= d.get("trackingNumber") %></strong><br>
                            <small style="color:#64748b;">Booking #<%= d.get("bookingId") %></small>
                        </td>
                        <td>
                            <strong><%= d.get("customerName") %></strong><br>
                            <small>Phone: <%= d.get("customerPhone") %></small>
                        </td>
                        <td>
                            <%= d.get("cargoType") %> (<%= d.get("weightKg") %> KG)<br>
                            <small>Qty: <%= d.get("quantity") %> | Fragile: <%= Boolean.TRUE.equals(d.get("fragile")) ? "Yes" : "No" %></small>
                        </td>
                        <td style="max-width: 250px;">
                            <strong>From:</strong> <%= d.get("pickupAddress") %><br>
                            <strong>To:</strong> <%= d.get("deliveryAddress") %>
                        </td>
                        <td>
                            <% 
                                String st = String.valueOf(d.get("status"));
                                String badgeClass = "badge-info";
                                if ("DELIVERED".equals(st)) badgeClass = "badge-success";
                                else if ("IN_TRANSIT".equals(st)) badgeClass = "badge-purple";
                                else if ("OUT_FOR_DELIVERY".equals(st)) badgeClass = "badge-warning";
                            %>
                            <span class="badge <%= badgeClass %>"><%= st %></span><br>
                            <small style="color:#64748b;"><%= d.get("currentLocation") %></small>
                        </td>
                        <td style="min-width: 180px;">
                            <form class="status-form" action="<%= ctx %>/driver/update-status" method="post">
                                <input type="hidden" name="shipmentId" value="<%= d.get("shipmentId") %>">
                                
                                <select name="newStatus" required>
                                    <option value="" disabled selected>-- Next Status --</option>
                                    <option value="PICKED_UP">PICKED_UP</option>
                                    <option value="IN_TRANSIT">IN_TRANSIT</option>
                                    <option value="OUT_FOR_DELIVERY">OUT_FOR_DELIVERY</option>
                                    <option value="DELIVERED">DELIVERED (Complete)</option>
                                </select>
                                
                                <input type="text" name="location" placeholder="Current Location (e.g. Highway Hub)" required maxlength="100">
                                <input type="text" name="remarks" placeholder="Remarks (optional)" maxlength="200">
                                
                                <button type="submit" class="btn-update">Update Status</button>
                            </form>
                        </td>
                    </tr>
                <%  } 
                   } else { %>
                    <tr>
                        <td colspan="6" class="empty-state">
                            No active deliveries pending! You're currently all caught up.
                        </td>
                    </tr>
                <% } %>
            </tbody>
        </table>
    </div>

    <!-- Completed Deliveries History -->
    <h2 class="section-title">Completed Delivery History (<%= completedDeliveries != null ? completedDeliveries.size() : 0 %>)</h2>
    <div class="table-responsive">
        <table>
            <thead>
                <tr>
                    <th>Tracking #</th>
                    <th>Customer</th>
                    <th>Cargo Type</th>
                    <th>Delivery Address</th>
                    <th>Delivered Date</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                <% if (completedDeliveries != null && !completedDeliveries.isEmpty()) { 
                    for (Map<String, Object> c : completedDeliveries) {
                %>
                    <tr>
                        <td><strong><%= c.get("trackingNumber") %></strong></td>
                        <td><%= c.get("customerName") %></td>
                        <td><%= c.get("cargoType") %></td>
                        <td><%= c.get("deliveryAddress") %></td>
                        <td><%= c.get("deliveredDate") != null ? c.get("deliveredDate") : "Recently" %></td>
                        <td><span class="badge badge-success">DELIVERED</span></td>
                    </tr>
                <%  } 
                   } else { %>
                    <tr>
                        <td colspan="6" class="empty-state">No completed delivery history recorded yet.</td>
                    </tr>
                <% } %>
            </tbody>
        </table>
    </div>

    <!-- Customer Reviews & Delivery Ratings -->
    <h2 class="section-title">Customer Delivery Reviews & Ratings (<%= driverReviewCount %>)</h2>
    <div class="table-responsive">
        <table>
            <thead>
                <tr>
                    <th>Tracking #</th>
                    <th>Booking ID</th>
                    <th>Customer</th>
                    <th>Cargo Type</th>
                    <th>Rating</th>
                    <th>Customer Review</th>
                    <th>Date</th>
                </tr>
            </thead>
            <tbody>
                <% if (driverReviews != null && !driverReviews.isEmpty()) { 
                    for (Map<String, Object> rev : driverReviews) {
                        int r = rev.get("rating") != null ? (Integer) rev.get("rating") : 5;
                        if (r < 1) r = 1; if (r > 5) r = 5;
                %>
                    <tr>
                        <td><strong><%= rev.get("trackingNumber") != null ? rev.get("trackingNumber") : "—" %></strong></td>
                        <td>Booking #<%= rev.get("bookingId") %></td>
                        <td><%= rev.get("customerName") != null ? rev.get("customerName") : "Customer" %></td>
                        <td><%= rev.get("cargoType") != null ? rev.get("cargoType") : "Freight" %></td>
                        <td>
                            <strong style="color: #d97706; font-size: 15px;"><%= r %> / 5 Stars</strong>
                        </td>
                        <td style="max-width: 300px; overflow-wrap: anywhere;">
                            <%= rev.get("comments") != null && !String.valueOf(rev.get("comments")).trim().isEmpty() 
                                ? rev.get("comments") 
                                : "<em style='color:#94a3b8;'>No written comments provided.</em>" %>
                        </td>
                        <td><small style="color: #64748b;"><%= rev.get("feedbackDate") != null ? rev.get("feedbackDate") : "—" %></small></td>
                    </tr>
                <%  } 
                   } else { %>
                    <tr>
                        <td colspan="7" class="empty-state">
                            No customer delivery reviews recorded for your completed shipments yet.
                        </td>
                    </tr>
                <% } %>
            </tbody>
        </table>
    </div>

    <!-- Driver Delivery Notes / Incident Reporting Info -->
    <div class="panel" style="margin-top: 20px; background: #f8fafc; border-left: 4px solid #0284c7;">
        <h3 style="font-size: 16px; color: #0d3b66; margin-bottom: 8px;">Driver Incident & Delivery Issue Reporting</h3>
        <p style="font-size: 13px; color: #475569; line-height: 1.5;">
            In the current database architecture, the <code>feedback</code> table is specifically designed to store customer satisfaction ratings (linking customer IDs and unique booking IDs).
            If you need to report delivery incidents, vehicle breakdowns, customer contact issues, or road route challenges, please contact Fleet Dispatch or your Administrator directly. A dedicated <code>driver_feedback</code> schema extension can be configured upon administrative approval.
        </p>
    </div>

</main>

<footer>
    Cargo Transportation Management System • Driver Portal • LBRCE
</footer>

</body>
</html>
