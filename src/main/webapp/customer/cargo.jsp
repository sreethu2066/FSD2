
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="com.cargo.controller.CargoServlet.Cargo" %>

<%!
    private String escapeHtml(Object value) {
        if (value == null) return "";

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

    if (request.getAttribute("cargoList") == null) {
        response.sendRedirect(request.getContextPath() + "/customer/cargo");
        return;
    }

    List<Cargo> cargoList =
            (List<Cargo>) request.getAttribute("cargoList");

    String saved = request.getParameter("saved");
    String deleted = request.getParameter("deleted");
    String error = request.getParameter("error");
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Cargo - Cargo Transportation System</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            padding: 30px 15px;
            background: #eef3f8;
            font-family: Arial, sans-serif;
            color: #222;
        }

        .container {
            max-width: 1000px;
            margin: auto;
            padding: 30px;
            background: white;
            border-radius: 12px;
            box-shadow: 0 5px 20px rgba(0, 0, 0, 0.1);
        }

        h1, h2 {
            color: #175b98;
        }

        h1 {
            text-align: center;
        }

        label {
            display: block;
            margin-top: 16px;
            font-weight: bold;
        }

        input, select, textarea {
            width: 100%;
            padding: 12px;
            margin-top: 7px;
            border: 1px solid #ccc;
            border-radius: 6px;
            font-size: 15px;
        }

        textarea {
            resize: vertical;
        }

        .checkbox-row {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-top: 18px;
        }

        .checkbox-row input {
            width: auto;
            margin: 0;
        }

        button {
            padding: 12px 18px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 15px;
        }

        .save-button {
            width: 100%;
            margin-top: 22px;
            background: #1769aa;
            color: white;
        }

        .delete-button {
            background: #c0392b;
            color: white;
        }

        .cargo-card {
            border: 1px solid #d7e0e9;
            padding: 20px;
            margin-top: 18px;
            border-radius: 8px;
            overflow-wrap: anywhere;
        }

        .message {
            padding: 13px;
            margin: 15px 0;
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
            margin-top: 25px;
            color: #1769aa;
            text-decoration: none;
        }
    </style>
</head>

<body>
<div class="container">

    <h1>My Cargo</h1>
    <p>Register and manage your cargo details.</p>

    <% if ("success".equals(saved)) { %>
        <div class="message success">
            Cargo registered successfully!
        </div>
    <% } %>

    <% if ("success".equals(deleted)) { %>
        <div class="message success">
            Cargo deleted successfully.
        </div>
    <% } %>

    <% if ("invalid".equals(error)) { %>
        <div class="message error">
            Please check your cargo details. Weight and quantity must
            be positive, and all required fields must be filled.
        </div>
    <% } %>

    <h2>Register New Cargo</h2>

    <form action="<%= request.getContextPath() %>/customer/cargo"
          method="post">

        <input type="hidden" name="action" value="add">

        <label for="cargoType">Cargo Type *</label>
        <input type="text"
               id="cargoType"
               name="cargoType"
               maxlength="100"
               placeholder="For example: Electronics, Furniture"
               required>

        <label for="description">Description</label>
        <textarea id="description"
                  name="description"
                  rows="3"
                  maxlength="5000"
                  placeholder="Describe the items in your cargo"></textarea>

        <label for="weightKg">Weight (kg) *</label>
        <input type="number"
               id="weightKg"
               name="weightKg"
               min="0.01"
               max="99999999.99"
               step="0.01"
               required>

        <label for="quantity">Quantity *</label>
        <input type="number"
               id="quantity"
               name="quantity"
               min="1"
               step="1"
               value="1"
               required>

        <div class="checkbox-row">
            <input type="checkbox" id="fragile" name="fragile">
            <label for="fragile" style="margin-top: 0;">
                Fragile cargo
            </label>
        </div>

        <button class="save-button" type="submit">
            Register Cargo
        </button>
    </form>

    <hr style="margin-top: 30px;">

    <h2>My Registered Cargo</h2>

    <% if (cargoList == null || cargoList.isEmpty()) { %>
        <p>You haven't registered any cargo yet.</p>
    <% } else {
        for (Cargo item : cargoList) { %>

            <div class="cargo-card">
                <h3><%= escapeHtml(item.type) %></h3>

                <p>
                    <strong>Cargo ID:</strong>
                    <%= item.id %>
                </p>

                <p>
                    <strong>Description:</strong>
                    <%= escapeHtml(item.description) %>
                </p>

                <p>
                    <strong>Weight:</strong>
                    <%= item.weight == null ? "" : item.weight.toPlainString() %>
                    kg
                </p>

                <p>
                    <strong>Quantity:</strong>
                    <%= item.quantity %>
                </p>

                <p>
                    <strong>Fragile:</strong>
                    <%= item.fragile ? "Yes" : "No" %>
                </p>

                <p>
                    <strong>Registered:</strong>
                    <%= escapeHtml(item.createdAt) %>
                </p>

                <form action="<%= request.getContextPath() %>/customer/cargo"
                      method="post"
                      onsubmit="return confirm('Delete this cargo record?');">

                    <input type="hidden" name="action" value="delete">

                    <input type="hidden" name="cargoId"
                           value="<%= item.id %>">

                    <button class="delete-button" type="submit">
                        Delete Cargo
                    </button>
                </form>
            </div>

    <%  }
       }
    %>

    <a class="back"
       href="<%= request.getContextPath() %>/customer/dashboard.jsp">
        Back to Customer Dashboard
    </a>

</div>
</body>
</html>
