<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="com.cargo.controller.ShipmentServlet.Shipment" %>
<%@ page import="com.cargo.controller.ShipmentServlet.StatusLog" %>

<%
    if (session.getAttribute("userId") == null || !"CUSTOMER".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    String ctx = request.getContextPath();
    List<Shipment> shipmentList = (List<Shipment>) request.getAttribute("shipmentList");
    if (shipmentList == null) {
        shipmentList = new ArrayList<>();
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Track Shipments | Cargo Transportation System</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        body { background: #f1f5f9; color: #1e293b; padding: 30px 20px; }
        .container { max-width: 1250px; margin: auto; }
        .top-nav { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; }
        .back-link { color: #0284c7; text-decoration: none; font-weight: 600; font-size: 14px; }
        .back-link:hover { text-decoration: underline; }
        h1 { color: #0f172a; font-size: 26px; margin-bottom: 6px; }
        p.subtitle { color: #64748b; font-size: 14px; margin-bottom: 25px; }
        .shipment-card { background: white; border-radius: 12px; border: 1px solid #e2e8f0; box-shadow: 0 4px 15px rgba(0,0,0,0.04); margin-bottom: 25px; overflow: hidden; }
        .shipment-header { background: #f8fafc; padding: 18px 24px; border-bottom: 1px solid #e2e8f0; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; }
        .tracking-title { font-size: 18px; font-weight: 700; color: #0284c7; }
        .shipment-body { padding: 24px; }
        .info-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 18px; margin-bottom: 24px; }
        .info-item { display: flex; flex-direction: column; gap: 4px; }
        .info-label { font-size: 12px; font-weight: 600; color: #64748b; text-transform: uppercase; }
        .info-value { font-size: 14px; font-weight: 600; color: #0f172a; }
        .status-badge { display: inline-block; padding: 5px 14px; border-radius: 20px; font-size: 12px; font-weight: 700; text-transform: uppercase; }
        .badge-pending { background: #fef3c7; color: #b45309; }
        .badge-picked { background: #e0f2fe; color: #0369a1; }
        .badge-transit { background: #f3e8ff; color: #7e22ce; }
        .badge-out { background: #fed7aa; color: #c2410c; }
        .badge-delivered { background: #dcfce7; color: #15803d; }
        .badge-failed { background: #fee2e2; color: #b91c1c; }
        
        /* Timeline styling */
        .timeline-section { border-top: 1px dashed #cbd5e1; padding-top: 18px; }
        .timeline-title { font-size: 14px; font-weight: 700; color: #334155; margin-bottom: 14px; }
        .timeline { list-style: none; position: relative; padding-left: 24px; }
        .timeline:before { content: ''; position: absolute; left: 7px; top: 6px; bottom: 6px; width: 2px; background: #cbd5e1; }
        .timeline-item { position: relative; margin-bottom: 16px; }
        .timeline-item:last-child { margin-bottom: 0; }
        .timeline-dot { position: absolute; left: -24px; top: 3px; width: 14px; height: 14px; border-radius: 50%; background: #0284c7; border: 2px solid white; box-shadow: 0 0 0 2px #0284c7; }
        .timeline-content { background: #f8fafc; padding: 10px 14px; border-radius: 8px; border: 1px solid #e2e8f0; font-size: 13px; }
        .timeline-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px; }
        .timeline-status { font-weight: 700; color: #0f172a; }
        .timeline-date { color: #64748b; font-size: 11px; }
        .empty { background: white; padding: 40px; border-radius: 12px; text-align: center; color: #64748b; border: 1px solid #e2e8f0; }
    </style>
</head>
<body>

<div class="container">
    <div class="top-nav">
        <a class="back-link" href="<%= ctx %>/customer/dashboard.jsp">Back to Dashboard</a>
    </div>

    <h1>Live Shipment Tracking &amp; Delivery Progress</h1>
    <p class="subtitle">Monitor real-time package dispatch, transit checkpoints, assigned fleet driver, and verified delivery confirmation.</p>

    <% if (shipmentList.isEmpty()) { %>
        <div class="empty">
            <h3 style="color:#0f172a; margin-bottom:8px;">No shipments found</h3>
            <p>Once the administrator confirms your bookings and dispatches vehicles, live shipments will appear here.</p>
        </div>
    <% } else { %>
        <% for (Shipment s : shipmentList) { 
            String st = s.status != null ? s.status : "PENDING";
            String badgeClass = "badge-pending";
            if ("PICKED_UP".equals(st)) badgeClass = "badge-picked";
            else if ("IN_TRANSIT".equals(st)) badgeClass = "badge-transit";
            else if ("OUT_FOR_DELIVERY".equals(st)) badgeClass = "badge-out";
            else if ("DELIVERED".equals(st)) badgeClass = "badge-delivered";
            else if ("FAILED".equals(st)) badgeClass = "badge-failed";
        %>
            <div class="shipment-card">
                <div class="shipment-header">
                    <div>
                        <span class="tracking-title">Tracking Number: <%= s.trackingNumber %></span>
                        <span style="color:#64748b; font-size:13px; margin-left:12px;">Shipment #<%= s.id %> (Booking #<%= s.bookingId %>)</span>
                    </div>
                    <div>
                        <span class="status-badge <%= badgeClass %>"><%= st %></span>
                    </div>
                </div>

                <div class="shipment-body">
                    <div class="info-grid">
                        <div class="info-item">
                            <span class="info-label">Current Checkpoint:</span>
                            <span class="info-value"><%= s.location != null ? s.location : "Processing Hub" %></span>
                        </div>
                        <div class="info-item">
                            <span class="info-label">Route:</span>
                            <span class="info-value"><%= s.pickupCity %> to <%= s.deliveryCity %></span>
                        </div>
                        <div class="info-item">
                            <span class="info-label">Cargo Specification:</span>
                            <span class="info-value"><%= s.cargoType %> (<%= s.weightKg %> kg)</span>
                        </div>
                        <div class="info-item">
                            <span class="info-label">Fleet Transport Vehicle:</span>
                            <span class="info-value"><%= s.vehicleNumber != null ? s.vehicleNumber + " (" + s.vehicleType + ")" : "Pending assignment" %></span>
                        </div>
                        <div class="info-item">
                            <span class="info-label">Assigned Driver:</span>
                            <span class="info-value"><%= s.driverName != null ? s.driverName + " (Phone: " + s.driverPhone + ")" : "Pending assignment" %></span>
                        </div>
                        <div class="info-item">
                            <span class="info-label">Dispatched / Delivered:</span>
                            <span class="info-value">
                                <%= s.shippedDate != null ? s.shippedDate : "Awaiting dispatch" %> / 
                                <%= s.deliveredDate != null ? s.deliveredDate : "In transit" %>
                            </span>
                        </div>
                    </div>

                    <!-- Tracking Timeline from shipment_status audit table -->
                    <div class="timeline-section">
                        <div class="timeline-title">Transit Checkpoint History (Audit Log):</div>
                        <% if (s.statusHistory != null && !s.statusHistory.isEmpty()) { %>
                            <ul class="timeline">
                                <% for (StatusLog log : s.statusHistory) { %>
                                    <li class="timeline-item">
                                        <div class="timeline-dot"></div>
                                        <div class="timeline-content">
                                            <div class="timeline-header">
                                                <span class="timeline-status"><%= log.status %> - <%= log.location %></span>
                                                <span class="timeline-date"><%= log.updatedAt %></span>
                                            </div>
                                            <div style="color:#475569;"><%= log.remarks != null ? log.remarks : "Checkpoint logged." %></div>
                                        </div>
                                    </li>
                                <% } %>
                            </ul>
                        <% } else { %>
                            <p style="color:#64748b; font-size:13px;">No checkpoint updates recorded yet.</p>
                        <% } %>
                    </div>
                </div>
            </div>
        <% } %>
    <% } %>
</div>

</body>
</html>
