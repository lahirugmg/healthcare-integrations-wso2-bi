import ballerinax/mysql;

// FTP server configuration - keeping configurable credentials for Config.toml
configurable string ftpHost = "127.0.0.1";
configurable int ftpPort = 21;
configurable string ftpUsername = "";
configurable string ftpPassword = "";
configurable string ftpDirectory = "/";

// MySQL database configuration with values from Config.toml
configurable string dbHost = "localhost";
configurable int dbPort = 3306;
configurable string dbUsername = "root";
configurable string dbPassword = "root";
configurable string dbName = "blueriver";

// Initialize MySQL client at module level
mysql:Client dbClient = check new (host = dbHost, port = dbPort, user = dbUsername, password = dbPassword, database = dbName);