import ballerina/ftp;
import ballerina/io;
import ballerina/lang.value as value;

// Initialize FTP client at module level
ftp:Client ftpClient = check new (getFtpClientConfig());

public function main() returns error? {
    io:println("Starting batch JSON file processing from FTP location...");
    io:println(string `FTP Server: ${ftpHost}:${ftpPort}`);
    io:println(string `Directory: ${ftpDirectory}`);
    io:println("----------------------------------------");
    
    // List files in the FTP directory
    ftp:FileInfo[]|ftp:Error fileListResult = ftpClient->list(path = ftpDirectory);
    
    if fileListResult is ftp:Error {
        string errorMsg = fileListResult.message();
        return error(string `Failed to list files from FTP directory: ${errorMsg}`);
    }
    
    ftp:FileInfo[] allFiles = fileListResult;
    int totalFiles = allFiles.length();
    io:println(string `Found ${totalFiles} total files in directory`);
    
    // Filter JSON files
    ftp:FileInfo[] jsonFiles = filterJsonFiles(allFiles);
    int jsonFileCount = jsonFiles.length();
    io:println(string `Found ${jsonFileCount} JSON files to process`);
    
    if jsonFileCount == 0 {
        io:println("No JSON files found to process.");
        return;
    }
    
    io:println("----------------------------------------");
    
    // Process each JSON file
    int successCount = 0;
    int errorCount = 0;
    
    foreach ftp:FileInfo fileInfo in jsonFiles {
        string fileName = fileInfo.name;
        string filePath = fileInfo.path;
        io:println(string `Processing file: ${fileName}`);
        
        ProcessedFile result = processJsonFile(ftpClient, filePath, fileName);
        
        if result.success {
            io:println(string `✓ Successfully processed: ${result.fileName}`);
            io:println("File Content:");
            string jsonString = value:toJsonString(result.content);
            io:println(jsonString);
            successCount += 1;
        } else {
            io:println(string `✗ Failed to process: ${result.fileName}`);
            string? errorMessage = result.errorMessage;
            string errorMsg = errorMessage ?: "Unknown error";
            io:println(string `Error: ${errorMsg}`);
            errorCount += 1;
        }
        
        io:println("----------------------------------------");
    }
    
    // Print summary
    io:println("PROCESSING SUMMARY:");
    io:println(string `Total JSON files: ${jsonFileCount}`);
    io:println(string `Successfully processed: ${successCount}`);
    io:println(string `Failed to process: ${errorCount}`);
    io:println("Batch processing completed.");
}