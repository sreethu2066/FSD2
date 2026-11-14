<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String role = (String) session.getAttribute("role");
    if (session.getAttribute("userId") == null || !"ADMIN".equalsIgnoreCase(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    Object driverIdObj = request.getAttribute("driverId");
    boolean editing = driverIdObj != null;
    String ctx = request.getContextPath();

    String genUsername = (String) request.getAttribute("genUsername");
    if (genUsername == null) genUsername = "";
    String genPassword = (String) request.getAttribute("genPassword");
    if (genPassword == null) genPassword = "";

    String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= editing ? "Edit Driver Details" : "Add New Fleet Driver" %> | CTMS Admin</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
    <style>
        .form-card {
            max-width: 680px;
            margin: 25px auto;
            background: #ffffff;
            border-radius: 12px;
            box-shadow: 0 4px 18px rgba(0, 0, 0, 0.08);
            border: 1px solid #e2e8f0;
            overflow: hidden;
        }

        .form-header {
            background: linear-gradient(135deg, #0d3b66 0%, #0284c7 100%);
            color: #ffffff;
            padding: 22px 28px;
        }

        .form-header h2 {
            color: #ffffff;
            margin: 0 0 6px 0;
            font-size: 22px;
        }

        .form-header p {
            margin: 0;
            font-size: 13px;
            opacity: 0.9;
        }

        .form-body {
            padding: 28px;
        }

        .grid-2 {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
        }

        @media (max-width: 600px) {
            .grid-2 { grid-template-columns: 1fr; }
        }

        .input-group {
            position: relative;
            display: flex;
        }

        .input-group input {
            flex: 1;
            border-top-right-radius: 0;
            border-bottom-right-radius: 0;
        }

        .input-group button {
            background: #e2e8f0;
            border: 1px solid #cbd5e1;
            border-left: none;
            padding: 0 14px;
            font-size: 12px;
            font-weight: 600;
            color: #334155;
            border-top-right-radius: 6px;
            border-bottom-right-radius: 6px;
            cursor: pointer;
            transition: background 0.2s;
            white-space: nowrap;
        }

        .input-group button:hover {
            background: #cbd5e1;
        }

        .field-hint {
            font-size: 11px;
            color: #64748b;
            margin-top: 4px;
        }

        .info-callout {
            background: #f0f9ff;
            border-left: 4px solid #0284c7;
            padding: 12px 16px;
            border-radius: 4px;
            font-size: 13px;
            color: #0369a1;
            margin-bottom: 22px;
        }

        .alert-error {
            background: #fee2e2;
            border: 1px solid #f87171;
            color: #991b1b;
            padding: 12px 16px;
            border-radius: 6px;
            font-size: 13px;
            margin-bottom: 20px;
        }

        .btn-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-top: 28px;
            padding-top: 20px;
            border-top: 1px solid #e2e8f0;
        }

        .readonly-chip {
            display: inline-block;
            background: #f1f5f9;
            padding: 6px 12px;
            border-radius: 4px;
            font-family: monospace;
            font-size: 13px;
            color: #334155;
            border: 1px solid #cbd5e1;
            width: 100%;
            box-sizing: border-box;
        }
    </style>
</head>
<body>

<header class="app-header">
    <div class="brand">
        CARGO <span>CTMS</span> | Fleet Admin
    </div>
    <div>
        <a class="btn btn-secondary" href="<%= ctx %>/admin/drivers">Back to Drivers</a>
        <a class="btn btn-danger" href="<%= ctx %>/logout" style="margin-left: 8px;">Logout</a>
    </div>
</header>

<div class="container">
    <div class="form-card">
        <div class="form-header">
            <h2><%= editing ? "Edit Driver Profile" : "Create New Driver Account" %></h2>
            <p><%= editing ? "Update driver contact information, driving license, and fleet status." : "Provision a new driver with login credentials and fleet profile in a single atomic transaction." %></p>
        </div>

        <div class="form-body">
            <% if (error != null) { %>
                <div class="alert-error">
                    <% if ("required".equals(error)) { %>
                        <strong>Missing required fields!</strong> Please fill in all mandatory fields (Full Name, Phone, License Number).
                    <% } else if ("username_exists".equals(error)) { %>
                        <strong>Username already taken!</strong> Please choose a different username or use auto-generate.
                    <% } else if ("email_exists".equals(error)) { %>
                        <strong>Email already registered!</strong> Please provide a different email address.
                    <% } else if ("license_exists".equals(error)) { %>
                        <strong>License number already exists!</strong> Another driver is already registered with this license number.
                    <% } else { %>
                        <strong>Operation failed!</strong> An unexpected error occurred. Please check the logs and try again.
                    <% } %>
                </div>
            <% } %>

            <% if (!editing) { %>
                <div class="info-callout">
                    <strong>Atomic Account Creation:</strong> Creating a driver here automatically inserts the user into the <code>users</code> table (with role <code>DRIVER</code>) and the driver profile into the <code>drivers</code> table within a single secure database transaction.
                </div>
            <% } %>

            <form action="<%= editing ? (ctx + "/admin/drivers") : (ctx + "/admin/add-driver") %>" method="post" id="driverForm">
                <% if (editing) { %>
                    <input type="hidden" name="action" value="update">
                    <input type="hidden" name="driverId" value="<%= driverIdObj %>">
                <% } %>

                <% if (editing) { %>
                    <div class="grid-2">
                        <div class="form-group">
                            <label>Driver ID</label>
                            <span class="readonly-chip">#<%= driverIdObj %></span>
                        </div>
                        <div class="form-group">
                            <label>System Username</label>
                            <span class="readonly-chip">@<%= request.getAttribute("username") != null ? request.getAttribute("username") : "driver_" + driverIdObj %></span>
                        </div>
                    </div>
                <% } %>

                <div class="form-group">
                    <label for="driverName">Full Legal Name <span style="color:#dc2626;">*</span></label>
                    <input type="text" id="driverName" name="driverName"
                           value="<%= editing ? request.getAttribute("driverName") : "" %>"
                           placeholder="e.g. John Doe" maxlength="100" required>
                    <div class="field-hint">Driver's official name as printed on their driving license.</div>
                </div>

                <% if (!editing) { %>
                    <!-- Credentials Provisioning (Add Mode Only) -->
                    <div class="grid-2">
                        <div class="form-group">
                            <label for="username">Driver Username <span style="color:#dc2626;">*</span></label>
                            <div class="input-group">
                                <input type="text" id="username" name="username"
                                       value="<%= genUsername %>"
                                       placeholder="e.g. driver_john" maxlength="50" required>
                                <button type="button" onclick="autoGenerateUsername()" title="Generate random username">Auto</button>
                            </div>
                            <div class="field-hint">Used by driver to log in. Must be unique.</div>
                        </div>

                        <div class="form-group">
                            <label for="password">Temporary Password <span style="color:#dc2626;">*</span></label>
                            <div class="input-group">
                                <input type="text" id="password" name="password"
                                       value="<%= genPassword %>"
                                       placeholder="Temporary password" maxlength="50" required>
                                <button type="button" onclick="autoGeneratePassword()" title="Generate random secure password">Generate</button>
                            </div>
                            <div class="field-hint">Will be securely hashed with BCrypt before storage.</div>
                        </div>
                    </div>
                <% } %>

                <div class="grid-2">
                    <div class="form-group">
                        <label for="phone">Phone Number <span style="color:#dc2626;">*</span></label>
                        <input type="text" id="phone" name="phone"
                               value="<%= editing ? request.getAttribute("phone") : "" %>"
                               placeholder="e.g. +91 9876543210" maxlength="15" required>
                    </div>

                    <div class="form-group">
                        <label for="email">Email Address</label>
                        <input type="email" id="email" name="email"
                               value="<%= editing && request.getAttribute("email") != null ? request.getAttribute("email") : "" %>"
                               placeholder="e.g. driver@example.com" maxlength="100">
                    </div>
                </div>

                <div class="grid-2">
                    <div class="form-group">
                        <label for="licenseNumber">Driving License Number <span style="color:#dc2626;">*</span></label>
                        <input type="text" id="licenseNumber" name="licenseNumber"
                               value="<%= editing ? request.getAttribute("licenseNumber") : "" %>"
                               placeholder="e.g. DL-1420110012345" maxlength="50" required style="text-transform: uppercase;">
                        <div class="field-hint">Unique commercial driving license number.</div>
                    </div>

                    <div class="form-group">
                        <label for="experienceYears">Experience (Years)</label>
                        <input type="number" id="experienceYears" name="experienceYears"
                               min="0" max="60"
                               value="<%= editing && request.getAttribute("experienceYears") != null ? request.getAttribute("experienceYears") : "0" %>"
                               required>
                    </div>
                </div>

                <div class="form-group">
                    <label for="status">Initial / Fleet Status <span style="color:#dc2626;">*</span></label>
                    <select id="status" name="status">
                        <%
                            String currentStatus = editing
                                    ? String.valueOf(request.getAttribute("status"))
                                    : "AVAILABLE";
                        %>
                        <option value="AVAILABLE" <%= "AVAILABLE".equalsIgnoreCase(currentStatus) ? "selected" : "" %>>
                            AVAILABLE (Active & Ready for Assignment)
                        </option>
                        <% if (editing) { %>
                            <option value="ASSIGNED" <%= "ASSIGNED".equalsIgnoreCase(currentStatus) ? "selected" : "" %>>
                                ASSIGNED (Currently On Active Route)
                            </option>
                        <% } %>
                        <option value="INACTIVE" <%= "INACTIVE".equalsIgnoreCase(currentStatus) ? "selected" : "" %>>
                            INACTIVE (Disabled / Pending Verification)
                        </option>
                    </select>
                    <div class="field-hint">
                        <%= editing ? "Set to INACTIVE to temporarily revoke driver operational access." : "Choose AVAILABLE to allow immediate vehicle assignment, or INACTIVE if onboarding is pending review." %>
                    </div>
                </div>

                <div class="btn-row">
                    <a href="<%= ctx %>/admin/drivers" class="btn btn-secondary">Cancel</a>
                    <button type="submit" class="btn btn-primary" style="padding: 12px 28px; font-size: 15px;">
                        <%= editing ? "Save Changes" : "Create Driver Account" %>
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
    function autoGenerateUsername() {
        const nameInput = document.getElementById('driverName').value.trim();
        let base = "driver";
        if (nameInput.length > 0) {
            base = nameInput.toLowerCase().replace(/[^a-z0-9]/g, '');
            if (base.length > 10) base = base.substring(0, 10);
            if (base.length === 0) base = "driver";
        }
        const randomDigits = Math.floor(1000 + Math.random() * 9000);
        document.getElementById('username').value = base + "_" + randomDigits;
    }

    function autoGeneratePassword() {
        const chars = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789!@#$%";
        let pass = "";
        for (let i = 0; i < 10; i++) {
            pass += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        document.getElementById('password').value = pass;
    }
</script>

</body>
</html>
