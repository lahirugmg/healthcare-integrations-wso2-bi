// Database configuration from Config.toml [db] section
configurable DatabaseConfig db = ?;

// Get database configuration
public isolated function getDatabaseConfig() returns DatabaseConfig {
    return db;
}