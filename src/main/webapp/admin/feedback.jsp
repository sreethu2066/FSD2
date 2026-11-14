<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="com.cargo.model.Feedback" %>

<%
    String role = (String) session.getAttribute("role");
    if (session.getAttribute("userId") == null || !"ADMIN".equalsIgnoreCase(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    if (request.getAttribute("feedbackList") == null) {
        response.sendRedirect(request.getContextPath() + "/admin/feedback");
        return;
    }

    List<Feedback> feedbackList = (List<Feedback>) request.getAttribute("feedbackList");
    int totalCount = (Integer) request.getAttribute("totalCount");
    double avgRating = (Double) request.getAttribute("avgRating");
    int fiveStarCount = (Integer) request.getAttribute("fiveStarCount");
    int lowRatingCount = (Integer) request.getAttribute("lowRatingCount");
    String selectedRating = (String) request.getAttribute("selectedRating");
    String searchTerm = (String) request.getAttribute("searchTerm");
    String ctx = request.getContextPath();
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Customer Feedback Management | Cargo Transportation System</title>
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
            max-width: 320px;
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

        .stars-gold {
            color: #d97706;
            font-size: 15px;
            letter-spacing: 1px;
        }

        .comment-text {
            max-width: 340px;
            overflow-wrap: anywhere;
            white-space: pre-wrap;
            font-size: 13px;
            color: #334155;
            line-height: 1.4;
        }

        .btn-delete {
            background: #dc2626;
            color: white;
            border: none;
            padding: 6px 12px;
            border-radius: 5px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.2s;
        }

        .btn-delete:hover {
            background: #b91c1c;
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
            <h1 style="margin-top: 8px;">Customer Feedback & Reviews</h1>
            <p class="subtitle">Monitor delivery ratings, inspect customer feedback, and analyze service satisfaction.</p>
        </div>
    </div>

    <% 
        String success = request.getParameter("success");
        String error = request.getParameter("error");
        if ("deleted".equals(success)) {
    %>
        <div class="alert alert-success">Feedback record successfully removed.</div>
    <% } else if (error != null) { %>
        <div class="alert alert-error">Operation failed: <%= error %></div>
    <% } %>

    <!-- KPI Summary Grid -->
    <div class="summary-grid">
        <div class="summary-card">
            <div class="summary-label">Total Feedback Received</div>
            <div class="summary-val"><%= totalCount %></div>
        </div>
        <div class="summary-card">
            <div class="summary-label">Average Customer Rating</div>
            <div class="summary-val" style="color: #d97706;">
                <%= avgRating %> <span style="font-size: 14px; color: #64748b; font-weight: normal;">/ 5.0</span>
            </div>
        </div>
        <div class="summary-card">
            <div class="summary-label">5-Star Top Ratings</div>
            <div class="summary-val" style="color: #16a34a;"><%= fiveStarCount %></div>
        </div>
        <div class="summary-card">
            <div class="summary-label">Critical Ratings (Rating &le; 2)</div>
            <div class="summary-val" style="color: <%= lowRatingCount > 0 ? "#dc2626" : "#64748b" %>;"><%= lowRatingCount %></div>
        </div>
    </div>

    <!-- Search & Filter Controls -->
    <div class="filter-card">
        <form class="filter-form" action="<%= ctx %>/admin/feedback" method="get">
            <input type="text" name="q" placeholder="Search Customer Name / Username / Booking ID / Comment..." 
                   value="<%= searchTerm != null ? searchTerm : "" %>">

            <select name="rating">
                <option value="ALL">All Star Ratings</option>
                <option value="5" <%= "5".equals(selectedRating) ? "selected" : "" %>>5 Stars</option>
                <option value="4" <%= "4".equals(selectedRating) ? "selected" : "" %>>4 Stars</option>
                <option value="3" <%= "3".equals(selectedRating) ? "selected" : "" %>>3 Stars</option>
                <option value="2" <%= "2".equals(selectedRating) ? "selected" : "" %>>2 Stars</option>
                <option value="1" <%= "1".equals(selectedRating) ? "selected" : "" %>>1 Star</option>
            </select>

            <button type="submit" class="btn btn-primary" style="padding: 9px 16px; font-size: 13px;">Filter</button>
            <a href="<%= ctx %>/admin/feedback" class="btn btn-secondary" style="padding: 9px 14px; font-size: 13px;">Reset</a>
        </form>
    </div>

    <!-- Feedback Table -->
    <div class="table-responsive">
        <table>
            <thead>
                <tr>
                    <th>Feedback ID</th>
                    <th>Customer Details</th>
                    <th>Booking & Shipment</th>
                    <th>Rating</th>
                    <th>Customer Comments</th>
                    <th>Date & Time</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
                <% if (feedbackList != null && !feedbackList.isEmpty()) { 
                    for (Feedback f : feedbackList) {
                        int r = f.getRating();
                        if (r < 1) r = 1;
                        if (r > 5) r = 5;
                %>
                    <tr>
                        <td><strong>#<%= f.getFeedbackId() %></strong></td>
                        <td>
                            <strong><%= f.getCustomerName() != null ? f.getCustomerName() : "Customer" %></strong><br>
                            <small style="color: #64748b;">
                                <%= f.getCustomerUsername() != null ? f.getCustomerUsername() : "" %> 
                                <%= f.getCustomerPhone() != null ? "• Phone: " + f.getCustomerPhone() : "" %>
                            </small>
                        </td>
                        <td>
                            <a href="<%= ctx %>/admin/bookings" style="color: #0284c7; font-weight: 600; text-decoration: none;">
                                Booking #<%= f.getBookingId() %>
                            </a><br>
                            <small style="color: #64748b;">
                                <%= f.getCargoType() != null ? f.getCargoType() : "Cargo" %>
                                <%= f.getTrackingNumber() != null ? "• Tracking: " + f.getTrackingNumber() : "" %>
                            </small>
                        </td>
                        <td>
                            <strong style="font-size: 15px; color: #d97706;"><%= r %> / 5 Stars</strong>
                        </td>
                        <td>
                            <div class="comment-text">
                                <%= f.getComments() != null && !f.getComments().trim().isEmpty() ? f.getComments() : "<em style='color:#94a3b8;'>No comments entered.</em>" %>
                            </div>
                        </td>
                        <td>
                            <small style="color: #475569;">
                                <%= f.getFeedbackDate() != null ? f.getFeedbackDate() : "—" %>
                            </small>
                        </td>
                        <td>
                            <form method="post" action="<%= ctx %>/admin/feedback" 
                                  onsubmit="return confirm('Are you sure you want to permanently delete Feedback #<%= f.getFeedbackId() %>? This cannot be undone.');">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="feedbackId" value="<%= f.getFeedbackId() %>">
                                <button type="submit" class="btn-delete">Delete</button>
                            </form>
                        </td>
                    </tr>
                <%  } 
                   } else { %>
                    <tr>
                        <td colspan="7" style="text-align: center; padding: 40px; color: #64748b;">
                            <h3 style="color: #0f172a; margin-bottom: 6px;">No Feedback Records Found</h3>
                            <p style="font-size: 13px;">No customer ratings or reviews matching your search criteria were found.</p>
                        </td>
                    </tr>
                <% } %>
            </tbody>
        </table>
    </div>

</div>

<footer class="app-footer">
    Cargo Transportation Management System • Admin Feedback Management • LBRCE
</footer>

</body>
</html>
