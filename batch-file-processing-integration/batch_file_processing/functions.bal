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

// Function to pad number with leading zeros
public function padWithZeros(int number, int width) returns string {
    string numStr = number.toString();
    int padding = width - numStr.length();
    
    if padding <= 0 {
        return numStr;
    }
    
    string paddedStr = "";
    int i = 0;
    while i < padding {
        paddedStr = paddedStr + "0";
        i = i + 1;
    }
    
    return paddedStr + numStr;
}

// Function to format decimal seconds
public function formatSeconds(decimal? seconds) returns string {
    decimal secondValue = seconds ?: 0.0d;
    int wholePart = <int>secondValue;
    return padWithZeros(wholePart, 2);
}

// Function to convert ISO 8601 datetime to MySQL compatible format
public function formatDateTimeForMySQL(string dateTimeString) returns string|error {
    // Handle date-only format (YYYY-MM-DD)
    if dateTimeString.length() == 10 && !dateTimeString.includes("T") {
        return dateTimeString + " 00:00:00";
    }
    
    // Handle ISO 8601 datetime format
    time:Utc|time:Error utcTime = time:utcFromString(dateTimeString);
    
    if utcTime is time:Error {
        // If parsing fails, try to handle it as a simple date
        return dateTimeString.length() == 10 ? dateTimeString + " 00:00:00" : dateTimeString;
    }
    
    time:Civil|time:Error civilTime = time:utcToCivil(utcTime);
    
    if civilTime is time:Error {
        return dateTimeString;
    }
    
    // Format as MySQL datetime: YYYY-MM-DD HH:MM:SS
    string year = civilTime.year.toString();
    string month = padWithZeros(civilTime.month, 2);
    string day = padWithZeros(civilTime.day, 2);
    string hour = padWithZeros(civilTime.hour, 2);
    string minute = padWithZeros(civilTime.minute, 2);
    string second = formatSeconds(civilTime.second);
    
    string formattedDateTime = string `${year}-${month}-${day} ${hour}:${minute}:${second}`;
    
    return formattedDateTime;
}

// Function to convert Clinician to ClinicianContact for database insertion
public function convertToClinicianContact(Clinician clinician, string sourceFile) returns ClinicianContact|error {
    time:Utc currentTime = time:utcNow();
    time:Civil|time:Error civilResult = time:utcToCivil(currentTime);
    
    if civilResult is time:Error {
        return error("Failed to convert current time to civil time");
    }
    
    time:Civil currentCivil = civilResult;
    
    string currentYear = currentCivil.year.toString();
    string currentMonth = padWithZeros(currentCivil.month, 2);
    string currentDay = padWithZeros(currentCivil.day, 2);
    string currentHour = padWithZeros(currentCivil.hour, 2);
    string currentMinute = padWithZeros(currentCivil.minute, 2);
    string currentSecond = formatSeconds(currentCivil.second);
    
    string currentTimestamp = string `${currentYear}-${currentMonth}-${currentDay} ${currentHour}:${currentMinute}:${currentSecond}`;
    
    // Format datetime fields for MySQL compatibility
    string formattedEffectiveFrom = check formatDateTimeForMySQL(clinician.effectiveFrom);
    string formattedUpdatedAt = check formatDateTimeForMySQL(clinician.updatedAt);
    
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
        effective_from: formattedEffectiveFrom,
        updated_at: formattedUpdatedAt,
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
        ClinicianContact|error contactDataResult = convertToClinicianContact(clinician, sourceFile);
        
        if contactDataResult is error {
            string errorMsg = string `Failed to convert clinician data for ${clinician.clinicianId}: ${contactDataResult.message()}`;
            result.errors.push(errorMsg);
            result.errorCount += 1;
            io:println(string `✗ ${errorMsg}`);
            continue;
        }
        
        ClinicianContact contactData = contactDataResult;
        
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