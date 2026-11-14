
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="com.cargo.controller.AddressServlet.Address" %>

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

    if (request.getAttribute("addresses") == null) {
        response.sendRedirect(request.getContextPath() + "/customer/addresses");
        return;
    }

    List<Address> addresses =
            (List<Address>) request.getAttribute("addresses");

    String saved = request.getParameter("saved");
    String deleted = request.getParameter("deleted");
    String error = request.getParameter("error");
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Addresses</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            font-family: Arial, sans-serif;
            background: #eef3f8;
            margin: 0;
            padding: 30px 15px;
            color: #222;
        }

        .container {
            max-width: 900px;
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

        input, select {
            width: 100%;
            padding: 12px;
            margin-top: 7px;
            border: 1px solid #ccc;
            border-radius: 6px;
            font-size: 16px;
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

        .address-card {
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

    <h1>My Addresses</h1>
    <p>Add and manage your pickup and delivery addresses.</p>

    <% if ("success".equals(saved)) { %>
        <div class="message success">
            Address saved successfully!
        </div>
    <% } %>

    <% if ("success".equals(deleted)) { %>
        <div class="message success">
            Address deleted successfully.
        </div>
    <% } %>

    <% if ("invalid".equals(error)) { %>
        <div class="message error">
            Please check all address details and try again.
        </div>
    <% } %>

    <h2>Add New Address</h2>

    <form action="<%= request.getContextPath() %>/customer/addresses"
          method="post">

        <input type="hidden" name="action" value="add">

        <label for="addressType">Address Type *</label>
        <select id="addressType" name="addressType" required>
            <option value="">Select address type</option>
            <option value="HOME">Home</option>
            <option value="OFFICE">Office</option>
            <option value="OTHER">Other</option>
        </select>

        <label for="addressLine">Address Line *</label>
        <input type="text" id="addressLine" name="addressLine"
               maxlength="255" required
               placeholder="House number, street, area">

        <label for="city">City *</label>
        <input type="text" id="city" name="city"
               maxlength="100" required>

        <label for="state">State *</label>
        <input type="text" id="state" name="state"
               maxlength="100" required>

        <label for="pincode">Pincode *</label>
        <input type="text" id="pincode" name="pincode"
               maxlength="10" required>

        <button class="save-button" type="submit">
            Save Address
        </button>
    </form>

    <hr style="margin-top: 30px;">

    <h2>Saved Addresses</h2>

    <% if (addresses == null || addresses.isEmpty()) { %>
        <p>No addresses saved yet. Add your first address above.</p>
    <% } else {
        for (Address address : addresses) { %>

            <div class="address-card">
                <h3><%= escapeHtml(address.type) %> Address</h3>

                <p>
                    <strong>Address:</strong>
                    <%= escapeHtml(address.addressLine) %>
                </p>

                <p>
                    <strong>City:</strong>
                    <%= escapeHtml(address.city) %>
                </p>

                <p>
                    <strong>State:</strong>
                    <%= escapeHtml(address.state) %>
                </p>

                <p>
                    <strong>Pincode:</strong>
                    <%= escapeHtml(address.pincode) %>
                </p>

                <form action="<%= request.getContextPath() %>/customer/addresses"
                      method="post"
                      onsubmit="return confirm('Delete this address?');">

                    <input type="hidden" name="action" value="delete">

                    <input type="hidden" name="addressId"
                           value="<%= address.id %>">

                    <button class="delete-button" type="submit">
                        Delete Address
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
