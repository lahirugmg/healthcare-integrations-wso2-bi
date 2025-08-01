import ballerina/ftp;

// FTP server configuration
configurable string ftpHost = "127.0.0.1";
configurable int ftpPort = 21;
configurable string ftpUsername = "";
configurable string ftpPassword = "";
configurable string ftpDirectory = "/";

// Create FTP client configuration
public function getFtpClientConfig() returns ftp:ClientConfiguration {
    ftp:ClientConfiguration clientConfig = {
        protocol: ftp:FTP,
        host: ftpHost,
        port: ftpPort
    };
    
    // Authentication configuration structure is not available in the provided API documentation
    // The FTP server needs to be configured to allow the connection
    // or the authentication might need to be handled differently
    
    return clientConfig;
}