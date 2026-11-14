package com.cargo.dao;

import com.cargo.model.Driver;
import com.cargo.model.User;
import com.cargo.util.DBConnection;
import com.cargo.util.PasswordUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Data Access Object for Users and Drivers.
 */
public class UserDAO {

    public User findByUsername(String username) throws SQLException {
        String sql = "SELECT user_id, username, email, password, role, created_at FROM users WHERE username = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRowToUser(rs);
                }
            }
        }
        return null;
    }

    public User findById(int userId) throws SQLException {
        String sql = "SELECT user_id, username, email, password, role, created_at FROM users WHERE user_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRowToUser(rs);
                }
            }
        }
        return null;
    }

    public boolean usernameExists(String username) throws SQLException {
        return checkExists("SELECT 1 FROM users WHERE username = ?", username);
    }

    public boolean emailExists(String email) throws SQLException {
        return checkExists("SELECT 1 FROM users WHERE email = ?", email);
    }

    public boolean licenseExists(String licenseNumber) throws SQLException {
        return checkExists("SELECT 1 FROM drivers WHERE license_number = ?", licenseNumber);
    }

    private boolean checkExists(String sql, String param) throws SQLException {
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, param);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public boolean licenseExistsExcludingDriver(String licenseNumber, int excludeDriverId) throws SQLException {
        String sql = "SELECT 1 FROM drivers WHERE license_number = ? AND driver_id != ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, licenseNumber);
            ps.setInt(2, excludeDriverId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public boolean emailExistsExcludingUser(String email, int excludeUserId) throws SQLException {
        String sql = "SELECT 1 FROM users WHERE email = ? AND user_id != ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, email);
            ps.setInt(2, excludeUserId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public int registerCustomer(String username, String email, String password, String fullName) throws SQLException {
        String insertUserSql = "INSERT INTO users (username, email, password, role) VALUES (?, ?, ?, 'CUSTOMER')";
        String insertCustSql = "INSERT INTO customers (user_id, full_name) VALUES (?, ?)";
        String hashedPassword = PasswordUtil.hashPassword(password);

        try (Connection con = DBConnection.getConnection()) {
            con.setAutoCommit(false);
            try {
                int userId;
                try (PreparedStatement psUser = con.prepareStatement(insertUserSql, Statement.RETURN_GENERATED_KEYS)) {
                    psUser.setString(1, username);
                    psUser.setString(2, email);
                    psUser.setString(3, hashedPassword);
                    psUser.executeUpdate();
                    try (ResultSet rs = psUser.getGeneratedKeys()) {
                        if (!rs.next()) throw new SQLException("Failed to get user_id.");
                        userId = rs.getInt(1);
                    }
                }

                try (PreparedStatement psCust = con.prepareStatement(insertCustSql)) {
                    psCust.setInt(1, userId);
                    psCust.setString(2, (fullName != null && !fullName.trim().isEmpty()) ? fullName.trim() : username);
                    psCust.executeUpdate();
                }

                con.commit();
                return userId;
            } catch (SQLException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    public int registerDriver(String username, String email, String password, String fullName,
                               String phone, String licenseNumber, int experienceYears, String status) throws SQLException {
        String insertUserSql = "INSERT INTO users (username, email, password, role) VALUES (?, ?, ?, 'DRIVER')";
        String insertDriverSql = "INSERT INTO drivers (user_id, driver_name, phone, license_number, experience_years, status) VALUES (?, ?, ?, ?, ?, ?)";
        String hashedPassword = PasswordUtil.hashPassword(password);

        try (Connection con = DBConnection.getConnection()) {
            con.setAutoCommit(false);
            try {
                int userId;
                try (PreparedStatement psUser = con.prepareStatement(insertUserSql, Statement.RETURN_GENERATED_KEYS)) {
                    psUser.setString(1, username);
                    psUser.setString(2, email);
                    psUser.setString(3, hashedPassword);
                    psUser.executeUpdate();
                    try (ResultSet rs = psUser.getGeneratedKeys()) {
                        if (!rs.next()) throw new SQLException("Failed to get user_id.");
                        userId = rs.getInt(1);
                    }
                }

                int driverId;
                try (PreparedStatement psDrv = con.prepareStatement(insertDriverSql, Statement.RETURN_GENERATED_KEYS)) {
                    psDrv.setInt(1, userId);
                    psDrv.setString(2, fullName);
                    psDrv.setString(3, phone);
                    psDrv.setString(4, licenseNumber);
                    psDrv.setInt(5, Math.max(0, experienceYears));
                    psDrv.setString(6, (status != null && !status.trim().isEmpty()) ? status.trim().toUpperCase() : "INACTIVE");
                    psDrv.executeUpdate();
                    try (ResultSet rs = psDrv.getGeneratedKeys()) {
                        if (!rs.next()) throw new SQLException("Failed to get driver_id.");
                        driverId = rs.getInt(1);
                    }
                }

                con.commit();
                return driverId;
            } catch (SQLException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    public boolean updatePassword(int userId, String newHash) throws SQLException {
        String sql = "UPDATE users SET password = ? WHERE user_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, newHash);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean resetDriverPassword(int driverId, String newPlainPassword) throws SQLException {
        String sql = "UPDATE users u JOIN drivers d ON u.user_id = d.user_id SET u.password = ? WHERE d.driver_id = ?";
        String hashed = PasswordUtil.hashPassword(newPlainPassword);
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, hashed);
            ps.setInt(2, driverId);
            return ps.executeUpdate() > 0;
        }
    }

    public Integer getCustomerIdByUserId(int userId) throws SQLException {
        String sql = "SELECT customer_id FROM customers WHERE user_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt("customer_id");
            }
        }
        return null;
    }

    public Integer getDriverIdByUserId(int userId) throws SQLException {
        String sql = "SELECT driver_id FROM drivers WHERE user_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt("driver_id");
            }
        }
        return null;
    }

    public String getDriverStatusByUserId(int userId) throws SQLException {
        String sql = "SELECT status FROM drivers WHERE user_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getString("status");
            }
        }
        return null;
    }

    private static final String DRIVER_SELECT_SQL =
        "SELECT d.driver_id, d.user_id, d.driver_name, d.phone, d.license_number, " +
        "d.experience_years, d.status, d.created_at AS driver_created_at, " +
        "u.username, u.email, u.created_at AS user_created_at, " +
        "v.vehicle_number, v.vehicle_type AS vehicle_model " +
        "FROM drivers d " +
        "JOIN users u ON d.user_id = u.user_id " +
        "LEFT JOIN shipments s ON (d.driver_id = s.driver_id AND s.shipment_status NOT IN ('DELIVERED', 'FAILED')) " +
        "LEFT JOIN vehicles v ON s.vehicle_id = v.vehicle_id ";

    public Driver findDriverByUserId(int userId) throws SQLException {
        String sql = DRIVER_SELECT_SQL + "WHERE d.user_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRowToDriver(rs);
            }
        }
        return null;
    }

    public Driver findDriverById(int driverId) throws SQLException {
        String sql = DRIVER_SELECT_SQL + "WHERE d.driver_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, driverId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRowToDriver(rs);
            }
        }
        return null;
    }

    public List<Map<String, Object>> findAllDriversWithUsers() throws SQLException {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = DRIVER_SELECT_SQL + "ORDER BY d.driver_id DESC";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> map = new HashMap<>();
                map.put("driverId", rs.getInt("driver_id"));
                map.put("userId", rs.getInt("user_id"));
                map.put("name", rs.getString("driver_name"));
                map.put("phone", rs.getString("phone"));
                map.put("licenseNumber", rs.getString("license_number"));
                map.put("experienceYears", rs.getInt("experience_years"));
                map.put("status", rs.getString("status"));
                map.put("username", rs.getString("username"));
                map.put("email", rs.getString("email"));
                map.put("vehicleNumber", rs.getString("vehicle_number"));
                map.put("vehicleModel", rs.getString("vehicle_model"));

                Timestamp ca = rs.getTimestamp("driver_created_at");
                if (ca == null) ca = rs.getTimestamp("user_created_at");
                map.put("createdAt", ca);

                list.add(map);
            }
        }
        return list;
    }

    public boolean updateDriverStatus(int driverId, String status) throws SQLException {
        String sql = "UPDATE drivers SET status = ? WHERE driver_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, driverId);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean updateDriverInfo(int driverId, String name, String email, String phone,
                                    String licenseNumber, int experienceYears, String status) throws SQLException {
        String selectUserSql = "SELECT user_id FROM drivers WHERE driver_id = ?";
        String updateDriverSql = "UPDATE drivers SET driver_name = ?, phone = ?, license_number = ?, experience_years = ?, status = ? WHERE driver_id = ?";
        String updateUserSql = "UPDATE users SET email = ? WHERE user_id = ?";

        try (Connection con = DBConnection.getConnection()) {
            con.setAutoCommit(false);
            try {
                int userId = -1;
                try (PreparedStatement psSelect = con.prepareStatement(selectUserSql)) {
                    psSelect.setInt(1, driverId);
                    try (ResultSet rs = psSelect.executeQuery()) {
                        if (rs.next()) userId = rs.getInt("user_id");
                    }
                }

                if (userId <= 0) {
                    con.rollback();
                    return false;
                }

                try (PreparedStatement psDriver = con.prepareStatement(updateDriverSql)) {
                    psDriver.setString(1, name);
                    psDriver.setString(2, phone);
                    psDriver.setString(3, licenseNumber);
                    psDriver.setInt(4, Math.max(0, experienceYears));
                    psDriver.setString(5, status);
                    psDriver.setInt(6, driverId);
                    psDriver.executeUpdate();
                }

                if (email != null && !email.trim().isEmpty()) {
                    try (PreparedStatement psUser = con.prepareStatement(updateUserSql)) {
                        psUser.setString(1, email.trim().toLowerCase());
                        psUser.setInt(2, userId);
                        psUser.executeUpdate();
                    }
                }

                con.commit();
                return true;
            } catch (SQLException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    public boolean updateDriverSelfProfile(int userId, String phone, String email) throws SQLException {
        String updateDriverSql = "UPDATE drivers SET phone = ? WHERE user_id = ?";
        String updateUserSql = "UPDATE users SET email = ? WHERE user_id = ?";

        try (Connection con = DBConnection.getConnection()) {
            con.setAutoCommit(false);
            try {
                try (PreparedStatement psDriver = con.prepareStatement(updateDriverSql)) {
                    psDriver.setString(1, phone);
                    psDriver.setInt(2, userId);
                    psDriver.executeUpdate();
                }

                try (PreparedStatement psUser = con.prepareStatement(updateUserSql)) {
                    psUser.setString(1, email.trim().toLowerCase());
                    psUser.setInt(2, userId);
                    psUser.executeUpdate();
                }

                con.commit();
                return true;
            } catch (SQLException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    public List<User> findAllUsers() throws SQLException {
        List<User> list = new ArrayList<>();
        String sql = "SELECT user_id, username, email, password, role, created_at FROM users ORDER BY user_id DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapRowToUser(rs));
            }
        }
        return list;
    }

    private User mapRowToUser(ResultSet rs) throws SQLException {
        User u = new User();
        u.setUserId(rs.getInt("user_id"));
        u.setUsername(rs.getString("username"));
        u.setEmail(rs.getString("email"));
        u.setPassword(rs.getString("password"));
        u.setRole(rs.getString("role"));
        u.setCreatedAt(rs.getTimestamp("created_at"));
        return u;
    }

    private Driver mapRowToDriver(ResultSet rs) throws SQLException {
        Driver d = new Driver();
        d.setDriverId(rs.getInt("driver_id"));
        d.setUserId(rs.getInt("user_id"));
        d.setDriverName(rs.getString("driver_name"));
        d.setPhone(rs.getString("phone"));
        d.setLicenseNumber(rs.getString("license_number"));
        d.setExperienceYears(rs.getInt("experience_years"));
        d.setStatus(rs.getString("status"));
        d.setUsername(rs.getString("username"));
        d.setEmail(rs.getString("email"));
        d.setVehicleNumber(rs.getString("vehicle_number"));
        d.setVehicleModel(rs.getString("vehicle_model"));

        Timestamp ca = rs.getTimestamp("driver_created_at");
        if (ca == null) ca = rs.getTimestamp("user_created_at");
        d.setCreatedAt(ca);
        return d;
    }
}
