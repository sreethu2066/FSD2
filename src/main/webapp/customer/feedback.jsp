<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="com.cargo.model.Feedback" %>
<%@ page import="com.cargo.controller.FeedbackServlet.EligibleBooking" %>

<%
    String role = (String) session.getAttribute("role");
    if (session.getAttribute("userId") == null || !"CUSTOMER".equalsIgnoreCase(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    if (request.getAttribute("bookingList") == null) {
        response.sendRedirect(request.getContextPath() + "/customer/feedback");
        return;
    }

    List<EligibleBooking> bookingList = (List<EligibleBooking>) request.getAttribute("bookingList");
    List<Feedback> feedbackList = (List<Feedback>) request.getAttribute("feedbackList");
    String ctx = request.getContextPath();
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Customer Feedback | Cargo Transportation System</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
    <style>
        .page-header {
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

        .feedback-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 25px;
        }

        .panel-card {
            background: white;
            padding: 24px 28px;
            border-radius: 12px;
            border: 1px solid #e2e8f0;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
        }

        .panel-card h2 {
            font-size: 18px;
            color: #0d3b66;
            margin-bottom: 16px;
            display: flex;
            align-items: center;
            gap: 8px;
            border-bottom: 2px solid #f1f5f9;
            padding-bottom: 10px;
        }

        .form-group {
            margin-bottom: 18px;
        }

        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            font-size: 14px;
            color: #334155;
        }

        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 10px 14px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-size: 14px;
            font-family: inherit;
            box-sizing: border-box;
            background: #f8fafc;
        }

        .form-group select:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #0284c7;
            background: white;
        }

        /* Star Rating Controls */
        .rating-group {
            display: flex;
            gap: 20px;
            align-items: center;
            background: #f8fafc;
            padding: 12px 18px;
            border-radius: 8px;
            border: 1px solid #e2e8f0;
        }

        .star-option {
            display: flex;
            align-items: center;
            gap: 6px;
            cursor: pointer;
            font-size: 15px;
            font-weight: 600;
            color: #475569;
        }

        .star-option input[type="radio"] {
            accent-color: #d97706;
            width: 17px;
            height: 17px;
            cursor: pointer;
        }

        .star-symbol {
            color: #d97706;
            font-size: 17px;
        }

        .history-card {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 18px 20px;
            margin-bottom: 14px;
        }

        .history-top {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
            flex-wrap: wrap;
            gap: 8px;
        }

        .history-title {
            font-weight: 700;
            color: #0d3b66;
            font-size: 15px;
        }

        .stars-display {
            color: #d97706;
            font-size: 17px;
            letter-spacing: 2px;
        }

        .history-comment {
            color: #334155;
            font-size: 14px;
            line-height: 1.5;
            margin: 8px 0;
            white-space: pre-wrap;
        }

        .history-date {
            color: #94a3b8;
            font-size: 12px;
        }

        .empty-box {
            text-align: center;
            padding: 35px 20px;
            color: #64748b;
        }

        .badge-completed {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 700;
            background: #dcfce7;
            color: #15803d;
        }
    </style>
</head>
<body>

<header class="app-header">
    <div class="brand">
        CARGO <span>CTMS</span> | Customer Portal
    </div>
    <div>
        <a class="btn btn-secondary" href="<%= ctx %>/customer/dashboard.jsp">Dashboard</a>
        <a class="btn btn-danger" href="<%= ctx %>/logout" style="margin-left: 8px;">Logout</a>
    </div>
</header>

<div class="container">

    <div class="page-header">
        <div>
            <a class="back-link" href="<%= ctx %>/customer/dashboard.jsp">Back to Dashboard</a>
            <h1 style="margin-top: 8px;">Delivery Feedback & Reviews</h1>
            <p class="subtitle">Rate completed shipments and share your experience with our cargo logistics.</p>
        </div>
    </div>

    <% 
        String success = request.getParameter("success");
        String error = request.getParameter("error");
        if ("1".equals(success)) {
    %>
        <div class="alert alert-success">Thank you! Your feedback has been submitted successfully.</div>
    <% } else if ("duplicate".equals(error)) { %>
        <div class="alert alert-error">Feedback has already been submitted for this booking. Duplicate entries are not allowed.</div>
    <% } else if ("not_completed".equals(error)) { %>
        <div class="alert alert-error">Feedback can only be submitted for completed deliveries.</div>
    <% } else if ("unauthorized_booking".equals(error)) { %>
        <div class="alert alert-error">You can only review your own cargo bookings.</div>
    <% } else if ("invalid_rating".equals(error)) { %>
        <div class="alert alert-error">Please select a valid rating between 1 and 5 stars.</div>
    <% } else if (error != null) { %>
        <div class="alert alert-error">Unable to process feedback: <%= error %></div>
    <% } %>

    <div class="feedback-grid">

        <!-- Form Card -->
        <div class="panel-card">
            <h2>Submit Feedback for Completed Delivery</h2>

            <% if (bookingList == null || bookingList.isEmpty()) { %>
                <div class="empty-box">
                    <strong style="color: #0f172a;">No Eligible Completed Bookings Available</strong>
                    <p style="font-size: 13px; margin-top: 6px;">
                        Feedback is unlocked as soon as your active shipment is delivered and marked as <strong>COMPLETED</strong>.
                        If you have already submitted feedback for your past bookings, thank you!
                    </p>
                </div>
            <% } else { %>
                <form action="<%= ctx %>/customer/feedback" method="post" id="feedbackForm">
                    <div class="form-group">
                        <label for="bookingId">Select Completed Booking *</label>
                        <select name="bookingId" id="bookingId" required>
                            <option value="" disabled selected>-- Choose a Completed Shipment to Review --</option>
                            <% for (EligibleBooking b : bookingList) { %>
                                <option value="<%= b.getBookingId() %>">
                                    Booking #<%= b.getBookingId() %> 
                                    <%= b.getCargoType() != null ? "• " + b.getCargoType() : "" %>
                                    <%= b.getTrackingNumber() != null ? "• Tracking: " + b.getTrackingNumber() : "" %>
                                    (COMPLETED)
                                </option>
                            <% } %>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Service Rating * (1 = Poor, 5 = Excellent)</label>
                        <div class="rating-group">
                            <label class="star-option">
                                <input type="radio" name="rating" value="5" required checked>
                                5 - Excellent
                            </label>
                            <label class="star-option">
                                <input type="radio" name="rating" value="4">
                                4 - Very Good
                            </label>
                            <label class="star-option">
                                <input type="radio" name="rating" value="3">
                                3 - Good
                            </label>
                            <label class="star-option">
                                <input type="radio" name="rating" value="2">
                                2 - Fair
                            </label>
                            <label class="star-option">
                                <input type="radio" name="rating" value="1">
                                1 - Poor
                            </label>
                        </div>
                    </div>

                    <div class="form-group">
                        <label for="comments">Your Review & Comments (Optional)</label>
                        <textarea name="comments" id="comments" rows="4" maxlength="2000"
                                  placeholder="How was the cargo condition, delivery timeliness, and driver service?"></textarea>
                    </div>

                    <button type="submit" class="btn btn-primary" style="padding: 11px 24px; font-size: 14px;">
                        Submit Review
                    </button>
                </form>
            <% } %>
        </div>

        <!-- History Card -->
        <div class="panel-card">
            <h2>Your Feedback History (<%= feedbackList != null ? feedbackList.size() : 0 %>)</h2>

            <% if (feedbackList != null && !feedbackList.isEmpty()) { 
                for (Feedback f : feedbackList) {
                    int r = f.getRating();
                    if (r < 1) r = 1;
                    if (r > 5) r = 5;
            %>
                <div class="history-card">
                    <div class="history-top">
                        <div>
                            <span class="history-title">Booking #<%= f.getBookingId() %></span>
                            <% if (f.getCargoType() != null) { %>
                                <span style="color: #64748b; font-size: 13px;">• <%= f.getCargoType() %></span>
                            <% } %>
                            <% if (f.getTrackingNumber() != null) { %>
                                <span style="color: #0284c7; font-size: 13px;">• Tracking: <%= f.getTrackingNumber() %></span>
                            <% } %>
                            <span class="badge-completed" style="margin-left: 6px;">COMPLETED</span>
                        </div>
                        <div class="stars-display" style="font-size: 14px; font-weight: 600; color: #d97706;">Rating: <%= r %> / 5</div>
                    </div>

                    <% if (f.getComments() != null && !f.getComments().trim().isEmpty()) { %>
                        <div class="history-comment"><%= f.getComments() %></div>
                    <% } else { %>
                        <div class="history-comment" style="color: #94a3b8; font-style: italic;">No detailed comments provided.</div>
                    <% } %>

                    <div class="history-date">
                        Submitted on: <%= f.getFeedbackDate() != null ? f.getFeedbackDate() : "Recently" %>
                    </div>
                </div>
            <%  } 
               } else { %>
                <div class="empty-box">
                    <strong style="color: #0f172a;">No Reviews Submitted Yet</strong>
                    <p style="font-size: 13px; margin-top: 6px;">Your submitted feedback for delivered bookings will appear here.</p>
                </div>
            <% } %>
        </div>

    </div>

</div>

<footer class="app-footer">
    Cargo Transportation Management System • Customer Feedback Portal • LBRCE
</footer>

</body>
</html>
