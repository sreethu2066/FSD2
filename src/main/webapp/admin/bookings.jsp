<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="java.util.List"%>
<%@ page import="com.cargo.controller.AdminBookingServlet.Booking"%>
<%
if (session.getAttribute("userId") == null || !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
	response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
	return;
}

String ctx = request.getContextPath();
List<Booking> bookings = (List<Booking>) request.getAttribute("bookings");
String message = request.getParameter("message");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Customer Bookings Management | CTMS Admin</title>
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

.navbar {
	background: #0f172a;
	color: white;
	padding: 18px 6%;
	display: flex;
	justify-content: space-between;
	align-items: center;
}

.navbar h2 {
	font-size: 20px;
	font-weight: 700;
	color: #38bdf8;
}

.nav-links a {
	color: #cbd5e1;
	text-decoration: none;
	margin-left: 18px;
	font-weight: 500;
	font-size: 14px;
}

.nav-links a:hover {
	color: white;
}

.container {
	max-width: 1400px;
	margin: 30px auto;
	padding: 0 20px;
}

.header-title {
	margin-bottom: 24px;
}

.header-title h1 {
	font-size: 24px;
	color: #0f172a;
}

.header-title p {
	color: #64748b;
	font-size: 14px;
	margin-top: 4px;
}

.alert {
	padding: 14px 18px;
	border-radius: 8px;
	margin-bottom: 20px;
	font-size: 14px;
}

.alert-success {
	background: #dcfce7;
	color: #166534;
	border: 1px solid #bbf7d0;
}

.alert-info {
	background: #e0f2fe;
	color: #0369a1;
	border: 1px solid #bae6fd;
}

.table-wrap {
	background: white;
	border-radius: 12px;
	overflow-x: auto;
	box-shadow: 0 4px 15px rgba(0, 0, 0, .04);
	border: 1px solid #e2e8f0;
}

table {
	width: 100%;
	border-collapse: collapse;
	text-align: left;
	font-size: 13px;
}

th {
	background: #f8fafc;
	color: #475569;
	font-weight: 600;
	padding: 14px 12px;
	border-bottom: 1px solid #e2e8f0;
}

td {
	padding: 14px 12px;
	border-bottom: 1px solid #f1f5f9;
	vertical-align: middle;
}

tr:hover {
	background: #f8fafc;
}

.status-badge {
	display: inline-block;
	padding: 4px 10px;
	border-radius: 12px;
	font-size: 11px;
	font-weight: 700;
	text-transform: uppercase;
}

.badge-pending {
	background: #fef3c7;
	color: #b45309;
}

.badge-confirmed {
	background: #e0f2fe;
	color: #0369a1;
}

.badge-completed {
	background: #dcfce7;
	color: #15803d;
}

.badge-cancelled {
	background: #fee2e2;
	color: #b91c1c;
}

.btn-confirm {
	background: #16a34a;
	color: white;
	border: none;
	padding: 7px 12px;
	border-radius: 6px;
	cursor: pointer;
	font-weight: 600;
	font-size: 12px;
	margin-right: 4px;
}

.btn-confirm:hover {
	background: #15803d;
}

.btn-cancel {
	background: #dc2626;
	color: white;
	border: none;
	padding: 7px 12px;
	border-radius: 6px;
	cursor: pointer;
	font-weight: 600;
	font-size: 12px;
}

.btn-cancel:hover {
	background: #b91c1c;
}
</style>
</head>
<body>

	<div class="navbar">
		<h2>CTMS Admin Bookings</h2>
		<div class="nav-links">
			<a href="<%=ctx%>/admin/dashboard.jsp">Dashboard</a> <a
				href="<%=ctx%>/admin/bookings"
				style="color: white; font-weight: bold;">Bookings</a> <a
				href="<%=ctx%>/admin/shipments">Shipments</a> <a
				href="<%=ctx%>/admin/drivers">Drivers</a> <a
				href="<%=ctx%>/admin/vehicles">Vehicles</a> <a
				href="<%=ctx%>/admin/payments">Payments</a> <a
				href="<%=ctx%>/admin/feedback">Feedback</a> <a
				href="<%=ctx%>/logout">Logout</a>
		</div>
	</div>

	<div class="container">
		<div class="header-title">
			<h1>Customer Bookings Management</h1>
			<p>Review customer booking requests, confirm shipments
				(automatically creates shipment tracking record), or cancel pending
				requests.</p>
		</div>

		<%
		if ("updated".equals(message)) {
		%>
		<div class="alert alert-success">Booking status updated
			successfully. Shipment has been created.</div>
		<%
		} else if ("unchanged".equals(message)) {
		%>
		<div class="alert alert-info">Booking was not modified because
			it is no longer pending.</div>
		<%
		}
		%>

		<div class="table-wrap">
			<table>
				<thead>
					<tr>
						<th>Booking ID</th>
						<th>Customer Name &amp; Contact</th>
						<th>Cargo Type &amp; Weight</th>
						<th>Pickup &amp; Delivery Route</th>
						<th>Scheduled Dates</th>
						<th>Total Amount</th>
						<th>Status</th>
						<th>Action</th>
					</tr>
				</thead>
				<tbody>
					<%
					if (bookings != null && !bookings.isEmpty()) {
						for (Booking b : bookings) {
							String st = b.status != null ? b.status : "PENDING";
							String badgeClass = "badge-pending";
							if ("CONFIRMED".equals(st))
						badgeClass = "badge-confirmed";
							else if ("COMPLETED".equals(st))
						badgeClass = "badge-completed";
							else if ("CANCELLED".equals(st))
						badgeClass = "badge-cancelled";
					%>
					<tr>
						<td><strong>#<%=b.id%></strong></td>
						<td><strong><%=b.customerName != null ? b.customerName : "Customer #" + b.customerId%></strong><br>
							<small style="color: #64748b;">Phone: <%=b.customerPhone != null ? b.customerPhone : "N/A"%></small>
						</td>
						<td><strong><%=b.cargoType%></strong><br> <small
							style="color: #0284c7;">Weight: <%=b.weightKg%> kg
						</small></td>
						<td><%=b.pickupCity != null ? b.pickupCity : "Origin"%> to
							<%=b.deliveryCity != null ? b.deliveryCity : "Destination"%></td>
						<td><small>Pickup: <strong><%=b.pickupDate != null ? b.pickupDate : "—"%></strong><br>
								Delivery: <strong><%=b.expectedDate != null ? b.expectedDate : "—"%></strong></small>
						</td>
						<td><strong style="color: #0f172a;">₹<%=b.amount%></strong></td>
						<td><span class="status-badge <%=badgeClass%>"><%=st%></span></td>
						<td>
							<%
							if ("PENDING".equals(st)) {
							%>
							<form method="post" action="<%=ctx%>/admin/bookings"
								style="display: inline">
								<input type="hidden" name="bookingId" value="<%=b.id%>">
								<input type="hidden" name="action" value="confirm">
								<button type="submit" class="btn-confirm">Confirm</button>
							</form>
							<form method="post" action="<%=ctx%>/admin/bookings"
								style="display: inline"
								onsubmit="return confirm('Cancel this booking?');">
								<input type="hidden" name="bookingId" value="<%=b.id%>">
								<input type="hidden" name="action" value="cancel">
								<button type="submit" class="btn-cancel">Cancel</button>
							</form> <%
 } else if ("CONFIRMED".equals(st)) {
 %> <a
							href="<%=ctx%>/admin/shipments"
							style="color: #0284c7; font-weight: 600; text-decoration: none;">Go
								to Dispatch</a> <%
 } else {
 %> <span style="color: #94a3b8;">—</span>
							<%
							}
							%>
						</td>
					</tr>
					<%
					}
					} else {
					%>
					<tr>
						<td colspan="8"
							style="text-align: center; padding: 35px; color: #64748b;">No
							bookings created by customers yet.</td>
					</tr>
					<%
					}
					%>
				</tbody>
			</table>
		</div>
	</div>

</body>
</html>
