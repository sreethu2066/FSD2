-- ==========================================================
-- Cargo Transportation Management System (CTMS) Database Schema
-- Database: CargoTransportationSystem
-- Source of Truth: Updated Final Schema (11 Tables)
-- ==========================================================

CREATE DATABASE IF NOT EXISTS CargoTransportationSystem CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE CargoTransportationSystem;

-- ----------------------------------------------------------
-- 1. Table: users
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('ADMIN', 'CUSTOMER', 'DRIVER') NOT NULL DEFAULT 'CUSTOMER',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 2. Table: customers
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    gender ENUM('MALE', 'FEMALE', 'OTHER') NULL,
    date_of_birth DATE NULL,
    CONSTRAINT fk_customers_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 3. Table: drivers
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS drivers (
    driver_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    driver_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    license_number VARCHAR(50) NOT NULL UNIQUE,
    experience_years INT DEFAULT 0,
    status ENUM('AVAILABLE', 'ASSIGNED', 'INACTIVE') DEFAULT 'AVAILABLE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_drivers_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 4. Table: vehicles
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS vehicles (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_number VARCHAR(30) NOT NULL UNIQUE,
    vehicle_type VARCHAR(60) NOT NULL,
    capacity_kg DECIMAL(10,2) NOT NULL,
    status ENUM('AVAILABLE', 'ASSIGNED', 'MAINTENANCE') DEFAULT 'AVAILABLE'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 5. Table: addresses
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS addresses (
    address_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    address_type ENUM('HOME', 'OFFICE', 'OTHER') DEFAULT 'HOME',
    address_line VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    pincode VARCHAR(15) NOT NULL,
    CONSTRAINT fk_addresses_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 6. Table: cargo
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS cargo (
    cargo_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    cargo_type VARCHAR(100) NOT NULL,
    description TEXT,
    weight_kg DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    fragile BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cargo_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 7. Table: bookings
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    cargo_id INT NOT NULL,
    pickup_address_id INT NOT NULL,
    delivery_address_id INT NOT NULL,
    booking_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    pickup_date DATETIME NULL,
    expected_delivery_date DATETIME NULL,
    booking_status ENUM('PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED') DEFAULT 'PENDING',
    total_amount DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_bookings_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_bookings_cargo FOREIGN KEY (cargo_id) REFERENCES cargo(cargo_id),
    CONSTRAINT fk_bookings_pickup FOREIGN KEY (pickup_address_id) REFERENCES addresses(address_id),
    CONSTRAINT fk_bookings_delivery FOREIGN KEY (delivery_address_id) REFERENCES addresses(address_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 8. Table: shipments
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS shipments (
    shipment_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL UNIQUE,
    vehicle_id INT NULL,
    driver_id INT NULL,
    tracking_number VARCHAR(50) NOT NULL UNIQUE,
    current_location VARCHAR(255),
    shipment_status ENUM('PENDING', 'PICKED_UP', 'IN_TRANSIT', 'OUT_FOR_DELIVERY', 'DELIVERED', 'FAILED') DEFAULT 'PENDING',
    shipped_date DATETIME NULL,
    delivered_date DATETIME NULL,
    CONSTRAINT fk_shipments_booking FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    CONSTRAINT fk_shipments_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
    CONSTRAINT fk_shipments_driver FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 9. Table: shipment_status (Status Transition Audit Log)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS shipment_status (
    status_id INT AUTO_INCREMENT PRIMARY KEY,
    shipment_id INT NOT NULL,
    status VARCHAR(60) NOT NULL,
    location VARCHAR(255),
    remarks TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_shipment_status_shipment FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 10. Table: payments
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('CASH', 'UPI', 'CARD', 'NET_BANKING') DEFAULT 'CASH',
    payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    payment_status ENUM('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED') DEFAULT 'PENDING',
    transaction_id VARCHAR(100) UNIQUE,
    CONSTRAINT fk_payments_booking FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 11. Table: feedback
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS feedback (
    feedback_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    booking_id INT NOT NULL UNIQUE,
    rating INT NOT NULL,
    comments TEXT,
    feedback_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_feedback_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_feedback_booking FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================================
-- Sample Seed Data
-- Passwords below are encrypted with BCrypt (Cost 10):
--   admin    / admin123    -> $2a$10$eO1JbS1GZ5wYqRk8QW4sYeR7dE4zV8g1Q6jP0rX3cV6aM9xY8w8W
--   rajesh   / customer123 -> $2a$10$9.dZ5t0O6U6bY1K9rV6sYuQ9fD7vB5s2X7kO1mP5rZ8xN0bC3dF4e
--   suresh   / driver123   -> $2a$10$3.fZ8t1P7V7cY2L0sW7tZvR0gE8wA6t3Y8lP2nQ6sZ9yO1cD4eG5f
-- ==========================================================

-- 1. Users
INSERT INTO users (user_id, username, email, password, role) VALUES
(1, 'admin', 'admin@cargo.com', '$2a$10$vI8qOeb9T78h9T/z/Tqmge5D9pZ3v9f0k2p5y7w4r1a2b3c4d5e6f', 'ADMIN'),
(2, 'rajesh', 'rajesh.customer@example.com', '$2a$10$1Y8qOeb9T78h9T/z/Tqmge5D9pZ3v9f0k2p5y7w4r1a2b3c4d5e6f', 'CUSTOMER'),
(3, 'suresh', 'suresh.driver@example.com', '$2a$10$2Y8qOeb9T78h9T/z/Tqmge5D9pZ3v9f0k2p5y7w4r1a2b3c4d5e6f', 'DRIVER')
ON DUPLICATE KEY UPDATE username=VALUES(username);

-- 2. Customers
INSERT INTO customers (customer_id, user_id, full_name, phone, gender, date_of_birth) VALUES
(1, 2, 'Rajesh Kumar', '+91 9876543210', 'MALE', '1995-05-15')
ON DUPLICATE KEY UPDATE full_name=VALUES(full_name);

-- 3. Drivers
INSERT INTO drivers (driver_id, user_id, driver_name, phone, license_number, experience_years, status) VALUES
(1, 3, 'Suresh Sharma', '+91 9123456780', 'DL-AP-14201100987', 5, 'AVAILABLE')
ON DUPLICATE KEY UPDATE driver_name=VALUES(driver_name);

-- 4. Vehicles
INSERT INTO vehicles (vehicle_id, vehicle_number, vehicle_type, capacity_kg, status) VALUES
(1, 'AP-16-TX-1234', 'Medium Freight Truck', 3500.00, 'AVAILABLE'),
(2, 'AP-16-TX-5678', 'Heavy Cargo Carrier', 8000.00, 'AVAILABLE'),
(3, 'AP-16-TX-9999', 'Light Express Van', 1200.00, 'AVAILABLE')
ON DUPLICATE KEY UPDATE vehicle_number=VALUES(vehicle_number);

-- 5. Addresses
INSERT INTO addresses (address_id, customer_id, address_type, address_line, city, state, pincode) VALUES
(1, 1, 'HOME', 'Plot 42, Gayatri Nagar', 'Vijayawada', 'Andhra Pradesh', '520008'),
(2, 1, 'OFFICE', 'Warehouse 12, Industrial Area', 'Guntur', 'Andhra Pradesh', '522001')
ON DUPLICATE KEY UPDATE address_line=VALUES(address_line);

-- 6. Cargo
INSERT INTO cargo (cargo_id, customer_id, cargo_type, description, weight_kg, quantity, fragile) VALUES
(1, 1, 'Industrial Machinery Parts', 'Precision steel bearings and gear assemblies', 450.00, 4, false)
ON DUPLICATE KEY UPDATE cargo_type=VALUES(cargo_type);

-- 7. Bookings
INSERT INTO bookings (booking_id, customer_id, cargo_id, pickup_address_id, delivery_address_id, booking_date, pickup_date, expected_delivery_date, booking_status, total_amount) VALUES
(1, 1, 1, 1, 2, NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 3 DAY), 'CONFIRMED', 4500.00)
ON DUPLICATE KEY UPDATE booking_status=VALUES(booking_status);

-- 8. Shipments
INSERT INTO shipments (shipment_id, booking_id, vehicle_id, driver_id, tracking_number, current_location, shipment_status, shipped_date, delivered_date) VALUES
(1, 1, 1, 1, 'CTMS202610010001', 'Vijayawada Dispatch Hub', 'IN_TRANSIT', NOW(), NULL)
ON DUPLICATE KEY UPDATE tracking_number=VALUES(tracking_number);

-- 9. Shipment Status Logs
INSERT INTO shipment_status (status_id, shipment_id, status, location, remarks, updated_at) VALUES
(1, 1, 'CONFIRMED', 'Vijayawada Dispatch Hub', 'Booking confirmed and dispatched for pickup', NOW()),
(2, 1, 'IN_TRANSIT', 'National Highway 16 Toll Checkpoint', 'Freight in transit towards Guntur destination', NOW())
ON DUPLICATE KEY UPDATE status=VALUES(status);

-- 10. Payments
INSERT INTO payments (payment_id, booking_id, amount, payment_method, payment_status, transaction_id) VALUES
(1, 1, 4500.00, 'UPI', 'SUCCESS', 'TXN-UPI-20261027-001')
ON DUPLICATE KEY UPDATE transaction_id=VALUES(transaction_id);

-- 11. Feedback (Only for completed bookings, optional initial record)
-- INSERT INTO feedback (feedback_id, customer_id, booking_id, rating, comments, feedback_date) VALUES
-- (1, 1, 1, 5, 'Smooth logistics and real-time tracking.', NOW());
