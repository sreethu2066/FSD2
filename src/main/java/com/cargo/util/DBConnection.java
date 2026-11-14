package com.cargo.util;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Database Connection Utility for Cargo Transportation Management System.
 * Connects to the MySQL database 'cargo_db' using configured credentials.
 */
public class DBConnection {

    private static String url = "jdbc:mysql://localhost:3306/cargo_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
    private static String user = "root";
    private static String password = "YOUR_MYSQL_PASSWORD";
    private static String driver = "com.mysql.cj.jdbc.Driver";

    static {
        loadConfiguration();
    }

    public static synchronized void loadConfiguration() {
        // 1. Attempt to load from db.properties in classpath
        try (InputStream in = DBConnection.class.getClassLoader().getResourceAsStream("db.properties")) {
            if (in != null) {
                Properties props = new Properties();
                props.load(in);
                if (props.getProperty("db.url") != null && !props.getProperty("db.url").trim().isEmpty()) {
                    url = props.getProperty("db.url").trim();
                }
                if (props.getProperty("db.user") != null && !props.getProperty("db.user").trim().isEmpty()) {
                    user = props.getProperty("db.user").trim();
                }
                if (props.getProperty("db.password") != null) {
                    password = props.getProperty("db.password").trim();
                }
                if (props.getProperty("db.driver") != null && !props.getProperty("db.driver").trim().isEmpty()) {
                    driver = props.getProperty("db.driver").trim();
                }
            }
        } catch (Exception e) {
            System.err.println("Notice: db.properties could not be loaded from classpath, using defaults: " + e.getMessage());
        }

        // 2. Override with system environment variables if present
        String envUrl = System.getenv("DB_URL");
        String envUser = System.getenv("DB_USER");
        String envPass = System.getenv("DB_PASSWORD");
        if (envUrl != null && !envUrl.trim().isEmpty()) url = envUrl.trim();
        if (envUser != null && !envUser.trim().isEmpty()) user = envUser.trim();
        if (envPass != null) password = envPass.trim();

        // 3. Register JDBC driver
        try {
            Class.forName(driver);
        } catch (ClassNotFoundException e) {
            System.err.println("Fatal: MySQL JDBC driver not found on classpath: " + driver);
            throw new RuntimeException("MySQL JDBC driver not found: " + driver, e);
        }
    }

    /**
     * Obtains an active connection to the cargo_db database.
     * @return Connection instance
     * @throws SQLException with descriptive troubleshooting message if connection fails
     */
    public static Connection getConnection() throws SQLException {
        try {
            return DriverManager.getConnection(url, user, password);
        } catch (SQLException e) {
            System.err.println("Database connection failed. URL: " + url + ", User: " + user + ". Error: " + e.getMessage());
            throw new SQLException(
                "Unable to connect to MySQL database 'cargo_db'. " +
                "Please verify that: " +
                "1) MySQL service is running on localhost:3306. " +
                "2) Database 'cargo_db' exists. " +
                "3) Credentials in src/main/resources/db.properties are correct. Original error: " + e.getMessage(), e);
        }
    }

    public static String getUrl() { return url; }
    public static String getUser() { return user; }
}
