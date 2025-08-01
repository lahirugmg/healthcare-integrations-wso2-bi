import ballerina/ftp;
import ballerina/io;

public function main() returns error? {
    io:println("Starting clinician contact data processing from FTP location...");

    // FTP client configuration with credentials from Config.toml
    ftp:ClientConfiguration ftpConfig = {
        protocol: ftp:FTP,
        host: "localhost",
        port: 2121,
        auth: {
            credentials: {
                username: ftpUsername,
                password: ftpPassword
            }
        }
    };

    ftp:Client ftpClient = check new (clientConfig = ftpConfig);

    io:println("FTP Server: localhost:2121");
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
        io:println(string `Processing clinician data file: ${fileName}`);

        ProcessedFile result = processJsonFile(ftpClient, filePath, fileName);

        if result.success {
            io:println(string `✓ Successfully loaded: ${result.fileName}`);

            // Process clinician data specifically
            error? clinicianProcessResult = processClinicianData(result.content);

            if clinicianProcessResult is error {
                io:println(string `✗ Failed to process clinician data: ${clinicianProcessResult.message()}`);
                errorCount += 1;
            } else {
                io:println(string `✓ Successfully processed clinician data from: ${result.fileName}`);
                successCount += 1;
            }
        } else {
            io:println(string `✗ Failed to load: ${result.fileName}`);
            string? errorMessage = result.errorMessage;
            string errorMsg = errorMessage ?: "Unknown error";
            io:println(string `Error: ${errorMsg}`);
            errorCount += 1;
        }

        io:println("========================================");
    }

    // Print summary
    io:println("PROCESSING SUMMARY:");
    io:println(string `Total JSON files: ${jsonFileCount}`);
    io:println(string `Successfully processed: ${successCount}`);
    io:println(string `Failed to process: ${errorCount}`);
    io:println("Clinician data processing completed.");
}