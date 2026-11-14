package com.cargo.util;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.ResultSet;
import java.sql.SQLException;

public class TestConnection {

    public static void main(String[] args) {
        System.out.println("Testing MySQL connection via DBConnection...");

        try (Connection con = DBConnection.getConnection()) {
            if (con != null && !con.isClosed()) {
                DatabaseMetaData meta = con.getMetaData();
                System.out.println("SUCCESS: Database connected successfully!");
                System.out.println("Database Product: " + meta.getDatabaseProductName() + " " + meta.getDatabaseProductVersion());
                System.out.println("Driver Name: " + meta.getDriverName() + " " + meta.getDriverVersion());
                System.out.println("Connected to Catalog: " + con.getCatalog());

                // List tables to verify permissions
                try (ResultSet rs = meta.getTables(con.getCatalog(), null, "%", new String[]{"TABLE"})) {
                    System.out.println("Tables found in database:");
                    int count = 0;
                    while (rs.next()) {
                        System.out.println("  - " + rs.getString("TABLE_NAME"));
                        count++;
                    }
                    System.out.println("Total tables verified: " + count);
                }
            } else {
                System.out.println("FAILED: Connection is null or closed.");
            }
        } catch (SQLException e) {
            System.err.println("FAILED: MySQL connection error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}