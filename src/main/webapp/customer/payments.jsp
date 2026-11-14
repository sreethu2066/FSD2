<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="com.cargo.controller.PaymentServlet.Payment" %>
<%@ page import="com.cargo.controller.PaymentServlet.PayableBooking" %>

<%
    if (session.getAttribute("userId") == null || !"CUSTOMER".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    if (request.getAttribute("paymentList") == null) {
        response.sendRedirect(request.getContextPath() + "/customer/payments");
        return;
    }

    String ctx = request.getContextPath();
    List<Payment> paymentList = (List<Payment>) request.getAttribute("paymentList");
    List<PayableBooking> payableBookings = (List<PayableBooking>) request.getAttribute("payableBookings");

    if (paymentList == null) paymentList = new ArrayList<>();
    if (payableBookings == null) payableBookings = new ArrayList<>();

    String success = request.getParameter("success");
    String txn = request.getParameter("txn");
    String error = request.getParameter("error");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payments & Invoices | Cargo Transportation System</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        body { background: #f1f5f9; color: #1e293b; padding: 30px 20px; }
        .container { max-width: 1200px; margin: auto; }
        .top-nav { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; }
        .back-link { color: #0284c7; text-decoration: none; font-weight: 600; font-size: 14px; }
        .back-link:hover { text-decoration: underline; }
        h1 { color: #0f172a; font-size: 26px; margin-bottom: 6px; }
        p.subtitle { color: #64748b; font-size: 14px; margin-bottom: 25px; }
        .alert { padding: 14px 18px; border-radius: 8px; margin-bottom: 24px; font-size: 14px; }
        .alert-success { background: #dcfce7; color: #166534; border: 1px solid #bbf7d0; }
        .alert-error { background: #fee2e2; color: #991b1b; border: 1px solid #fecaca; }
        .card { background: white; padding: 25px; border-radius: 12px; border: 1px solid #e2e8f0; box-shadow: 0 4px 15px rgba(0,0,0,0.04); margin-bottom: 30px; }
        .card h2 { font-size: 18px; color: #0f172a; margin-bottom: 16px; border-bottom: 2px solid #f1f5f9; padding-bottom: 10px; }
        .form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 16px; align-items: flex-end; }
        .field { display: flex; flex-direction: column; gap: 6px; }
        .field label { font-size: 13px; font-weight: 600; color: #334155; }
        .field select { padding: 10px 12px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 14px; outline: none; }
        .btn-pay { background: #16a34a; color: white; border: none; padding: 11px 24px; border-radius: 6px; font-weight: 600; cursor: pointer; font-size: 14px; }
        .btn-pay:hover { background: #15803d; }
        .table-wrap { overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; font-size: 14px; }
        th { background: #f8fafc; color: #475569; font-weight: 600; padding: 14px 16px; text-align: left; border-bottom: 1px solid #e2e8f0; }
        td { padding: 14px 16px; border-bottom: 1px solid #f1f5f9; vertical-align: middle; }
        tr:hover { background: #f8fafc; }
        .status-badge { display: inline-block; padding: 4px 10px; border-radius: 12px; font-size: 11px; font-weight: 700; text-transform: uppercase; }
        .badge-success { background: #dcfce7; color: #15803d; }
        .badge-pending { background: #fef3c7; color: #b45309; }
        .badge-failed { background: #fee2e2; color: #b91c1c; }
        .empty { text-align: center; padding: 30px; color: #64748b; font-size: 14px; }
    </style>
</head>
<body>

<div class="container">
    <div class="top-nav">
        <a class="back-link" href="<%= ctx %>/customer/dashboard.jsp">Back to Dashboard</a>
    </div>

    <h1>Customer Payments & Invoices</h1>
    <p class="subtitle">Securely make payments for your cargo bookings and review digital receipts with unique transaction IDs.</p>

    <% if ("payment_successful".equals(success)) { %>
        <div class="alert alert-success">
            Payment completed successfully! Transaction ID: <strong><%= txn %></strong>. Your booking receipt is recorded below.
        </div>
    <% } %>

    <% if (error != null) { %>
        <div class="alert alert-error">Payment error: <%= error %></div>
    <% } %>

    <!-- Make Payment Section -->
    <div class="card">
        <h2>Pay for Confirmed Bookings</h2>
        <% if (!payableBookings.isEmpty()) { %>
            <form method="post" action="<%= ctx %>/customer/payments">
                <div class="form-grid">
                    <div class="field">
                        <label for="bookingId">Select Booking to Pay:</label>
                        <select id="bookingId" name="bookingId" required>
                            <option value="">-- Choose Booking --</option>
                            <% for (PayableBooking pb : payableBookings) { %>
                                <option value="<%= pb.bookingId %>">
                                    Booking #<%= pb.bookingId %> (<%= pb.cargoType %>, ₹<%= pb.amount %>) - <%= pb.pickupCity %> to <%= pb.deliveryCity %>
                                </option>
                            <% } %>
                        </select>
                    </div>

                    <div class="field">
                        <label for="paymentMethod">Payment Method:</label>
                        <select id="paymentMethod" name="paymentMethod" required>
                            <option value="UPI">UPI (Google Pay / PhonePe / Paytm)</option>
                            <option value="CARD">Credit / Debit Card</option>
                            <option value="NET_BANKING">Net Banking</option>
                            <option value="CASH">Cash on Delivery / Pickup</option>
                        </select>
                    </div>

                    <button type="submit" class="btn-pay">Pay &amp; Confirm Receipt</button>
                </div>
            </form>
        <% } else { %>
            <div class="empty">
                All your active bookings are fully paid! When you submit a new booking, it will appear here for checkout.
            </div>
        <% } %>
    </div>

    <!-- Payment History Section -->
    <div class="card">
        <h2>Payment History &amp; Receipts</h2>
        <div class="table-wrap">
            <% if (paymentList.isEmpty()) { %>
                <div class="empty">No payment receipts found yet.</div>
            <% } else { %>
                <table>
                    <thead>
                        <tr>
                            <th>Receipt ID</th>
                            <th>Booking ID</th>
                            <th>Cargo Type</th>
                            <th>Amount</th>
                            <th>Payment Method</th>
                            <th>Transaction ID</th>
                            <th>Payment Date</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                    <% for (Payment p : paymentList) {
                        String st = p.status != null ? p.status : "PENDING";
                        String badgeClass = "badge-pending";
                        if ("SUCCESS".equalsIgnoreCase(st)) badgeClass = "badge-success";
                        else if ("FAILED".equalsIgnoreCase(st)) badgeClass = "badge-failed";
                    %>
                        <tr>
                            <td><strong>#<%= p.id %></strong></td>
                            <td>Booking #<%= p.bookingId %></td>
                            <td><%= p.cargoType != null ? p.cargoType : "General Cargo" %></td>
                            <td><strong style="color:#0f172a;">₹<%= p.amount %></strong></td>
                            <td><span style="font-weight:600; color:#0284c7;"><%= p.method %></span></td>
                            <td><code><%= p.transactionId != null ? p.transactionId : "N/A" %></code></td>
                            <td><%= p.paymentDate != null ? p.paymentDate : "—" %></td>
                            <td><span class="status-badge <%= badgeClass %>"><%= st %></span></td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
            <% } %>
        </div>
    </div>
</div>

</body>
</html>
