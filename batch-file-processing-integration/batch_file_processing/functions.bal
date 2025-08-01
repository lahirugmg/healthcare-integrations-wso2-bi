import ballerina/ftp;
import ballerina/io;
import ballerina/lang.value as value;
import ballerina/time;
import ballerina/sql;

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

// Function to convert Clinician to ClinicianContact for database insertion
public function convertToClinicianContact(Clinician clinician, string sourceFile) returns ClinicianContact {
    time:Utc currentTime = time:utcNow();
    string currentTimestamp = time:utcToString(currentTime);
    
    return {
        clinician_id: clinician.clinicianId,
        npi: clinician.npi,
        first_name: clinician.firstName,
        middle_name: clinician.middleName,
        last_name: clinician.lastName,
        email: clinician.email,
        phone_mobile: clinician.phoneMobile,
        phone_office: clinician.phoneOffice,
        pager: clinician.pager,
        department: clinician.department,
        specialty: clinician.specialty,
        facility_code: clinician.facilityCode,
        facility_name: clinician.facilityName,
        status: clinician.status,
        effective_from: clinician.effectiveFrom,
        updated_at: clinician.updatedAt,
        source_file: sourceFile,
        last_ingested_at: currentTimestamp
    };
}

// Function to insert clinician contact data into MySQL database
public function insertClinicianData(json jsonContent, string sourceFile) returns InsertionResult {
    InsertionResult result = {
        successCount: 0,
        errorCount: 0,
        errors: []
    };
    
    // Convert JSON to Clinician array
    Clinician[]|error clinicians = jsonContent.cloneWithType();
    
    if clinicians is error {
        string errorMsg = string `Failed to parse clinician data: ${clinicians.message()}`;
        result.errors.push(errorMsg);
        result.errorCount = 1;
        return result;
    }
    
    int clinicianCount = clinicians.length();
    io:println(string `Found ${clinicianCount} clinician records to insert`);
    
    // Process and insert each clinician record
    foreach Clinician clinician in clinicians {
        ClinicianContact contactData = convertToClinicianContact(clinician, sourceFile);
        
        // Prepare INSERT statement
        sql:ParameterizedQuery insertQuery = `
            INSERT INTO clinician_contact (
                clinician_id, npi, first_name, middle_name, last_name, email,
                phone_mobile, phone_office, pager, department, specialty,
                facility_code, facility_name, status, effective_from, updated_at,
                source_file, last_ingested_at
            ) VALUES (
                ${contactData.clinician_id}, ${contactData.npi}, ${contactData.first_name},
                ${contactData.middle_name}, ${contactData.last_name}, ${contactData.email},
                ${contactData.phone_mobile}, ${contactData.phone_office}, ${contactData.pager},
                ${contactData.department}, ${contactData.specialty}, ${contactData.facility_code},
                ${contactData.facility_name}, ${contactData.status}, ${contactData.effective_from},
                ${contactData.updated_at}, ${contactData.source_file}, ${contactData.last_ingested_at}
            )
        `;
        
        // Execute INSERT statement
        sql:ExecutionResult|sql:Error insertResult = dbClient->execute(insertQuery);
        
        if insertResult is sql:Error {
            string errorMsg = string `Failed to insert clinician ${contactData.clinician_id}: ${insertResult.message()}`;
            result.errors.push(errorMsg);
            result.errorCount += 1;
            io:println(string `✗ ${errorMsg}`);
        } else {
            result.successCount += 1;
            io:println(string `✓ Inserted clinician: ${contactData.clinician_id} (${contactData.first_name} ${contactData.last_name})`);
        }
    }
    
    return result;
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