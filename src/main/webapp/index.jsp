<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cargo Transportation Management System | Home</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .hero {
            background: linear-gradient(135deg, #0d3b66 0%, #001e3d 100%);
            color: white;
            text-align: center;
            padding: 80px 20px 60px;
        }

        .hero h1 {
            font-size: 38px;
            color: #ffffff;
            margin-bottom: 16px;
            font-weight: 800;
        }

        .hero p {
            font-size: 18px;
            color: #e0f2fe;
            max-width: 700px;
            margin: 0 auto 30px;
            line-height: 1.6;
        }

        .hero-buttons {
            display: flex;
            justify-content: center;
            gap: 16px;
            flex-wrap: wrap;
        }

        .btn-large {
            padding: 14px 28px;
            font-size: 16px;
            border-radius: 8px;
            font-weight: 600;
            text-decoration: none;
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .btn-large:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 16px rgba(0,0,0,0.2);
        }

        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 25px;
            margin: 50px 0;
        }

        .feature-card {
            background: white;
            padding: 30px 24px;
            border-radius: 12px;
            border: 1px solid #e2e8f0;
            box-shadow: 0 4px 12px rgba(0,0,0,0.05);
            text-align: center;
        }

        .feature-icon {
            font-size: 40px;
            margin-bottom: 16px;
        }

        .feature-card h3 {
            font-size: 20px;
            margin-bottom: 12px;
            color: #0d3b66;
        }

        .feature-card p {
            color: #64748b;
            font-size: 14px;
            line-height: 1.6;
        }

        .role-section {
            background: #ffffff;
            border-radius: 12px;
            border: 1px solid #e2e8f0;
            padding: 35px;
            margin: 40px 0;
        }

        .role-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }

        .role-box {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 20px;
            text-align: center;
        }

        .role-box h4 {
            color: #0284c7;
            font-size: 16px;
            margin-bottom: 8px;
        }
    </style>
</head>
<body>

<header class="app-header">
    <div class="brand">
        CARGO <span>CTMS</span>
    </div>
    <div>
        <a class="btn btn-primary" href="${pageContext.request.contextPath}/login.jsp">Sign In</a>
        <a class="btn btn-secondary" href="${pageContext.request.contextPath}/register.jsp" style="margin-left: 8px;">Register</a>
    </div>
</header>

<section class="hero">
    <h1>Cargo Transportation Management System</h1>
    <p>A Full-Stack web application providing cargo booking, real-time shipment dispatch, vehicle fleet tracking, and role-based delivery management.</p>
    <div class="hero-buttons">
        <a class="btn btn-primary btn-large" href="${pageContext.request.contextPath}/login.jsp">Access Portal</a>
        <a class="btn btn-secondary btn-large" href="${pageContext.request.contextPath}/register.jsp">New Customer Sign Up</a>
    </div>
</section>

<div class="container">

    <div class="features-grid">
        <div class="feature-card">
            <h3>Cargo Booking</h3>
            <p>Customers can register cargo with weight in KG, pickup and delivery addresses, and track quotation amounts.</p>
        </div>

        <div class="feature-card">
            <h3>Dispatch & Tracking</h3>
            <p>Admins review bookings, assign available drivers and fleet vehicles, and generate real-time tracking numbers.</p>
        </div>

        <div class="feature-card">
            <h3>Driver Portal</h3>
            <p>Drivers log in to view assigned routes, inspect vehicle specifications, and log live delivery milestone updates.</p>
        </div>
    </div>

    <div class="role-section">
        <h2 style="text-align: center; margin-bottom: 6px;">Supported User Roles & Demo Credentials</h2>
        <p style="text-align: center; color: #64748b; font-size: 14px;">Every role is strictly authorized via server-side filters.</p>

        <div class="role-grid">
            <div class="role-box">
                <h4>Customer</h4>
                <p style="font-size: 13px; color: #475569; margin-bottom: 12px;">Create cargo bookings, manage addresses, track shipments, and give feedback.</p>
                <div style="font-size: 12px; color: #64748b;">User: <code>customer_test</code><br>Pass: <code>12345678</code></div>
            </div>

            <div class="role-box">
                <h4>Driver</h4>
                <p style="font-size: 13px; color: #475569; margin-bottom: 12px;">View assigned shipments, vehicle specifications, and update delivery status.</p>
                <div style="font-size: 12px; color: #64748b;">User: <code>driver_test</code><br>Pass: <code>12345678</code></div>
            </div>

            <div class="role-box">
                <h4>Administrator</h4>
                <p style="font-size: 13px; color: #475569; margin-bottom: 12px;">Manage fleet, approve bookings, assign drivers, view revenue & feedback reports.</p>
                <div style="font-size: 12px; color: #64748b;">User: <code>admin_test</code><br>Pass: <code>12345678</code></div>
            </div>
        </div>
    </div>

</div>

<footer class="app-footer">
    <strong>Cargo Transportation Management System</strong> • College FSD-II Project • LBRCE, Mylavaram
</footer>

</body>
</html>