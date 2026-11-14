package com.cargo.model;

public class Driver {
    private int driverId;
    private int userId;
    private String driverName;
    private String phone;
    private String licenseNumber;
    private int experienceYears;
    private String status; // AVAILABLE, ASSIGNED, INACTIVE

    // Joined fields from users and vehicles table
    private String username;
    private String email;
    private String vehicleNumber;
    private String vehicleModel;
    private java.sql.Timestamp createdAt;

    public Driver() {}

    public Driver(int driverId, int userId, String driverName, String phone, String licenseNumber, int experienceYears, String status) {
        this.driverId = driverId;
        this.userId = userId;
        this.driverName = driverName;
        this.phone = phone;
        this.licenseNumber = licenseNumber;
        this.experienceYears = experienceYears;
        this.status = status;
    }

    public int getDriverId() {
        return driverId;
    }

    public void setDriverId(int driverId) {
        this.driverId = driverId;
    }

    public int getUserId() {
        return userId;
    }

    public void setUserId(int userId) {
        this.userId = userId;
    }

    public String getDriverName() {
        return driverName;
    }

    public void setDriverName(String driverName) {
        this.driverName = driverName;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getLicenseNumber() {
        return licenseNumber;
    }

    public void setLicenseNumber(String licenseNumber) {
        this.licenseNumber = licenseNumber;
    }

    public int getExperienceYears() {
        return experienceYears;
    }

    public void setExperienceYears(int experienceYears) {
        this.experienceYears = experienceYears;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getVehicleNumber() {
        return vehicleNumber;
    }

    public void setVehicleNumber(String vehicleNumber) {
        this.vehicleNumber = vehicleNumber;
    }

    public String getVehicleModel() {
        return vehicleModel;
    }

    public void setVehicleModel(String vehicleModel) {
        this.vehicleModel = vehicleModel;
    }

    public java.sql.Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(java.sql.Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}
