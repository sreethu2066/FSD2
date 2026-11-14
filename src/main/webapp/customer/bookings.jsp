
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="com.cargo.controller.BookingServlet.CargoOption" %>
<%@ page import="com.cargo.controller.BookingServlet.AddressOption" %>
<%@ page import="com.cargo.controller.BookingServlet.Booking" %>

<%
    if (session.getAttribute("userId") == null ||
        !"CUSTOMER".equals(session.getAttribute("role"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    if (request.getAttribute("bookingList") == null) {
        response.sendRedirect(request.getContextPath() + "/customer/bookings");
        return;
    }

    String ctx = request.getContextPath();

    List<CargoOption> cargoList =
        (List<CargoOption>) request.getAttribute("cargoList");
    List<AddressOption> addressList =
        (List<AddressOption>) request.getAttribute("addressList");
    List<Booking> bookingList =
        (List<Booking>) request.getAttribute("bookingList");

    if (cargoList == null) cargoList = new java.util.ArrayList<>();
    if (addressList == null) addressList = new java.util.ArrayList<>();
    if (bookingList == null) bookingList = new java.util.ArrayList<>();

    String today = LocalDate.now().toString();
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>My Bookings | Cargo Transport</title>

<style>
* { box-sizing: border-box; }

body {
    margin: 0;
    font-family: Arial, sans-serif;
    background: #f1f5f9;
    color: #1e293b;
}

.navbar {
    background: #0f172a;
    color: white;
    padding: 18px 6%;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 12px;
}

.navbar h2 { margin: 0; }

.navbar a {
    color: white;
    text-decoration: none;
    margin-left: 15px;
}

.container {
    width: 92%;
    max-width: 1200px;
    margin: 30px auto;
}

.subtitle { color: #64748b; }

.card {
    background: white;
    padding: 25px;
    margin: 24px 0;
    border-radius: 12px;
    box-shadow: 0 4px 15px rgba(0,0,0,.05);
}

.card h2 { margin-top: 0; }

.form-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 18px;
}

.field {
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.full { grid-column: 1 / -1; }

label { font-weight: bold; font-size: 14px; }

input, select {
    width: 100%;
    padding: 12px;
    border: 1px solid #cbd5e1;
    border-radius: 7px;
    background: white;
    font-size: 14px;
}

button, .btn {
    display: inline-block;
    padding: 11px 16px;
    border: none;
    border-radius: 7px;
    background: #2563eb;
    color: white;
    text-decoration: none;
    font-weight: bold;
    cursor: pointer;
}

button:disabled {
    background: #94a3b8;
    cursor: not-allowed;
}

.cancel-btn { background: #dc2626; }

.table-wrap { overflow-x: auto; }

table {
    width: 100%;
    min-width: 850px;
    border-collapse: collapse;
}

th, td {
    padding: 13px 10px;
    text-align: left;
    border-bottom: 1px solid #e2e8f0;
    font-size: 14px;
}

th { background: #f8fafc; }

.status {
    display: inline-block;
    padding: 6px 9px;
    border-radius: 15px;
    background: #e2e8f0;
    font-size: 12px;
    font-weight: bold;
}

.pending { background: #fef3c7; color: #92400e; }
.confirmed { background: #dbeafe; color: #1d4ed8; }
.cancelled { background: #fee2e2; color: #991b1b; }
.completed { background: #dcfce7; color: #166534; }

.notice {
    background: #eff6ff;
    color: #1e40af;
    padding: 14px;
    margin: 15px 0;
    border-radius: 7px;
}

.empty {
    text-align: center;
    color: #64748b;
    padding: 25px;
}

.small {
    font-size: 13px;
    color: #64748b;
}

@media (max-width: 650px) {
    .form-grid { grid-template-columns: 1fr; }
    .full { grid-column: auto; }
    .card { padding: 17px; }
}
</style>
</head>

<body>

<header class="navbar">
    <h2>Cargo Transport</h2>
    <nav>
        <a href="<%= ctx %>/customer/dashboard.jsp">Dashboard</a>
        <a href="<%= ctx %>/customer/profile">Profile</a>
        <a href="<%= ctx %>/logout">Logout</a>
    </nav>
</header>

<main class="container">

    <h1>My Bookings</h1>
    <p class="subtitle">Create transport bookings and manage your requests.</p>

    <section class="card">
        <h2>Create a Transport Booking</h2>

        <% if (cargoList.isEmpty()) { %>
            <div class="notice">
                No cargo was loaded for this account. Add cargo first.
            </div>
            <a class="btn" href="<%= ctx %>/customer/cargo">Manage Cargo</a>
        <% } %>

        <% if (addressList.size() < 2) { %>
            <div class="notice">
                You need at least two saved addresses for pickup and delivery.
            </div>
            <a class="btn" href="<%= ctx %>/customer/addresses">
                Manage Addresses
            </a>
        <% } %>

        <% if (!cargoList.isEmpty() && addressList.size() >= 2) { %>

        <form action="<%= ctx %>/customer/bookings" method="post">
            <input type="hidden" name="action" value="create">

            <div class="form-grid">

                <div class="field full">
                    <label for="cargoId">Select Cargo</label>
                    <select id="cargoId" name="cargoId" required>
                        <option value="">-- Select Cargo --</option>
                        <% for (CargoOption c : cargoList) { %>
                            <option value="<%= c.id %>">
                                Cargo #<%= c.id %> -
                                <%= c.type %> -
                                <%= c.weight %> kg -
                                Quantity: <%= c.quantity %>
                            </option>
                        <% } %>
                    </select>
                </div>

                <div class="field">
                    <label for="pickupAddressId">Pickup Address</label>
                    <select id="pickupAddressId" name="pickupAddressId" required>
                        <option value="">-- Select Pickup Address --</option>
                        <% for (AddressOption a : addressList) { %>
                            <option value="<%= a.id %>">
                                <%= a.type %> - <%= a.line %>,
                                <%= a.city %>, <%= a.state %> - <%= a.pincode %>
                            </option>
                        <% } %>
                    </select>
                </div>

                <div class="field">
                    <label for="deliveryAddressId">Delivery Address</label>
                    <select id="deliveryAddressId"
                            name="deliveryAddressId" required>
                        <option value="">-- Select Delivery Address --</option>
                        <% for (AddressOption a : addressList) { %>
                            <option value="<%= a.id %>">
                                <%= a.type %> - <%= a.line %>,
                                <%= a.city %>, <%= a.state %> - <%= a.pincode %>
                            </option>
                        <% } %>
                    </select>
                </div>

                <div class="field">
                    <label for="pickupDate">Pickup Date</label>
                    <input type="date" id="pickupDate" name="pickupDate"
                           min="<%= today %>" required>
                </div>

                <div class="field">
                    <label for="expectedDeliveryDate">
                        Expected Delivery Date
                    </label>
                    <input type="date" id="expectedDeliveryDate"
                           name="expectedDeliveryDate"
                           min="<%= today %>" required>
                </div>

                <div class="field full">
                    <label for="totalAmount">Transport Amount (₹)</label>
                    <input type="number" id="totalAmount" name="totalAmount"
                           min="0" step="0.01"
                           placeholder="Enter transport cost" required>
                </div>

            </div>

            <p class="small">
                Select different pickup and delivery addresses.
                The expected delivery date must not precede the pickup date.
            </p>

            <button type="submit">Create Booking</button>
        </form>

        <% } %>
    </section>

    <section class="card">
        <h2>Booking History</h2>

        <% if (bookingList.isEmpty()) { %>
            <div class="empty">No bookings found yet.</div>
        <% } else { %>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>Booking ID</th>
                        <th>Cargo</th>
                        <th>Pickup City</th>
                        <th>Delivery City</th>
                        <th>Pickup Date</th>
                        <th>Expected Delivery</th>
                        <th>Amount</th>
                        <th>Status</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                <% for (Booking b : bookingList) {
                    String statusClass = b.status == null ? ""
                        : b.status.toLowerCase(java.util.Locale.ROOT);
                %>
                    <tr>
                        <td>#<%= b.id %></td>
                        <td><%= b.cargoType %></td>
                        <td><%= b.pickupCity %></td>
                        <td><%= b.deliveryCity %></td>
                        <td><%= b.pickupDate %></td>
                        <td><%= b.expectedDate %></td>
                        <td>₹<%= b.amount %></td>
                        <td>
                            <span class="status <%= statusClass %>">
                                <%= b.status %>
                            </span>
                        </td>
                        <td>
                            <% if ("PENDING".equals(b.status)) { %>
                                <form action="<%= ctx %>/customer/bookings"
                                      method="post"
                                      onsubmit="return confirm('Cancel this booking?');">
                                    <input type="hidden" name="action"
                                           value="cancel">
                                    <input type="hidden" name="bookingId"
                                           value="<%= b.id %>">
                                    <button type="submit" class="cancel-btn">
                                        Cancel
                                    </button>
                                </form>
                            <% } else { %>
                                -
                            <% } %>
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>

        <% } %>
    </section>

</main>

<script>
const pickup = document.getElementById("pickupDate");
const delivery = document.getElementById("expectedDeliveryDate");

if (pickup && delivery) {
    pickup.addEventListener("change", function () {
        delivery.min = pickup.value;

        if (delivery.value && delivery.value < pickup.value) {
            delivery.value = pickup.value;
        }
    });
}

const pickupSelect = document.getElementById("pickupAddressId");
const deliverySelect = document.getElementById("deliveryAddressId");

if (pickupSelect && deliverySelect) {
    pickupSelect.addEventListener("change", function () {
        Array.from(deliverySelect.options).forEach(function (option) {
            option.disabled =
                option.value !== "" && option.value === pickupSelect.value;
        });

        if (deliverySelect.value === pickupSelect.value) {
            deliverySelect.value = "";
        }
    });
}
</script>

</body>
</html>
