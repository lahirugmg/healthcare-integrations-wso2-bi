// Configuration record for FTP connection
public type FtpConfig record {|
    string host;
    int port;
    string username?;
    string password?;
|};

// Record to represent processed file information
public type ProcessedFile record {|
    string fileName;
    json content;
    boolean success;
    string? errorMessage;
|};