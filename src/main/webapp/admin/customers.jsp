
<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="com.cargo.controller.AdminCustomerServlet.Customer" %>

<%!
    public String esc(String value) {
        if (value == null) return "";
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

    List<Customer> customers =
        (List<Customer>) request.getAttribute("customers");

    String message =
        (String) session.getAttribute("customerMessage");
    String error =
        (String) session.getAttribute("customerError");

    session.removeAttribute("customerMessage");
    session.removeAttribute("customerError");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <title>Customer Management | Cargo Transportation</title>

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
            max-width: 1400px;
            margin: auto;
        }

        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 15px;
            flex-wrap: wrap;
            margin-bottom: 22px;
        }

        h1 {
            margin: 0 0 8px;
            color: #173b70;
        }

        .subtitle {
            color: #64748b;
            margin: 0;
        }

        .back {
            text-decoration: none;
            background: #173b70;
            color: white;
            padding: 11px 16px;
            border-radius: 7px;
        }

        .card {
            background: white;
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 4px 18px #0000000d;
            overflow-x: auto;
        }

        .alert {
            padding: 12px 15px;
            border-radius: 7px;
            margin-bottom: 15px;
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
            border-collapse: collapse;
            min-width: 1050px;
        }

        th, td {
            padding: 13px 10px;
            border-bottom: 1px solid #e5e7eb;
            text-align: left;
            vertical-align: top;
        }

        th {
            background: #edf3fb;
            color: #173b70;
            white-space: nowrap;
        }

        input, select {
            width: 145px;
            padding: 8px;
            border: 1px solid #cbd5e1;
            border-radius: 5px;
            margin-bottom: 5px;
        }

        .name-input {
            width: 170px;
        }

        button {
            border: 0;
            border-radius: 5px;
            padding: 9px 12px;
            color: white;
            cursor: pointer;
            margin: 3px 0;
        }

        .update {
            background: #2563eb;
        }

        .delete {
            background: #dc2626;
        }

        .actions {
            min-width: 110px;
        }

        .empty {
            padding: 25px;
            text-align: center;
            color: #64748b;
        }
    </style>
</head>

<body>
<div class="container">

    <div class="header">
        <div>
            <h1>Customer Management</h1>
            <p class="subtitle">
                View and update registered customer profiles.
            </p>
        </div>

        <a class="back"
           href="<%= request.getContextPath() %>/admin/dashboard.jsp">
            Back to Dashboard
        </a>
    </div>

    <% if (message != null) { %>
        <div class="alert success"><%= esc(message) %></div>
    <% } %>

    <% if (error != null) { %>
        <div class="alert error"><%= esc(error) %></div>
    <% } %>

    <div class="card">
        <table>
            <thead>
            <tr>
                <th>Customer ID</th>
                <th>User ID</th>
                <th>Username</th>
                <th>Email</th>
                <th>Full Name</th>
                <th>Phone</th>
                <th>Gender</th>
                <th>Date of Birth</th>
                <th>Actions</th>
            </tr>
            </thead>

            <tbody>
            <% if (customers != null && !customers.isEmpty()) {
                   for (Customer c : customers) { %>

                <tr>
                    <form method="post"
                          action="<%= request.getContextPath() %>/admin/customers">

                        <input type="hidden"
                               name="action"
                               value="update">

                        <input type="hidden"
                               name="customerId"
                               value="<%= c.getCustomerId() %>">

                        <td><%= c.getCustomerId() %></td>
                        <td><%= c.getUserId() %></td>
                        <td><%= esc(c.getUsername()) %></td>
                        <td><%= esc(c.getEmail()) %></td>

                        <td>
                            <input class="name-input"
                                   type="text"
                                   name="fullName"
                                   maxlength="100"
                                   required
                                   value="<%= esc(c.getFullName()) %>">
                        </td>

                        <td>
                            <input type="tel"
                                   name="phone"
                                   maxlength="15"
                                   value="<%= esc(c.getPhone()) %>">
                        </td>

                        <td>
                            <select name="gender">
                                <option value=""
                                    <%= c.getGender() == null ||
                                        c.getGender().isEmpty()
                                        ? "selected" : "" %>>
                                    Not specified
                                </option>

                                <option value="Male"
                                    <%= "Male".equalsIgnoreCase(c.getGender())
                                        ? "selected" : "" %>>
                                    Male
                                </option>

                                <option value="Female"
                                    <%= "Female".equalsIgnoreCase(c.getGender())
                                        ? "selected" : "" %>>
                                    Female
                                </option>

                                <option value="Other"
                                    <%= "Other".equalsIgnoreCase(c.getGender())
                                        ? "selected" : "" %>>
                                    Other
                                </option>
                            </select>
                        </td>

                        <td>
                            <input type="date"
                                   name="dateOfBirth"
                                   value="<%= c.getDateOfBirth() == null
                                       ? ""
                                       : c.getDateOfBirth().toString() %>">
                        </td>

                        <td class="actions">
                            <button class="update" type="submit">
                                Update
                            </button>
                    </form>

                            <form method="post"
                                  action="<%= request.getContextPath() %>/admin/customers"
                                  onsubmit="return confirm(
                                      'Delete this customer profile?'
                                  );">

                                <input type="hidden"
                                       name="action"
                                       value="delete">

                                <input type="hidden"
                                       name="customerId"
                                       value="<%= c.getCustomerId() %>">

                                <button class="delete" type="submit">
                                    Delete
                                </button>
                            </form>
                        </td>
                </tr>

            <%     }
               } else { %>

                <tr>
                    <td colspan="9" class="empty">
                        No customer profiles found.
                    </td>
                </tr>

            <% } %>
            </tbody>
        </table>
    </div>

</div>
</body>
</html>
