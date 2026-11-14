<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.cargo.util.DBConnection" %>

<%
    if (session.getAttribute("userId") == null
            || !"CUSTOMER".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    int userId = (Integer) session.getAttribute("userId");
    String username = (String) session.getAttribute("username");
    String ctx = request.getContextPath();

    int myBookings = 0;
    int myShipments = 0;
    int myCargo = 0;
    int myAddresses = 0;

    try (Connection con = DBConnection.getConnection()) {
        int customerId = -1;
        try (PreparedStatement ps = con.prepareStatement("SELECT customer_id FROM customers WHERE user_id = ?")) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) customerId = rs.getInt("customer_id");
            }
        }

        if (customerId != -1) {
            try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM bookings WHERE customer_id = ?")) {
                ps.setInt(1, customerId);
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) myBookings = rs.getInt(1); }
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COUNT(*) FROM shipments s JOIN bookings b ON s.booking_id = b.booking_id WHERE b.customer_id = ? AND s.shipment_status != 'DELIVERED'")) {
                ps.setInt(1, customerId);
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) myShipments = rs.getInt(1); }
            }
            try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM cargo WHERE customer_id = ?")) {
                ps.setInt(1, customerId);
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) myCargo = rs.getInt(1); }
            }
            try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM addresses WHERE customer_id = ?")) {
                ps.setInt(1, customerId);
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) myAddresses = rs.getInt(1); }
            }
        }
    } catch (Exception e) {
        System.err.println("Customer dashboard stats query error: " + e.getMessage());
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Customer Dashboard | Cargo Transportation System</title>

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
            padding: 18px 6%;
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

        .welcome-banner {
            background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%);
            color: white;
            padding: 35px 6%;
        }

        .welcome-banner h1 {
            font-size: 26px;
            margin-bottom: 8px;
        }

        .welcome-banner p {
            color: #e0f2fe;
            font-size: 15px;
        }

        main {
            max-width: 1200px;
            margin: 30px auto;
            padding: 0 20px;
        }

        /* KPI Cards */
        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 18px;
            margin-bottom: 30px;
        }

        .kpi-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            border: 1px solid #e2e8f0;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.04);
        }

        .kpi-title {
            font-size: 13px;
            color: #64748b;
            font-weight: 600;
            text-transform: uppercase;
        }

        .kpi-val {
            font-size: 28px;
            font-weight: 700;
            color: #0f172a;
            margin-top: 6px;
        }

        .section-title {
            font-size: 20px;
            color: #0d3b66;
            margin-bottom: 20px;
            font-weight: 600;
        }

        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 22px;
        }

        .dashboard-card {
            background: white;
            padding: 24px;
            border-radius: 12px;
            border: 1px solid #e2e8f0;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .dashboard-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 8px 20px rgba(0, 0, 0, 0.08);
        }

        .card-icon {
            font-size: 32px;
            margin-bottom: 14px;
        }

        .dashboard-card h3 {
            color: #0d3b66;
            font-size: 18px;
            margin-bottom: 8px;
        }

        .dashboard-card p {
            color: #64748b;
            font-size: 13px;
            line-height: 1.6;
            margin-bottom: 18px;
            flex-grow: 1;
        }

        .card-link {
            display: inline-block;
            text-align: center;
            text-decoration: none;
            color: white;
            background: #0284c7;
            padding: 10px 16px;
            border-radius: 6px;
            font-weight: 600;
            font-size: 14px;
            transition: background 0.2s;
        }

        .card-link:hover {
            background: #0369a1;
        }

        footer {
            margin-top: 50px;
            background: white;
            color: #64748b;
            text-align: center;
            padding: 20px;
            font-size: 13px;
            border-top: 1px solid #e2e8f0;
        }

        @media (max-width: 900px) {
            .dashboard-grid {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }
        }

        @media (max-width: 600px) {
            .dashboard-grid {
                grid-template-columns: 1fr;
            }
            .welcome-banner {
                padding: 24px 5%;
            }
        }
    </style>
</head>

<body>

<header>
    <div class="brand">
        CARGO <span>CTMS</span>
    </div>

    <div class="header-right">
        <span class="user-tag">Welcome, <%= username == null ? "Customer" : username %></span>
        <a class="btn-logout" href="<%= ctx %>/logout">Logout</a>
    </div>
</header>

<section class="welcome-banner">
    <h1>Customer Portal Dashboard</h1>
    <p>Manage your cargo shipments, pickup and delivery addresses, and track real-time deliveries from one central portal.</p>
</section>

<main>
    <!-- Personal Stats Summary -->
    <div class="kpi-grid">
        <div class="kpi-card">
            <div class="kpi-title">My Bookings</div>
            <div class="kpi-val"><%= myBookings %></div>
        </div>
        <div class="kpi-card">
            <div class="kpi-title">In-Transit Shipments</div>
            <div class="kpi-val"><%= myShipments %></div>
        </div>
        <div class="kpi-card">
            <div class="kpi-title">Saved Cargo Items</div>
            <div class="kpi-val"><%= myCargo %></div>
        </div>
        <div class="kpi-card">
            <div class="kpi-title">Saved Addresses</div>
            <div class="kpi-val"><%= myAddresses %></div>
        </div>
    </div>

    <h2 class="section-title">Customer Services</h2>

    <div class="dashboard-grid">

        <!-- My Profile -->
        <div class="dashboard-card">
            <h3>My Profile</h3>
            <p>View and update your personal information, phone number, and account profile.</p>
            <a class="card-link" href="<%= ctx %>/customer/profile">Manage Profile</a>
        </div>

        <!-- My Addresses -->
        <div class="dashboard-card">
            <h3>Address Book</h3>
            <p>Save home, office, and warehouse addresses for quick booking pickup and delivery selection.</p>
            <a class="card-link" href="<%= ctx %>/customer/addresses">Manage Addresses</a>
        </div>

        <!-- Cargo Management -->
        <div class="dashboard-card">
            <h3>Cargo Inventory</h3>
            <p>Register packages, declare weight in KG, specify item quantities, and mark fragile items.</p>
            <a class="card-link" href="<%= ctx %>/customer/cargo">Manage Cargo</a>
        </div>

        <!-- My Bookings -->
        <div class="dashboard-card">
            <h3>Create & View Bookings</h3>
            <p>Create new transportation orders, select routes, view booking history, and cancel eligible requests.</p>
            <a class="card-link" href="<%= ctx %>/customer/bookings">Book Transportation</a>
        </div>

        <!-- My Shipments -->
        <div class="dashboard-card">
            <h3>Track Shipments</h3>
            <p>Track your shipment status in real time, see assigned vehicles, and contact assigned drivers.</p>
            <a class="card-link" href="<%= ctx %>/customer/shipments">Track Shipments</a>
        </div>

        <!-- Payments -->
        <div class="dashboard-card">
            <h3>Payment Records</h3>
            <p>Review payment history, transaction references, invoices, and payment statuses.</p>
            <a class="card-link" href="<%= ctx %>/customer/payments">View Payments</a>
        </div>

        <!-- Feedback -->
        <div class="dashboard-card">
            <h3>Service Feedback</h3>
            <p>Rate completed cargo deliveries (1 to 5 stars) and submit comments on driver service quality.</p>
            <a class="card-link" href="<%= ctx %>/customer/feedback">Submit Feedback</a>
        </div>

    </div>
</main>

<footer>
    Cargo Transportation Management System • College FSD-II Project • LBRCE
</footer>

</body>
</html>
