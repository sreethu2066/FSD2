
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.List" %>

<%
    String ctx = request.getContextPath();

    Map<String, Object> stats =
        (Map<String, Object>) request.getAttribute("stats");

    List<Map<String, Object>> recentBookings =
        (List<Map<String, Object>>) request.getAttribute("recentBookings");

    List<Map<String, Object>> shipmentStats =
        (List<Map<String, Object>>) request.getAttribute("shipmentStats");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Reports | CTMS</title>

    <style>
        * { box-sizing: border-box; }

        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f1f5f9;
            color: #1e293b;
        }

        header {
            background: #12325b;
            color: white;
            padding: 20px 28px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 12px;
        }

        header a {
            color: white;
            text-decoration: none;
            margin-left: 15px;
        }

        main {
            max-width: 1300px;
            padding: 25px;
            margin: auto;
        }

        .cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
            gap: 16px;
            margin: 20px 0;
        }

        .card, .panel {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 8px #0000000c;
        }

        .card h3 {
            color: #64748b;
            font-size: 14px;
            margin: 0 0 12px;
        }

        .number {
            font-size: 28px;
            font-weight: bold;
            color: #12325b;
            overflow-wrap: anywhere;
        }

        .panel { margin-top: 20px; }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #e2e8f0;
        }

        th { background: #eaf0f8; }

        .table-wrap { overflow-x: auto; }

        @media print {
            header nav, .no-print { display: none; }
            body { background: white; }
            .card, .panel { box-shadow: none; border: 1px solid #ddd; }
        }
    </style>
</head>

<body>

<header>
    <div>
        <h2>Cargo Transportation Management</h2>
        <div>Admin Reports</div>
    </div>

    <nav>
        <a href="<%= ctx %>/admin/dashboard.jsp">Dashboard</a>
        <a href="<%= ctx %>/logout">Logout</a>
    </nav>
</header>

<main>
    <h2>System Overview</h2>

    <div class="no-print">
        <button onclick="window.print()">Print / Save as PDF</button>
    </div>

    <section class="cards">
        <div class="card">
            <h3>Total Bookings</h3>
            <div class="number"><%= stats.get("totalBookings") %></div>
        </div>

        <div class="card">
            <h3>Pending Bookings</h3>
            <div class="number"><%= stats.get("pendingBookings") %></div>
        </div>

        <div class="card">
            <h3>Confirmed Bookings</h3>
            <div class="number"><%= stats.get("confirmedBookings") %></div>
        </div>

        <div class="card">
            <h3>Completed Bookings</h3>
            <div class="number"><%= stats.get("completedBookings") %></div>
        </div>

        <div class="card">
            <h3>Cancelled Bookings</h3>
            <div class="number"><%= stats.get("cancelledBookings") %></div>
        </div>

        <div class="card">
            <h3>Successful Payments</h3>
            <div class="number">
                ₹ <%= stats.get("totalRevenue") == null
                    ? "0.00" : stats.get("totalRevenue") %>
            </div>
        </div>
    </section>

    <section class="panel">
        <h2>Shipment Status Summary</h2>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>Shipment Status</th>
                        <th>Number of Shipments</th>
                    </tr>
                </thead>
                <tbody>
                <% if (shipmentStats != null && !shipmentStats.isEmpty()) {
                    for (Map<String, Object> item : shipmentStats) { %>
                    <tr>
                        <td><%= item.get("status") == null
                            ? "UNKNOWN" : item.get("status") %></td>
                        <td><%= item.get("total") %></td>
                    </tr>
                <%  }
                   } else { %>
                    <tr>
                        <td colspan="2">No shipment records found.</td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </section>

    <section class="panel">
        <h2>Recent Bookings</h2>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>Booking ID</th>
                        <th>Customer ID</th>
                        <th>Booking Date</th>
                        <th>Status</th>
                        <th>Amount (₹)</th>
                    </tr>
                </thead>
                <tbody>
                <% if (recentBookings != null && !recentBookings.isEmpty()) {
                    for (Map<String, Object> booking : recentBookings) { %>
                    <tr>
                        <td>#<%= booking.get("bookingId") %></td>
                        <td><%= booking.get("customerId") %></td>
                        <td><%= booking.get("bookingDate") == null
                            ? "—" : booking.get("bookingDate") %></td>
                        <td><%= booking.get("status") %></td>
                        <td><%= booking.get("amount") == null
                            ? "0.00" : booking.get("amount") %></td>
                    </tr>
                <%  }
                   } else { %>
                    <tr>
                        <td colspan="5">No bookings found.</td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </section>
</main>

</body>
</html>
