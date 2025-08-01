import ballerina/ftp;
import ballerina/io;

public function main() returns error? {
    io:println("Starting clinician contact data processing and database insertion...");

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
    io:println(string `Database: ${dbName} on ${dbHost}:${dbPort}`);
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

    // Process each JSON file and insert data into database
    int totalSuccessCount = 0;
    int totalErrorCount = 0;
    int filesProcessed = 0;
    int filesWithErrors = 0;

    foreach ftp:FileInfo fileInfo in jsonFiles {
        string fileName = fileInfo.name;
        string filePath = fileInfo.path;
        io:println(string `Processing clinician data file: ${fileName}`);

        ProcessedFile result = processJsonFile(ftpClient, filePath, fileName);

        if result.success {
            io:println(string `✓ Successfully loaded: ${result.fileName}`);

            // Insert clinician data into database
            InsertionResult insertionResult = insertClinicianData(result.content, fileName);

            if insertionResult.errorCount > 0 {
                io:println(string `✗ Database insertion errors for file: ${result.fileName}`);
                foreach string errorMsg in insertionResult.errors {
                    io:println(string `  Error: ${errorMsg}`);
                }
                filesWithErrors += 1;
            } else {
                io:println(string `✓ Successfully inserted all records from: ${result.fileName}`);
                filesProcessed += 1;
            }

            totalSuccessCount += insertionResult.successCount;
            totalErrorCount += insertionResult.errorCount;

        } else {
            io:println(string `✗ Failed to load: ${result.fileName}`);
            string? errorMessage = result.errorMessage;
            string errorMsg = errorMessage ?: "Unknown error";
            io:println(string `Error: ${errorMsg}`);
            filesWithErrors += 1;
        }

        io:println("========================================");
    }

    // Print summary
    io:println("PROCESSING SUMMARY:");
    io:println(string `Total JSON files: ${jsonFileCount}`);
    io:println(string `Files successfully processed: ${filesProcessed}`);
    io:println(string `Files with errors: ${filesWithErrors}`);
    io:println(string `Total clinician records inserted: ${totalSuccessCount}`);
    io:println(string `Total insertion errors: ${totalErrorCount}`);
    io:println("Clinician data processing and database insertion completed.");

    // Close database connection
    error? closeResult = dbClient.close();
    if closeResult is error {
        io:println(string `Warning: Failed to close database connection: ${closeResult.message()}`);
    }
}