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

// Record to represent clinician contact data from JSON
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

// Record to represent clinician contact data for database insertion
public type ClinicianContact record {|
    string clinician_id;
    string npi;
    string first_name;
    string? middle_name;
    string last_name;
    string email;
    string phone_mobile;
    string phone_office;
    string? pager;
    string department;
    string specialty;
    string facility_code;
    string facility_name;
    string status;
    string effective_from;
    string updated_at;
    string source_file;
    string last_ingested_at;
|};

// Record to represent database insertion result
public type InsertionResult record {|
    int successCount;
    int errorCount;
    string[] errors;
|};