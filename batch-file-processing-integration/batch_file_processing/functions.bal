import ballerina/ftp;
import ballerina/io;
import ballerina/lang.value as value;

// Function to check if a file is a JSON file
public function isJsonFile(string fileName) returns boolean {
    return fileName.endsWith(".json");
}

// Function to convert byte stream to string
public function convertBytesToString(stream<byte[] & readonly, io:Error?> byteStream) returns string|error {
    byte[] bytes = [];
    
    error? result = byteStream.forEach(function(byte[] & readonly chunk) {
        foreach byte b in chunk {
            bytes.push(b);
        }
    });
    
    if result is error {
        return result;
    }
    
    return string:fromBytes(bytes);
}

// Function to process clinician data and print each object
public function processClinicianData(json jsonContent) returns error? {
    // Convert JSON to Clinician array
    Clinician[]|error clinicians = jsonContent.cloneWithType();
    
    if clinicians is error {
        return error(string `Failed to parse clinician data: ${clinicians.message()}`);
    }
    
    int clinicianCount = clinicians.length();
    io:println(string `Found ${clinicianCount} clinician records`);
    io:println("========================================");
    
    // Process and print each clinician object
    int index = 1;
    foreach Clinician clinician in clinicians {
        io:println(string `Clinician #${index}:`);
        io:println(string `  Clinician ID: ${clinician.clinicianId}`);
        io:println(string `  NPI: ${clinician.npi}`);
        
        string? middleName = clinician.middleName;
        string fullName = middleName is string ? 
            string `${clinician.firstName} ${middleName} ${clinician.lastName}` : 
            string `${clinician.firstName} ${clinician.lastName}`;
        io:println(string `  Full Name: ${fullName}`);
        
        io:println(string `  Email: ${clinician.email}`);
        io:println(string `  Mobile Phone: ${clinician.phoneMobile}`);
        io:println(string `  Office Phone: ${clinician.phoneOffice}`);
        
        string? pager = clinician.pager;
        if pager is string {
            io:println(string `  Pager: ${pager}`);
        }
        
        io:println(string `  Department: ${clinician.department}`);
        io:println(string `  Specialty: ${clinician.specialty}`);
        io:println(string `  Facility Code: ${clinician.facilityCode}`);
        io:println(string `  Facility Name: ${clinician.facilityName}`);
        io:println(string `  Status: ${clinician.status}`);
        io:println(string `  Effective From: ${clinician.effectiveFrom}`);
        io:println(string `  Updated At: ${clinician.updatedAt}`);
        io:println("----------------------------------------");
        
        index += 1;
    }
    
    return;
}

// Function to process a single JSON file
public function processJsonFile(ftp:Client ftpClient, string filePath, string fileName) returns ProcessedFile {
    ProcessedFile processedFile = {
        fileName: fileName,
        content: {},
        success: false,
        errorMessage: ()
    };
    
    // Get file content from FTP
    stream<byte[] & readonly, io:Error?>|ftp:Error fileStream = ftpClient->get(path = filePath);
    
    if fileStream is ftp:Error {
        string errorMsg = fileStream.message();
        processedFile.errorMessage = string `Failed to retrieve file ${fileName}: ${errorMsg}`;
        return processedFile;
    }
    
    // Convert byte stream to string
    string|error fileContent = convertBytesToString(fileStream);
    
    if fileContent is error {
        string errorMsg = fileContent.message();
        processedFile.errorMessage = string `Failed to convert file content to string: ${errorMsg}`;
        return processedFile;
    }
    
    // Parse JSON content
    json|error jsonContent = value:fromJsonString(fileContent);
    
    if jsonContent is error {
        string errorMsg = jsonContent.message();
        processedFile.errorMessage = string `Failed to parse JSON content: ${errorMsg}`;
        return processedFile;
    }
    
    processedFile.content = jsonContent;
    processedFile.success = true;
    
    return processedFile;
}

// Function to filter JSON files from file list
public function filterJsonFiles(ftp:FileInfo[] fileList) returns ftp:FileInfo[] {
    ftp:FileInfo[] jsonFiles = [];
    
    foreach ftp:FileInfo fileInfo in fileList {
        boolean isFile = fileInfo.isFile;
        string fileName = fileInfo.name;
        if isFile && isJsonFile(fileName) {
            jsonFiles.push(fileInfo);
        }
    }
    
    return jsonFiles;
}