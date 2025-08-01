// Database configuration from Config.toml [healthcare_integration.healthcare_integration.db] section
configurable DatabaseConfig db = ?;

// Twilio configuration from Config.toml [healthcare_integration.healthcare_integration.twilio] section  
configurable TwilioConfig twilio = ?;

// Get database configuration
public isolated function getDatabaseConfig() returns DatabaseConfig {
    return db;
}

// Get Twilio configuration
public isolated function getTwilioConfig() returns TwilioConfig {
    return twilio;
}