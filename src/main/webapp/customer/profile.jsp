
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Date" %>

<%!
    private String escapeHtml(Object value) {
        if (value == null) {
            return "";
        }

        return value.toString()
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#x27;");
    }
%>

<%
    if (session.getAttribute("userId") == null
            || !"CUSTOMER".equals(session.getAttribute("role"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    if (request.getAttribute("customerId") == null && request.getParameter("saved") == null) {
        response.sendRedirect(request.getContextPath() + "/customer/profile");
        return;
    }

    Object customerId = request.getAttribute("customerId");
    Object fullName = request.getAttribute("fullName");
    Object phone = request.getAttribute("phone");
    Object gender = request.getAttribute("gender");
    Object dateOfBirth = request.getAttribute("dateOfBirth");

    String genderValue = gender == null ? "" : gender.toString();
    String dobValue = dateOfBirth == null ? "" : dateOfBirth.toString();

    String error = request.getParameter("error");
    String saved = request.getParameter("saved");
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Customer Profile</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            font-family: Arial, sans-serif;
            background: #eef3f8;
            margin: 0;
            padding: 35px 15px;
            color: #222;
        }

        .container {
            max-width: 750px;
            margin: auto;
            padding: 30px;
            background: white;
            border-radius: 12px;
            box-shadow: 0 5px 20px rgba(0, 0, 0, 0.10);
        }

        h1 {
            text-align: center;
            color: #175b98;
            margin-bottom: 25px;
        }

        label {
            display: block;
            margin-top: 18px;
            font-weight: bold;
        }

        input, select {
            width: 100%;
            padding: 12px;
            margin-top: 7px;
            border: 1px solid #ccc;
            border-radius: 6px;
            font-size: 16px;
        }

        button {
            width: 100%;
            margin-top: 25px;
            padding: 14px;
            background: #1769aa;
            color: white;
            border: none;
            border-radius: 6px;
            font-size: 17px;
            cursor: pointer;
        }

        button:hover {
            background: #104d80;
        }

        .message {
            padding: 14px;
            margin-bottom: 18px;
            border-radius: 6px;
        }

        .success {
            background: #e3f7e8;
            color: #17652b;
        }

        .error {
            background: #fff0e9;
            color: #a33112;
        }

        .back {
            display: block;
            text-align: center;
            margin-top: 22px;
            color: #1769aa;
            text-decoration: none;
        }

        .back:hover {
            text-decoration: underline;
        }
    </style>
</head>

<body>
<div class="container">

    <h1>My Customer Profile</h1>

    <% if ("success".equals(saved)) { %>
        <div class="message success">
            Profile saved successfully!
        </div>
    <% } %>

    <% if (error != null) { %>
        <div class="message error">
            <% if ("name".equals(error)) { %>
                Please enter your name (maximum 100 characters).
            <% } else if ("phone".equals(error)) { %>
                Phone number must not exceed 15 characters.
            <% } else if ("gender".equals(error)) { %>
                Please select a valid gender.
            <% } else if ("date".equals(error)) { %>
                Please enter a valid date of birth.
            <% } else { %>
                Unable to process your request.
            <% } %>
        </div>
    <% } %>

    <form action="<%= request.getContextPath() %>/customer/profile"
          method="post">

        <label for="fullName">Full Name *</label>
        <input type="text"
               id="fullName"
               name="fullName"
               maxlength="100"
               value="<%= escapeHtml(fullName) %>"
               required>

        <label for="phone">Phone Number</label>
        <input type="tel"
               id="phone"
               name="phone"
               maxlength="15"
               value="<%= escapeHtml(phone) %>">

        <label for="gender">Gender</label>
        <select id="gender" name="gender">
            <option value="">Select Gender</option>

            <option value="Male"
                <%= "Male".equals(genderValue) ? "selected" : "" %>>
                Male
            </option>

            <option value="Female"
                <%= "Female".equals(genderValue) ? "selected" : "" %>>
                Female
            </option>

            <option value="Other"
                <%= "Other".equals(genderValue) ? "selected" : "" %>>
                Other
            </option>
        </select>

        <label for="dateOfBirth">Date of Birth</label>
        <input type="date"
               id="dateOfBirth"
               name="dateOfBirth"
               value="<%= escapeHtml(dobValue) %>">

        <button type="submit">Save Profile</button>
    </form>

    <a class="back"
       href="<%= request.getContextPath() %>/customer/dashboard.jsp">
        Back to Dashboard
    </a>

</div>
</body>
</html>
