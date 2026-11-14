<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String typeParam = request.getParameter("type");
    boolean isDriver = "driver".equalsIgnoreCase(typeParam);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= isDriver ? "Driver Registration" : "Customer Registration" %> | Cargo Transportation System</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }

        body {
            background: linear-gradient(135deg, #0d3b66 0%, #001e3d 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            padding: 25px 20px;
        }

        .register-card {
            background: #ffffff;
            width: 100%;
            max-width: 520px;
            padding: 35px 30px;
            border-radius: 12px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.25);
        }

        .brand-header {
            text-align: center;
            margin-bottom: 20px;
        }

        .brand-header .icon {
            font-size: 38px;
        }

        .brand-header h1 {
            font-size: 24px;
            color: #0d3b66;
            margin-top: 6px;
            font-weight: 700;
        }

        .brand-header p {
            color: #64748b;
            font-size: 14px;
            margin-top: 4px;
        }

        /* Role Switcher Tabs */
        .role-tabs {
            display: flex;
            background: #f1f5f9;
            border-radius: 8px;
            padding: 4px;
            margin-bottom: 22px;
            gap: 4px;
        }

        .role-tab {
            flex: 1;
            text-align: center;
            padding: 9px 12px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 600;
            text-decoration: none;
            color: #64748b;
            transition: all 0.2s;
            cursor: pointer;
            border: none;
            background: transparent;
        }

        .role-tab.active {
            background: white;
            color: #0284c7;
            box-shadow: 0 2px 6px rgba(0,0,0,0.08);
        }

        .alert {
            padding: 12px 14px;
            border-radius: 6px;
            font-size: 13px;
            margin-bottom: 20px;
            line-height: 1.4;
        }

        .alert-error {
            background-color: #fee2e2;
            color: #991b1b;
            border: 1px solid #fecaca;
        }

        .alert-info {
            background-color: #e0f2fe;
            color: #0369a1;
            border: 1px solid #bae6fd;
        }

        .form-group {
            margin-bottom: 15px;
        }

        label {
            display: block;
            margin-bottom: 6px;
            font-size: 13px;
            font-weight: 600;
            color: #334155;
        }

        input[type="text"],
        input[type="email"],
        input[type="password"],
        input[type="number"] {
            width: 100%;
            padding: 11px;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            font-size: 14px;
            box-sizing: border-box;
            transition: border-color 0.2s, box-shadow 0.2s;
        }

        input:focus {
            border-color: #0284c7;
            outline: none;
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
        }

        .grid-2 {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
        }

        .btn-submit {
            width: 100%;
            padding: 12px;
            background: #0284c7;
            color: white;
            border: none;
            border-radius: 6px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.2s;
            margin-top: 10px;
        }

        .btn-submit:hover {
            background: #0369a1;
        }

        .footer-links {
            text-align: center;
            margin-top: 22px;
            font-size: 14px;
            color: #64748b;
        }

        .footer-links a {
            color: #0284c7;
            text-decoration: none;
            font-weight: 600;
        }

        .footer-links a:hover {
            text-decoration: underline;
        }

        .helper {
            font-size: 11px;
            color: #94a3b8;
            margin-top: 3px;
        }
    </style>
</head>
<body>

<div class="register-card">
    <div class="brand-header">
        <h1 id="pageTitle"><%= isDriver ? "Driver Self-Registration" : "Customer Registration" %></h1>
        <p id="pageSubtitle"><%= isDriver ? "Apply to join our freight delivery fleet" : "Create an account to book cargo transportation" %></p>
    </div>

    <!-- Role Switcher -->
    <div class="role-tabs">
        <a class="role-tab <%= !isDriver ? "active" : "" %>" href="register.jsp?type=customer" id="tabCustomer">
            Customer Registration
        </a>
        <a class="role-tab <%= isDriver ? "active" : "" %>" href="register.jsp?type=driver" id="tabDriver">
            Driver Registration
        </a>
    </div>

    <% 
        String error = request.getParameter("error");
        if ("username_exists".equals(error)) { 
    %>
        <div class="alert alert-error">That username is already taken. Please choose another.</div>
    <% } else if ("email_exists".equals(error)) { %>
        <div class="alert alert-error">That email address is already registered. Please login.</div>
    <% } else if ("license_exists".equals(error)) { %>
        <div class="alert alert-error">That driving license number is already registered in the system.</div>
    <% } else if ("driver_fields_required".equals(error)) { %>
        <div class="alert alert-error">Phone and Driving License Number are required for driver registration.</div>
    <% } else if ("password_mismatch".equals(error)) { %>
        <div class="alert alert-error">Passwords do not match. Please re-enter.</div>
    <% } else if ("required".equals(error)) { %>
        <div class="alert alert-error">All required fields must be filled out.</div>
    <% } else if ("short_password".equals(error)) { %>
        <div class="alert alert-error">Password must be at least 6 characters long.</div>
    <% } else if ("invalid_email".equals(error)) { %>
        <div class="alert alert-error">Please provide a valid email address.</div>
    <% } else if ("forbidden_role".equals(error)) { %>
        <div class="alert alert-error">Forbidden: Administrator accounts cannot be created publicly.</div>
    <% } else if ("server".equals(error)) { %>
        <div class="alert alert-error">Registration failed due to a database issue. Please try again.</div>
    <% } %>

    <% if (isDriver) { %>
        <div class="alert alert-info">
            <strong>Driver Notice:</strong> Upon registration, your account will be set to <strong>PENDING APPROVAL</strong>. An administrator will review your driving license before dispatching shipments.
        </div>
    <% } %>

    <form id="regForm" action="${pageContext.request.contextPath}/register" method="post" onsubmit="return validateRegisterForm()">
        
        <input type="hidden" name="role" id="roleInput" value="<%= isDriver ? "DRIVER" : "CUSTOMER" %>">

        <div class="form-group">
            <label for="fullName">Full Name *</label>
            <input type="text" id="fullName" name="fullName" placeholder="e.g. Rajesh Kumar" required maxlength="100">
        </div>

        <div class="grid-2">
            <div class="form-group">
                <label for="username">Username *</label>
                <input type="text" id="username" name="username" placeholder="e.g. rajesh_driver" required maxlength="50" autocomplete="username">
            </div>

            <div class="form-group">
                <label for="email">Email Address *</label>
                <input type="email" id="email" name="email" placeholder="e.g. rajesh@example.com" required maxlength="100" autocomplete="email">
            </div>
        </div>

        <% if (isDriver) { %>
            <div class="grid-2">
                <div class="form-group">
                    <label for="phone">Phone Number *</label>
                    <input type="text" id="phone" name="phone" placeholder="e.g. 9876543210" required maxlength="15">
                </div>

                <div class="form-group">
                    <label for="experienceYears">Experience (Years)</label>
                    <input type="number" id="experienceYears" name="experienceYears" min="0" max="50" value="2" required>
                </div>
            </div>

            <div class="form-group">
                <label for="licenseNumber">Commercial Driving License # *</label>
                <input type="text" id="licenseNumber" name="licenseNumber" placeholder="e.g. AP-07-2022-004312" required maxlength="50" style="text-transform: uppercase;">
                <div class="helper">Enter your valid commercial or transport vehicle driving license</div>
            </div>
        <% } %>

        <div class="grid-2">
            <div class="form-group">
                <label for="password">Password *</label>
                <input type="password" id="password" name="password" placeholder="Min 6 characters" required minlength="6" autocomplete="new-password">
            </div>

            <div class="form-group">
                <label for="confirmPassword">Confirm Password *</label>
                <input type="password" id="confirmPassword" name="confirmPassword" placeholder="Re-enter password" required minlength="6" autocomplete="new-password">
            </div>
        </div>

        <button type="submit" class="btn-submit" id="submitBtn">
            <%= isDriver ? "Submit Driver Application" : "Create Customer Account" %>
        </button>
    </form>

    <div class="footer-links">
        Already have an account? <a href="${pageContext.request.contextPath}/login.jsp">Sign In here</a>
    </div>
</div>

<script>
function validateRegisterForm() {
    var p1 = document.getElementById("password").value;
    var p2 = document.getElementById("confirmPassword").value;
    if (p1 !== p2) {
        alert("Passwords do not match. Please re-enter.");
        document.getElementById("confirmPassword").focus();
        return false;
    }
    if (p1.length < 6) {
        alert("Password must be at least 6 characters long.");
        return false;
    }

    var isDrv = document.getElementById("roleInput").value === "DRIVER";
    if (isDrv) {
        var phone = document.getElementById("phone").value.trim();
        var lic = document.getElementById("licenseNumber").value.trim();
        if (phone === "" || lic === "") {
            alert("Phone number and Driving License number are required for driver registration.");
            return false;
        }
    }
    return true;
}
</script>

</body>
</html>
