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

// Record to represent clinician contact data
public type Clinician record {|
    string clinicianId;
    string npi;
    string firstName;
    string? middleName;
    string lastName;
    string email;
    string phoneMobile;
    string phoneOffice;
    string? pager;
    string department;
    string specialty;
    string facilityCode;
    string facilityName;
    string status;
    string effectiveFrom;
    string updatedAt;
|};