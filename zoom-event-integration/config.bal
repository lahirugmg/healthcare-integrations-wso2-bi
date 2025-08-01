// Database configuration from Config.toml [healthcare_integration.healthcare_integration.db] section
configurable DatabaseConfig db = ?;

// Get database configuration
public isolated function getDatabaseConfig() returns DatabaseConfig {
    return db;
}
