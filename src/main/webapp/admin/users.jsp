
<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" %>

<%@ page import="java.util.List" %>
<%@ page import="com.cargo.controller.AdminUserServlet.User" %>

<%!
    public String escapeHtml(String value) {
        if (value == null) {
            return "";
        }

        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }
%>

<%
    if (session.getAttribute("userId") == null ||
        !"ADMIN".equalsIgnoreCase(
            String.valueOf(session.getAttribute("role")))) {

        response.sendRedirect(
            request.getContextPath() + "/login.jsp"
        );
        return;
    }

    List<User> users =
        (List<User>) request.getAttribute("users");

    String message =
        (String) session.getAttribute("userMessage");

    String error =
        (String) session.getAttribute("userError");

    session.removeAttribute("userMessage");
    session.removeAttribute("userError");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">

    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <title>User Management | Cargo Transportation</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            padding: 25px;
            font-family: Arial, sans-serif;
            background: #f3f6fb;
            color: #1f2937;
        }

        .container {
            max-width: 1150px;
            margin: auto;
        }

        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
            margin-bottom: 25px;
        }

        h1 {
            margin: 0 0 8px;
            color: #173b70;
        }

        .subtitle {
            margin: 0;
            color: #64748b;
        }

        .back {
            display: inline-block;
            padding: 11px 16px;
            background: #173b70;
            color: white;
            text-decoration: none;
            border-radius: 7px;
        }

        .card {
            background: white;
            padding: 20px;
            border-radius: 12px;
            box-shadow: 0 4px 18px #0000000d;
            overflow-x: auto;
        }

        .alert {
            padding: 13px 16px;
            border-radius: 7px;
            margin-bottom: 16px;
        }

        .success {
            background: #dcfce7;
            color: #166534;
        }

        .error {
            background: #fee2e2;
            color: #991b1b;
        }

        table {
            width: 100%;
            min-width: 750px;
            border-collapse: collapse;
        }

        th, td {
            padding: 14px 12px;
            border-bottom: 1px solid #e5e7eb;
            text-align: left;
            vertical-align: middle;
        }

        th {
            background: #edf3fb;
            color: #173b70;
        }

        .badge {
            display: inline-block;
            padding: 6px 10px;
            border-radius: 20px;
            background: #e0e7ff;
            color: #3730a3;
            font-size: 12px;
            font-weight: bold;
        }

        select {
            padding: 9px;
            border: 1px solid #cbd5e1;
            border-radius: 5px;
            background: white;
        }

        button {
            border: none;
            border-radius: 5px;
            padding: 9px 12px;
            color: white;
            cursor: pointer;
            font-weight: bold;
        }

        .update {
            background: #2563eb;
        }

        .delete {
            background: #dc2626;
        }

        .empty {
            text-align: center;
            color: #64748b;
            padding: 25px;
        }

        .action-form {
            margin: 4px 0;
        }
    </style>
</head>

<body>

<div class="container">

    <div class="header">
        <div>
            <h1>User Management</h1>
            <p class="subtitle">
                View user accounts and manage their roles.
            </p>
        </div>

        <a class="back"
           href="<%= request.getContextPath() %>/admin/dashboard.jsp">
            Back to Dashboard
        </a>
    </div>

    <% if (message != null) { %>
        <div class="alert success">
            <%= escapeHtml(message) %>
        </div>
    <% } %>

    <% if (error != null) { %>
        <div class="alert error">
            <%= escapeHtml(error) %>
        </div>
    <% } %>

    <div class="card">

        <table>
            <thead>
                <tr>
                    <th>User ID</th>
                    <th>Username</th>
                    <th>Email</th>
                    <th>Current Role</th>
                    <th>Update Role</th>
                    <th>Delete User</th>
                </tr>
            </thead>

            <tbody>

            <% if (users != null && !users.isEmpty()) {
                   for (User item : users) {
                       int userId = item.getUserId();

                       String username =
                           escapeHtml(item.getUsername());

                       String email =
                           escapeHtml(item.getEmail());

                       String currentRole =
                           item.getRole() == null
                               ? ""
                               : item.getRole();
            %>

                <tr>
                    <td><%= userId %></td>

                    <td><%= username %></td>

                    <td><%= email %></td>

                    <td>
                        <span class="badge">
                            <%= escapeHtml(currentRole) %>
                        </span>
                    </td>

                    <td>
                        <form class="action-form"
                              method="post"
                              action="<%= request.getContextPath() %>/admin/users">

                            <input type="hidden"
                                   name="action"
                                   value="updateRole">

                            <input type="hidden"
                                   name="userId"
                                   value="<%= userId %>">

                            <select name="role" required>
                                <option value="ADMIN"
                                    <%= "ADMIN".equalsIgnoreCase(currentRole)
                                        ? "selected" : "" %>>
                                    ADMIN
                                </option>

                                <option value="CUSTOMER"
                                    <%= "CUSTOMER".equalsIgnoreCase(currentRole)
                                        ? "selected" : "" %>>
                                    CUSTOMER
                                </option>

                                <option value="DRIVER"
                                    <%= "DRIVER".equalsIgnoreCase(currentRole)
                                        ? "selected" : "" %>>
                                    DRIVER
                                </option>
                            </select>

                            <button class="update" type="submit">
                                Update
                            </button>
                        </form>
                    </td>

                    <td>
                        <form class="action-form"
                              method="post"
                              action="<%= request.getContextPath() %>/admin/users"
                              onsubmit="return confirm(
                                  'Are you sure you want to delete this user?'
                              );">

                            <input type="hidden"
                                   name="action"
                                   value="delete">

                            <input type="hidden"
                                   name="userId"
                                   value="<%= userId %>">

                            <button class="delete" type="submit">
                                Delete
                            </button>
                        </form>
                    </td>
                </tr>

            <%
                   }
               } else {
            %>

                <tr>
                    <td colspan="6" class="empty">
                        No users found.
                    </td>
                </tr>

            <% } %>

            </tbody>
        </table>

    </div>
</div>

</body>
</html>
