<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login | Cargo Transportation System</title>
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
            padding: 20px;
        }

        .login-card {
            background: #ffffff;
            width: 100%;
            max-width: 440px;
            padding: 35px 30px;
            border-radius: 12px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.25);
        }

        .brand-header {
            text-align: center;
            margin-bottom: 25px;
        }

        .brand-header .icon {
            font-size: 42px;
        }

        .brand-header h1 {
            font-size: 24px;
            color: #0d3b66;
            margin-top: 8px;
            font-weight: 700;
        }

        .brand-header p {
            color: #64748b;
            font-size: 14px;
            margin-top: 4px;
        }

        .alert {
            padding: 12px 14px;
            border-radius: 6px;
            font-size: 13px;
            margin-bottom: 20px;
            line-height: 1.4;
        }

        .alert-success {
            background-color: #d1fae5;
            color: #065f46;
            border: 1px solid #a7f3d0;
        }

        .alert-error {
            background-color: #fee2e2;
            color: #991b1b;
            border: 1px solid #fecaca;
        }

        .alert-warning {
            background-color: #fef3c7;
            color: #92400e;
            border: 1px solid #fde68a;
        }

        .form-group {
            margin-bottom: 18px;
        }

        label {
            display: block;
            margin-bottom: 6px;
            font-size: 14px;
            font-weight: 600;
            color: #334155;
        }

        input[type="text"],
        input[type="password"],
        select {
            width: 100%;
            padding: 11px 12px;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            font-size: 14px;
            background: #fff;
            transition: border-color 0.2s, box-shadow 0.2s;
        }

        input[type="text"]:focus,
        input[type="password"]:focus,
        select:focus {
            border-color: #0284c7;
            outline: none;
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
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
            margin-top: 8px;
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

        .reg-options {
            display: flex;
            justify-content: center;
            gap: 12px;
            margin-top: 8px;
        }

        .demo-box {
            margin-top: 25px;
            padding: 12px;
            background: #f8fafc;
            border: 1px dashed #cbd5e1;
            border-radius: 6px;
            font-size: 12px;
            color: #475569;
        }
        .demo-box h4 {
            color: #0d3b66;
            margin-bottom: 6px;
        }
    </style>
</head>
<body>

<div class="login-card">
    <div class="brand-header">
        <h1>Cargo Transportation</h1>
        <p>Sign in to your account</p>
    </div>

    <% 
        String registered = request.getParameter("registered");
        String logout = request.getParameter("logout");
        String error = request.getParameter("error");

        if ("driver_pending".equals(registered)) {
    %>
        <div class="alert alert-warning">
            Driver registration submitted! Your account is <strong>PENDING ADMIN APPROVAL</strong>. You can sign in to view your application status.
        </div>
    <% } else if ("success".equals(registered)) { %>
        <div class="alert alert-success">
            Customer registration successful! You can now log in.
        </div>
    <% } else if ("success".equals(logout)) { %>
        <div class="alert alert-success">
            You have been logged out successfully.
        </div>
    <% } else if ("role_mismatch".equals(error)) { %>
        <div class="alert alert-error">
            Role Mismatch: The credentials provided do not match the selected user role.
        </div>
    <% } else if ("invalid".equals(error)) { %>
        <div class="alert alert-error">
            Invalid username or password. Please try again.
        </div>
    <% } else if ("unauthorized".equals(error)) { %>
        <div class="alert alert-warning">
            Please log in first to access that section.
        </div>
    <% } else if ("forbidden".equals(error)) { %>
        <div class="alert alert-error">
            Access Denied: You do not have permission to view that section.
        </div>
    <% } else if ("server".equals(error)) { %>
        <div class="alert alert-error">
            A database error occurred. Please check server logs.
        </div>
    <% } %>

    <form id="loginForm" action="${pageContext.request.contextPath}/login" method="post" onsubmit="return validateForm()">
        <div class="form-group">
            <label for="username">Username</label>
            <input type="text" id="username" name="username" placeholder="Enter your username" required maxlength="50" autocomplete="username">
        </div>

        <div class="form-group">
            <label for="password">Password</label>
            <input type="password" id="password" name="password" placeholder="Enter your password" required autocomplete="current-password">
        </div>

        <div class="form-group">
            <label for="role">User Role</label>
            <select id="role" name="role">
                <option value="ANY">Auto-Detect Role</option>
                <option value="CUSTOMER">Customer (Freight Booker)</option>
                <option value="DRIVER">Driver (Fleet Delivery)</option>
                <option value="ADMIN">Administrator (Fleet Dispatch)</option>
            </select>
        </div>

        <button type="submit" class="btn-submit">Sign In</button>
    </form>

    <div class="footer-links">
        <div>Don't have an account?</div>
        <div class="reg-options">
            <a href="${pageContext.request.contextPath}/register.jsp?type=customer">Register as Customer</a>
            <span>•</span>
            <a href="${pageContext.request.contextPath}/register.jsp?type=driver">Register as Driver</a>
        </div>
    </div>

    <div class="demo-box">
        <h4>College Demo Credentials (Password: 12345678)</h4>
        <div>• <strong>Admin:</strong> admin_test</div>
        <div>• <strong>Driver:</strong> driver_test</div>
        <div>• <strong>Customer:</strong> customer_test</div>
    </div>
</div>

<script>
function validateForm() {
    var u = document.getElementById("username").value.trim();
    var p = document.getElementById("password").value;
    if (u === "" || p === "") {
        alert("Please enter both username and password.");
        return false;
    }
    return true;
}
</script>

</body>
</html>
