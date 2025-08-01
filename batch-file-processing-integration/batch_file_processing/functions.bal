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