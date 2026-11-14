<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    if (session.getAttribute("userId") == null || !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    Object vehicleId = request.getAttribute("vehicleId");
    boolean editing = (vehicleId != null);
    String selectedStatus = editing ? String.valueOf(request.getAttribute("status")) : "AVAILABLE";
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= editing ? "Edit Vehicle" : "Add Vehicle" %> | CTMS Admin</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        body { background: #f1f5f9; color: #1e293b; padding: 40px 20px; }
        .box { max-width: 520px; margin: auto; background: white; padding: 32px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,.05); border: 1px solid #e2e8f0; }
        h2 { font-size: 22px; color: #0f172a; margin-bottom: 20px; }
        label { display: block; margin-top: 16px; font-weight: 600; font-size: 14px; color: #334155; }
        input, select { width: 100%; padding: 11px 14px; margin-top: 6px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 14px; outline: none; }
        input:focus, select:focus { border-color: #0284c7; box-shadow: 0 0 0 3px rgba(2,132,199,.15); }
        .btn-group { display: flex; gap: 12px; margin-top: 26px; }
        .btn { padding: 11px 20px; border-radius: 6px; font-weight: 600; text-decoration: none; cursor: pointer; border: none; font-size: 14px; text-align: center; }
        .btn-primary { background: #0284c7; color: white; flex: 1; }
        .btn-primary:hover { background: #0369a1; }
        .btn-secondary { background: #f1f5f9; color: #475569; border: 1px solid #cbd5e1; }
        .btn-secondary:hover { background: #e2e8f0; }
        .hint { font-size: 12px; color: #64748b; margin-top: 4px; }
    </style>
</head>
<body>

<div class="box">
    <h2><%= editing ? "Edit Vehicle" : "Register New Fleet Vehicle" %></h2>

    <form method="post" action="<%= ctx %>/admin/vehicles">
        <input type="hidden" name="action" value="<%= editing ? "update" : "add" %>">
        <% if (editing) { %>
            <input type="hidden" name="vehicleId" value="<%= vehicleId %>">
        <% } %>

        <label for="vehicleNumber">Vehicle Registration Number *</label>
        <input type="text" id="vehicleNumber" name="vehicleNumber" maxlength="30" placeholder="e.g. MH-12-AB-1234" required
               value="<%= editing ? request.getAttribute("vehicleNumber") : "" %>">
        <div class="hint">Unique state transport registration license plate number.</div>

        <label for="vehicleType">Vehicle Type / Category *</label>
        <input type="text" id="vehicleType" name="vehicleType" maxlength="60" placeholder="e.g. Mini Truck, Cargo Van, Heavy Lorry" required
               value="<%= editing ? request.getAttribute("vehicleType") : "" %>">

        <label for="capacity">Load Capacity (kg) *</label>
        <input type="number" id="capacity" name="capacity" min="0.01" step="0.01" placeholder="e.g. 1500.00" required
               value="<%= editing ? request.getAttribute("capacity") : "" %>">
        <div class="hint">Maximum weight this vehicle can transport. Used to validate shipment cargo limits.</div>

        <label for="status">Vehicle Status *</label>
        <select id="status" name="status" required>
            <option value="AVAILABLE" <%= "AVAILABLE".equals(selectedStatus) ? "selected" : "" %>>AVAILABLE (Ready for dispatch)</option>
            <option value="ASSIGNED" <%= "ASSIGNED".equals(selectedStatus) ? "selected" : "" %>>ASSIGNED (Currently dispatched)</option>
            <option value="MAINTENANCE" <%= "MAINTENANCE".equals(selectedStatus) ? "selected" : "" %>>MAINTENANCE (Out of service)</option>
        </select>

        <div class="btn-group">
            <button class="btn btn-primary" type="submit"><%= editing ? "Update Vehicle" : "Save Vehicle" %></button>
            <a class="btn btn-secondary" href="<%= ctx %>/admin/vehicles">Cancel</a>
        </div>
    </form>
</div>

</body>
</html>
