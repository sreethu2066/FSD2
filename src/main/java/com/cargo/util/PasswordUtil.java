package com.cargo.util;

import org.mindrot.jbcrypt.BCrypt;
import java.security.SecureRandom;

/**
 * Utility for password hashing, verification, and temporary credential generation.
 * Uses BCrypt with 12 rounds of salting.
 */
public class PasswordUtil {

    private static final String CHAR_LOWER = "abcdefghijklmnopqrstuvwxyz";
    private static final String CHAR_UPPER = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    private static final String NUMBER = "0123456789";
    private static final String SPECIAL = "@#$&*";
    private static final SecureRandom random = new SecureRandom();

    /**
     * Hashes a plain-text password using BCrypt.
     */
    public static String hashPassword(String plainTextPassword) {
        if (plainTextPassword == null || plainTextPassword.isEmpty()) {
            throw new IllegalArgumentException("Password cannot be empty.");
        }
        return BCrypt.hashpw(plainTextPassword, BCrypt.gensalt(12));
    }

    /**
     * Verifies a plain-text password against a stored hash or plain-text legacy value.
     */
    public static boolean verifyPassword(String plainTextPassword, String storedHashOrPassword) {
        if (plainTextPassword == null || storedHashOrPassword == null) {
            return false;
        }

        // Standard BCrypt hash check
        if (storedHashOrPassword.startsWith("$2a$") || storedHashOrPassword.startsWith("$2b$") || storedHashOrPassword.startsWith("$2y$") || storedHashOrPassword.startsWith("$2")) {
            try {
                return BCrypt.checkpw(plainTextPassword, storedHashOrPassword);
            } catch (Exception e) {
                return false;
            }
        }

        // Legacy plain-text fallback
        return plainTextPassword.equals(storedHashOrPassword);
    }

    /**
     * Generates a secure temporary password (e.g. Drv@2026Xk).
     */
    public static String generateTemporaryPassword() {
        StringBuilder sb = new StringBuilder(10);
        sb.append("Drv@");
        for (int i = 0; i < 4; i++) {
            sb.append(NUMBER.charAt(random.nextInt(NUMBER.length())));
        }
        sb.append(CHAR_UPPER.charAt(random.nextInt(CHAR_UPPER.length())));
        sb.append(CHAR_LOWER.charAt(random.nextInt(CHAR_LOWER.length())));
        return sb.toString();
    }

    /**
     * Generates a suggested unique username from a driver's full name.
     */
    public static String generateUsername(String fullName) {
        String clean = fullName == null ? "driver" : fullName.replaceAll("[^a-zA-Z0-9]", "").toLowerCase();
        if (clean.length() > 8) {
            clean = clean.substring(0, 8);
        }
        if (clean.isEmpty()) {
            clean = "driver";
        }
        int num = 100 + random.nextInt(900);
        return "drv_" + clean + "_" + num;
    }
}
