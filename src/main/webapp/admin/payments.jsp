<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="com.cargo.model.Payment" %>

<%
    if (session.getAttribute("userId") == null
            || !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    if (request.getAttribute("payments") == null) {
        response.sendRedirect(request.getContextPath() + "/admin/payments");
        return;
    }

    List<Payment> payments = (List<Payment>) request.getAttribute("payments");
    String selectedStatus = (String) request.getAttribute("selectedStatus");
    String searchTerm = (String) request.getAttribute("searchTerm");
    String ctx = request.getContextPath();

    BigDecimal totalSuccessAmount = BigDecimal.ZERO;
    int successCount = 0;
    int pendingCount = 0;

    if (payments != null) {
        for (Payment p : payments) {
            if ("SUCCESS".equalsIgnoreCase(p.getPaymentStatus())) {
                successCount++;
                if (p.getAmount() != null) {
                    totalSuccessAmount = totalSuccessAmount.add(p.getAmount());
                }
            } else if ("PENDING".equalsIgnoreCase(p.getPaymentStatus())) {
                pendingCount++;
            }
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Records | Cargo Transportation System</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
    <style>
        .top-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 24px;
            flex-wrap: wrap;
            gap: 12px;
        }

        .back-link {
            color: #0284c7;
            text-decoration: none;
            font-weight: 600;
            font-size: 14px;
        }

        .back-link:hover {
            text-decoration: underline;
        }

        /* Filter & Search Bar */
        .filter-card {
            background: white;
            padding: 18px 24px;
            border-radius: 10px;
            border: 1px solid #e2e8f0;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.04);
            margin-bottom: 24px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 15px;
        }

        .filter-form {
            display: flex;
            align-items: center;
            gap: 12px;
            flex-wrap: wrap;
            flex: 1;
        }

        .filter-form input[type="text"] {
            max-width: 280px;
            padding: 9px 12px;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            font-size: 13px;
        }

        .filter-form select {
            max-width: 180px;
            padding: 9px 12px;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            font-size: 13px;
        }

        /* Summary Stats Cards */
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 16px;
            margin-bottom: 25px;
        }

        .summary-card {
            background: white;
            padding: 18px 20px;
            border-radius: 10px;
            border: 1px solid #e2e8f0;
            box-shadow: 0 2px 6px rgba(0,0,0,0.04);
        }

        .summary-label {
            font-size: 12px;
            color: #64748b;
            text-transform: uppercase;
            font-weight: 600;
        }

        .summary-val {
            font-size: 24px;
            font-weight: 700;
            color: #0f172a;
            margin-top: 4px;
        }

        .status-badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
        }

        .badge-success { background: #dcfce7; color: #15803d; }
        .badge-pending { background: #fef3c7; color: #b45309; }
        .badge-failed { background: #fee2e2; color: #b91c1c; }
        .badge-refunded { background: #f1f5f9; color: #475569; }

        .method-badge {
            display: inline-block;
            background: #e0f2fe;
            color: #0369a1;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 600;
        }

        .update-form {
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .update-form select {
            padding: 5px 8px;
            font-size: 12px;
            border: 1px solid #cbd5e1;
            border-radius: 4px;
        }

        .btn-mini {
            padding: 5px 10px;
            font-size: 11px;
            border-radius: 4px;
            border: none;
            background: #0284c7;
            color: white;
            cursor: pointer;
            font-weight: 600;
        }

        .btn-mini:hover {
            background: #0369a1;
        }
    </style>
</head>
<body>

<header class="app-header">
    <div class="brand">
        CARGO <span>CTMS</span> | Admin Management
    </div>
    <div>
        <a class="btn btn-secondary" href="<%= ctx %>/admin/dashboard.jsp">Dashboard</a>
        <a class="btn btn-danger" href="<%= ctx %>/logout" style="margin-left: 8px;">Logout</a>
    </div>
</header>

<div class="container">

    <div class="top-bar">
        <div>
            <a class="back-link" href="<%= ctx %>/admin/dashboard.jsp">Back to Admin Dashboard</a>
            <h1 style="margin-top: 8px;">Payment Management</h1>
            <p class="subtitle">Review customer payments, track transaction IDs, and verify settlement statuses.</p>
        </div>
    </div>

    <% 
        String success = request.getParameter("success");
        String error = request.getParameter("error");
        if ("updated".equals(success)) {
    %>
        <div class="alert alert-success">Payment status updated successfully.</div>
    <% } else if ("deleted".equals(success)) { %>
        <div class="alert alert-success">Payment record removed.</div>
    <% } else if (error != null) { %>
        <div class="alert alert-error">Operation failed: <%= error %></div>
    <% } %>

    <!-- Summary KPI Cards -->
    <div class="summary-grid">
        <div class="summary-card">
            <div class="summary-label">Total Revenue Collected</div>
            <div class="summary-val" style="color: #16a34a;">₹<%= totalSuccessAmount %></div>
        </div>
        <div class="summary-card">
            <div class="summary-label">Successful Payments</div>
            <div class="summary-val"><%= successCount %></div>
        </div>
        <div class="summary-card">
            <div class="summary-label">Pending Verifications</div>
            <div class="summary-val" style="color: #d97706;"><%= pendingCount %></div>
        </div>
        <div class="summary-card">
            <div class="summary-label">Total Payment Records</div>
            <div class="summary-val"><%= payments != null ? payments.size() : 0 %></div>
        </div>
    </div>

    <!-- Search & Filter Controls -->
    <div class="filter-card">
        <form class="filter-form" action="<%= ctx %>/admin/payments" method="get">
            <input type="text" name="q" placeholder="Search Transaction ID / Booking ID / Name..." 
                   value="<%= searchTerm != null ? searchTerm : "" %>">

            <select name="status">
                <option value="ALL">All Statuses</option>
                <option value="SUCCESS" <%= "SUCCESS".equalsIgnoreCase(selectedStatus) ? "selected" : "" %>>SUCCESS</option>
                <option value="PENDING" <%= "PENDING".equalsIgnoreCase(selectedStatus) ? "selected" : "" %>>PENDING</option>
                <option value="FAILED" <%= "FAILED".equalsIgnoreCase(selectedStatus) ? "selected" : "" %>>FAILED</option>
                <option value="REFUNDED" <%= "REFUNDED".equalsIgnoreCase(selectedStatus) ? "selected" : "" %>>REFUNDED</option>
            </select>

            <button type="submit" class="btn btn-primary" style="padding: 9px 16px; font-size: 13px;">Filter</button>
            <a href="<%= ctx %>/admin/payments" class="btn btn-secondary" style="padding: 9px 14px; font-size: 13px;">Reset</a>
        </form>
    </div>

    <!-- Payments Table -->
    <div class="table-responsive">
        <table>
            <thead>
                <tr>
                    <th>Payment ID</th>
                    <th>Booking ID</th>
                    <th>Customer & Cargo</th>
                    <th>Amount</th>
                    <th>Method</th>
                    <th>Transaction Reference</th>
                    <th>Date</th>
                    <th>Status</th>
                    <th>Update Status</th>
                </tr>
            </thead>
            <tbody>
                <% if (payments != null && !payments.isEmpty()) { 
                    for (Payment p : payments) {
                        String st = p.getPaymentStatus() != null ? p.getPaymentStatus() : "PENDING";
                        String badgeClass = "badge-pending";
                        if ("SUCCESS".equalsIgnoreCase(st)) badgeClass = "badge-success";
                        else if ("FAILED".equalsIgnoreCase(st)) badgeClass = "badge-failed";
                        else if ("REFUNDED".equalsIgnoreCase(st)) badgeClass = "badge-refunded";
                %>
                    <tr>
                        <td><strong>#<%= p.getPaymentId() %></strong></td>
                        <td>
                            <a href="<%= ctx %>/admin/bookings" style="color: #0284c7; font-weight: 600; text-decoration: none;">
                                Booking #<%= p.getBookingId() %>
                            </a>
                        </td>
                        <td>
                            <strong><%= p.getCustomerName() != null ? p.getCustomerName() : "Client" %></strong><br>
                            <small style="color: #64748b;">
                                <%= p.getCargoType() != null ? p.getCargoType() : "Freight Cargo" %> 
                                <%= p.getCustomerPhone() != null ? "• Phone: " + p.getCustomerPhone() : "" %>
                            </small>
                        </td>
                        <td>
                            <strong style="font-size: 15px; color: #0f172a;">
                                ₹<%= p.getAmount() != null ? p.getAmount() : "0.00" %>
                            </strong>
                        </td>
                        <td>
                            <span class="method-badge"><%= p.getPaymentMethod() != null ? p.getPaymentMethod() : "CASH" %></span>
                        </td>
                        <td>
                            <code><%= p.getTransactionId() != null ? p.getTransactionId() : "—" %></code>
                        </td>
                        <td>
                            <small style="color: #475569;">
                                <%= p.getPaymentDate() != null ? p.getPaymentDate() : "—" %>
                            </small>
                        </td>
                        <td>
                            <span class="status-badge <%= badgeClass %>"><%= st %></span>
                        </td>
                        <td>
                            <form class="update-form" action="<%= ctx %>/admin/payments" method="post" 
                                  onsubmit="return confirm('Update status for Payment #<%= p.getPaymentId() %>?');">
                                <input type="hidden" name="action" value="updateStatus">
                                <input type="hidden" name="paymentId" value="<%= p.getPaymentId() %>">
                                
                                <select name="status">
                                    <option value="SUCCESS" <%= "SUCCESS".equalsIgnoreCase(st) ? "selected" : "" %>>SUCCESS</option>
                                    <option value="PENDING" <%= "PENDING".equalsIgnoreCase(st) ? "selected" : "" %>>PENDING</option>
                                    <option value="FAILED" <%= "FAILED".equalsIgnoreCase(st) ? "selected" : "" %>>FAILED</option>
                                    <option value="REFUNDED" <%= "REFUNDED".equalsIgnoreCase(st) ? "selected" : "" %>>REFUNDED</option>
                                </select>
                                <button type="submit" class="btn-mini">Save</button>
                            </form>
                        </td>
                    </tr>
                <%  } 
                   } else { %>
                    <tr>
                        <td colspan="9" style="text-align: center; padding: 40px; color: #64748b;">
                            <h3 style="color: #0f172a; margin-bottom: 6px;">No Payment Records Found</h3>
                            <p style="font-size: 13px;">No payments matching your search criteria were found in the system database.</p>
                        </td>
                    </tr>
                <% } %>
            </tbody>
        </table>
    </div>

</div>

<footer class="app-footer">
    Cargo Transportation Management System • Admin Payment Management • LBRCE
</footer>

</body>
</html>
