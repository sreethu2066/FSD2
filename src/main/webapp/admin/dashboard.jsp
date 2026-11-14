<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="com.cargo.util.DBConnection" %>

<%
    String role = (String) session.getAttribute("role");

    if (role == null || !"ADMIN".equalsIgnoreCase(role) || session.getAttribute("userId") == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    String username = (String) session.getAttribute("username");
    if (username == null || username.trim().isEmpty()) {
        username = "Administrator";
    }

    String ctx = request.getContextPath();

    // Query real-time database statistics
    int totalUsers = 0, totalCustomers = 0, totalDrivers = 0, totalVehicles = 0;
    int totalBookings = 0, pendingBookings = 0, activeShipments = 0;
    BigDecimal totalRevenue = BigDecimal.ZERO;

    try (Connection con = DBConnection.getConnection()) {
        try (Statement st = con.createStatement()) {
            try (ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM users")) {
                if (rs.next()) totalUsers = rs.getInt(1);
            }
            try (ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM customers")) {
                if (rs.next()) totalCustomers = rs.getInt(1);
            }
            try (ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM drivers")) {
                if (rs.next()) totalDrivers = rs.getInt(1);
            }
            try (ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM vehicles")) {
                if (rs.next()) totalVehicles = rs.getInt(1);
            }
            try (ResultSet rs = st.executeQuery("SELECT COUNT(*), COALESCE(SUM(CASE WHEN booking_status='PENDING' THEN 1 ELSE 0 END),0) FROM bookings")) {
                if (rs.next()) {
                    totalBookings = rs.getInt(1);
                    pendingBookings = rs.getInt(2);
                }
            }
            try (ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM shipments WHERE shipment_status NOT IN ('DELIVERED', 'FAILED')")) {
                if (rs.next()) activeShipments = rs.getInt(1);
            }
            try (ResultSet rs = st.executeQuery("SELECT COALESCE(SUM(amount), 0) FROM payments WHERE payment_status = 'SUCCESS'")) {
                if (rs.next()) totalRevenue = rs.getBigDecimal(1);
            }
        }
    } catch (Exception e) {
        System.err.println("Dashboard stats query error: " + e.getMessage());
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Admin Dashboard | Cargo Transportation System</title>

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

.layout {
    display: flex;
    min-height: 100vh;
}

.sidebar {
    width: 260px;
    background: #0f172a;
    color: white;
    padding: 25px 16px;
    flex-shrink: 0;
}

.brand {
    font-size: 20px;
    font-weight: 700;
    margin-bottom: 30px;
    padding: 0 10px;
    display: flex;
    align-items: center;
    gap: 8px;
}

.brand span {
    color: #38bdf8;
}

.nav-title {
    color: #94a3b8;
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    margin: 20px 10px 10px;
    font-weight: 600;
}

.nav-link {
    display: flex;
    align-items: center;
    gap: 10px;
    color: #cbd5e1;
    text-decoration: none;
    padding: 11px 14px;
    border-radius: 8px;
    margin-bottom: 4px;
    font-size: 14px;
    transition: all 0.2s;
}

.nav-link:hover,
.nav-link.active {
    background: #1e293b;
    color: #38bdf8;
    font-weight: 600;
}

.logout {
    margin-top: 25px;
    background: #991b1b;
    color: white !important;
}

.logout:hover {
    background: #b91c1c;
}

.main {
    flex: 1;
    min-width: 0;
}

.topbar {
    background: white;
    padding: 20px 32px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid #e2e8f0;
}

.topbar h1 {
    font-size: 22px;
    color: #0f172a;
}

.admin-user {
    color: #475569;
    font-size: 14px;
    background: #f8fafc;
    padding: 8px 14px;
    border-radius: 20px;
    border: 1px solid #e2e8f0;
}

.content {
    padding: 28px 32px;
}

.welcome-banner {
    background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%);
    color: white;
    padding: 24px 28px;
    border-radius: 12px;
    margin-bottom: 25px;
}

.welcome-banner h2 {
    font-size: 22px;
    margin-bottom: 6px;
}

.welcome-banner p {
    color: #e0f2fe;
    font-size: 14px;
}

/* KPI Statistics Grid */
.kpi-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
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
    letter-spacing: 0.03em;
}

.kpi-value {
    font-size: 28px;
    font-weight: 700;
    color: #0f172a;
    margin-top: 8px;
}

.kpi-subtext {
    font-size: 12px;
    color: #0284c7;
    margin-top: 4px;
}

.section-heading {
    font-size: 18px;
    color: #0f172a;
    margin-bottom: 16px;
    font-weight: 600;
}

.cards {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 20px;
}

.card {
    background: white;
    padding: 22px;
    border-radius: 10px;
    border: 1px solid #e2e8f0;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.04);
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    transition: transform 0.2s, box-shadow 0.2s;
}

.card:hover {
    transform: translateY(-3px);
    box-shadow: 0 6px 16px rgba(0, 0, 0, 0.08);
}

.card-icon {
    font-size: 28px;
    margin-bottom: 12px;
}

.card h3 {
    font-size: 17px;
    color: #0f172a;
    margin-bottom: 8px;
}

.card p {
    color: #64748b;
    font-size: 13px;
    line-height: 1.5;
    margin-bottom: 16px;
    flex-grow: 1;
}

.card-link {
    display: inline-block;
    text-align: center;
    text-decoration: none;
    background: #0284c7;
    color: white;
    padding: 10px 14px;
    border-radius: 6px;
    font-size: 13px;
    font-weight: 600;
    transition: background 0.2s;
}

.card-link:hover {
    background: #0369a1;
}

.footer {
    padding: 20px 32px;
    color: #64748b;
    font-size: 13px;
    border-top: 1px solid #e2e8f0;
    background: white;
    text-align: center;
}

@media (max-width: 1024px) {
    .cards {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }
}

@media (max-width: 768px) {
    .layout {
        flex-direction: column;
    }
    .sidebar {
        width: 100%;
    }
    .cards {
        grid-template-columns: 1fr;
    }
}
</style>
</head>

<body>

<div class="layout">

    <!-- Sidebar -->
    <aside class="sidebar">
        <div class="brand">
            CARGO <span>CTMS</span>
        </div>

        <div class="nav-title">Navigation</div>
        <a class="nav-link active" href="<%= ctx %>/admin/dashboard.jsp">Dashboard</a>
        <a class="nav-link" href="<%= ctx %>/admin/users">User Accounts</a>
        <a class="nav-link" href="<%= ctx %>/admin/customers">Customers</a>
        <a class="nav-link" href="<%= ctx %>/admin/drivers">Drivers</a>
        <a class="nav-link" href="<%= ctx %>/admin/vehicles">Fleet Vehicles</a>
        <a class="nav-link" href="<%= ctx %>/admin/bookings">Bookings</a>
        <a class="nav-link" href="<%= ctx %>/admin/shipments">Shipments</a>
        <a class="nav-link" href="<%= ctx %>/admin/reports">Analytics & Reports</a>
        <a class="nav-link" href="<%= ctx %>/admin/payments">Payments</a>
        <a class="nav-link" href="<%= ctx %>/admin/feedback">Feedback</a>

        <a class="nav-link logout" href="<%= ctx %>/logout">Logout</a>
    </aside>

    <!-- Main Content -->
    <main class="main">
        <header class="topbar">
            <h1>Admin Management Dashboard</h1>
            <div class="admin-user">
                Logged in as: <strong><%= username %></strong>
            </div>
        </header>

        <section class="content">
            <div class="welcome-banner">
                <h2>Cargo Transportation Management System</h2>
                <p>Welcome back, Administrator. Overview of fleet operations, active shipments, and customer bookings.</p>
            </div>

            <!-- Live Database KPI Stats -->
            <h2 class="section-heading">Operational Key Metrics</h2>
            <div class="kpi-grid">
                <div class="kpi-card">
                    <div class="kpi-title">Customers</div>
                    <div class="kpi-value"><%= totalCustomers %></div>
                    <div class="kpi-subtext">Registered clients</div>
                </div>

                <div class="kpi-card">
                    <div class="kpi-title">Drivers</div>
                    <div class="kpi-value"><%= totalDrivers %></div>
                    <div class="kpi-subtext">Active fleet drivers</div>
                </div>

                <div class="kpi-card">
                    <div class="kpi-title">Vehicles</div>
                    <div class="kpi-value"><%= totalVehicles %></div>
                    <div class="kpi-subtext">Fleet vehicles</div>
                </div>

                <div class="kpi-card">
                    <div class="kpi-title">Total Bookings</div>
                    <div class="kpi-value"><%= totalBookings %></div>
                    <div class="kpi-subtext"><%= pendingBookings %> Pending Approval</div>
                </div>

                <div class="kpi-card">
                    <div class="kpi-title">Active Shipments</div>
                    <div class="kpi-value"><%= activeShipments %></div>
                    <div class="kpi-subtext">In-transit deliveries</div>
                </div>

                <div class="kpi-card">
                    <div class="kpi-title">Total Revenue</div>
                    <div class="kpi-value">₹<%= totalRevenue %></div>
                    <div class="kpi-subtext">Confirmed payments</div>
                </div>
            </div>

            <h2 class="section-heading">Management Modules</h2>
            <div class="cards">

                <!-- User Management -->
                <div class="card">
                    <h3>User Accounts</h3>
                    <p>Review system accounts, credentials status, and role assignments.</p>
                    <a class="card-link" href="<%= ctx %>/admin/users">Manage Users</a>
                </div>

                <!-- Customer Management -->
                <div class="card">
                    <h3>Customer Directory</h3>
                    <p>Access registered customer profiles, contact numbers, and delivery addresses.</p>
                    <a class="card-link" href="<%= ctx %>/admin/customers">Manage Customers</a>
                </div>

                <!-- Driver Management -->
                <div class="card">
                    <h3>Driver Management</h3>
                    <p>Register new drivers, view license details, experience, and availability.</p>
                    <a class="card-link" href="<%= ctx %>/admin/drivers">Manage Drivers</a>
                </div>

                <!-- Vehicle Management -->
                <div class="card">
                    <h3>Vehicle Fleet</h3>
                    <p>Maintain fleet vehicles, capacity in KG, assigned drivers, and maintenance status.</p>
                    <a class="card-link" href="<%= ctx %>/admin/vehicles">Manage Vehicles</a>
                </div>

                <!-- Booking Management -->
                <div class="card">
                    <h3>Cargo Bookings</h3>
                    <p>Review incoming customer cargo requests, approve/confirm bookings, or cancel.</p>
                    <a class="card-link" href="<%= ctx %>/admin/bookings">Manage Bookings</a>
                </div>

                <!-- Shipment Management -->
                <div class="card">
                    <h3>Shipment Dispatch</h3>
                    <p>Assign drivers and vehicles to shipments, monitor tracking numbers, and progress.</p>
                    <a class="card-link" href="<%= ctx %>/admin/shipments">Manage Shipments</a>
                </div>

                <!-- Admin Reports -->
                <div class="card">
                    <h3>Reports & Analytics</h3>
                    <p>View detailed breakdown charts, delivery success rates, and revenue reports.</p>
                    <a class="card-link" href="<%= ctx %>/admin/reports">View Reports</a>
                </div>

                <!-- Payment Management -->
                <div class="card">
                    <h3>Payment Records</h3>
                    <p>Inspect customer payments, transaction IDs, payment methods, and statuses.</p>
                    <a class="card-link" href="<%= ctx %>/admin/payments">View Payments</a>
                </div>

                <!-- Feedback Management -->
                <div class="card">
                    <h3>Customer Feedback</h3>
                    <p>Analyze service ratings (1-5 stars) and customer delivery comments.</p>
                    <a class="card-link" href="<%= ctx %>/admin/feedback">View Feedback</a>
                </div>

            </div>
        </section>

        <footer class="footer">
            Cargo Transportation Management System • College FSD-II Project
        </footer>
    </main>

</div>

</body>
</html>
