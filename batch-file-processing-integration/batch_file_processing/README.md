# FTP JSON Batch File Processing Integration

A Ballerina-based automation system that processes batches of JSON files from FTP locations and inserts clinician contact data into a MySQL database.

## Overview

This integration connects to an FTP server, discovers JSON files containing clinician contact data in a specified directory, downloads and processes each file, then inserts the parsed data into a MySQL database. It's designed for automated batch processing scenarios where JSON files are regularly uploaded to an FTP server and need to be processed and stored in a database systematically.

## Features

- **Automated FTP Connection**: Connects to FTP servers with configurable authentication
- **JSON File Discovery**: Automatically identifies and filters JSON files from FTP directories
- **Batch Processing**: Processes multiple JSON files sequentially
- **Database Integration**: Inserts clinician contact data into MySQL database
- **Error Handling**: Comprehensive error handling for FTP operations, JSON parsing, and database operations
- **Processing Summary**: Provides detailed reports on successful and failed file processing and database insertions
- **Configurable Settings**: Flexible configuration through Config.toml file

## Data Processing Workflow

### 1. JSON File Reading
- **FTP Connection**: Establishes secure connection to FTP server using configured credentials
- **File Discovery**: Scans the specified directory and identifies all `.json` files
- **File Retrieval**: Downloads each JSON file as a byte stream from the FTP server
- **Content Parsing**: Converts byte stream to string and parses as JSON array

### 2. Data Transformation
- **JSON to Record Conversion**: Transforms JSON objects into strongly-typed `Clinician` records
- **Field Mapping**: Maps JSON field names (camelCase) to database column names (snake_case):
  - `clinicianId` → `clinician_id`
  - `firstName` → `first_name`
  - `lastName` → `last_name`
  - `phoneMobile` → `phone_mobile`
  - `phoneOffice` → `phone_office`
  - `facilityCode` → `facility_code`
  - `facilityName` → `facility_name`
  - `effectiveFrom` → `effective_from`
  - `updatedAt` → `updated_at`

### 3. Database Writing Process
- **Metadata Enhancement**: Adds processing metadata to each record:
  - `source_file`: Name of the originating JSON file
  - `last_ingested_at`: Timestamp when the record was processed
- **Parameterized Queries**: Uses SQL parameterized queries to prevent injection attacks
- **Individual Record Processing**: Inserts each clinician record separately with detailed logging
- **Error Isolation**: Failed insertions don't stop processing of remaining records
- **Transaction Safety**: Each INSERT operation is handled as a separate transaction

### 4. Processing Results
- **Real-time Feedback**: Displays success/failure status for each record insertion
- **Comprehensive Logging**: Logs clinician ID, name, and any error messages
- **Summary Statistics**: Provides final counts of successful and failed operations

## Prerequisites

- Ballerina Swan Lake (2201.x.x or later)
- MySQL Server (5.7 or later)
- Access to an FTP server
- JSON files with clinician contact data available on the FTP server

## Database Setup

### MySQL Database Schema

Create the database and table structure:

```sql
CREATE DATABASE IF NOT EXISTS blueriver;
USE blueriver;

CREATE TABLE IF NOT EXISTS clinician_contact (
    id INT AUTO_INCREMENT PRIMARY KEY,
    clinician_id VARCHAR(50) NOT NULL,
    npi VARCHAR(20),
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone_mobile VARCHAR(20),
    phone_office VARCHAR(20),
    pager VARCHAR(20),
    department VARCHAR(100),
    specialty VARCHAR(100),
    facility_code VARCHAR(50),
    facility_name VARCHAR(255),
    status VARCHAR(20),
    effective_from VARCHAR(50),
    updated_at VARCHAR(50),
    source_file VARCHAR(255),
    last_ingested_at VARCHAR(50),
    UNIQUE KEY unique_clinician (clinician_id, source_file)
);
```

## Configuration

### Config.toml Setup

Create a `Config.toml` file in your project root with the following configuration:

```toml
# FTP Server Configuration
ftpHost = "localhost"
ftpPort = 2121
ftpUsername = "myuser"
ftpPassword = "s3cr3t"
ftpDirectory = "/json-files"

# MySQL Database Configuration
dbHost = "localhost"
dbPort = 3306
dbUsername = "root"
dbPassword = "root"
dbName = "blueriver"
```

### Configuration Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `ftpHost` | string | FTP server hostname or IP address | "127.0.0.1" |
| `ftpPort` | int | FTP server port number | 21 |
| `ftpUsername` | string | FTP authentication username | "" |
| `ftpPassword` | string | FTP authentication password | "" |
| `ftpDirectory` | string | Directory path containing JSON files | "/" |
| `dbHost` | string | MySQL server hostname or IP address | "localhost" |
| `dbPort` | int | MySQL server port number | 3306 |
| `dbUsername` | string | MySQL database username | "root" |
| `dbPassword` | string | MySQL database password | "root" |
| `dbName` | string | MySQL database name | "blueriver" |

## Usage

### Running the Integration

1. **Clone or create the project**:
   ```bash
   bal new batch_file_processing
   cd batch_file_processing
   ```

2. **Add the source files** to your project directory

3. **Configure your settings** in `Config.toml`

4. **Set up the MySQL database** using the provided schema

5. **Run the integration**:
   ```bash
   bal run
   ```

### Expected Output

The integration will display:
- Connection information for both FTP and database
- File discovery results (total files found, JSON files identified)
- Processing status for each JSON file
- Database insertion results for each clinician record
- Final processing summary with success/failure counts

Example output:
```
Starting clinician contact data processing and database insertion...
FTP Server: localhost:2121
Directory: /json-files
Database: blueriver on localhost:3306
----------------------------------------
Found 3 total files in directory
Found 2 JSON files to process
----------------------------------------
Processing clinician data file: clinicians_batch1.json
✓ Successfully loaded: clinicians_batch1.json
Found 5 clinician records to insert
✓ Inserted clinician: C1001 (John Doe)
✓ Inserted clinician: C1002 (Jane Smith)
✓ Successfully inserted all records from: clinicians_batch1.json
========================================
PROCESSING SUMMARY:
Total JSON files: 2
Files successfully processed: 2
Files with errors: 0
Total clinician records inserted: 10
Total insertion errors: 0
Clinician data processing and database insertion completed.
```

## Project Structure

```
batch_file_processing/
├── main.bal              # Main application entry point
├── config.bal            # FTP and database client configuration
├── functions.bal         # Core processing functions
├── types.bal            # Type definitions
├── Config.toml          # Configuration file
├── Ballerina.toml       # Project configuration with MySQL driver
└── README.md           # This documentation
```

### Key Components

- **main.bal**: Contains the main function that orchestrates the batch processing workflow
- **config.bal**: Manages FTP and database client configuration and connection setup
- **functions.bal**: Implements core functionality for file processing, JSON parsing, and database insertion
- **types.bal**: Defines custom types for configuration, processing results, and data structures
- **Ballerina.toml**: Project configuration including MySQL JDBC driver dependency

## JSON Data Format

The integration expects JSON files containing arrays of clinician contact objects with the following structure:

```json
[
  {
    "clinicianId": "C1004",
    "npi": "9988776655",
    "firstName": "Emily",
    "middleName": "K",
    "lastName": "Chen",
    "email": "emily.chen@blueriver.org",
    "phoneMobile": "+19015550055",
    "phoneOffice": "+19015550004",
    "pager": "5004",
    "department": "Oncology",
    "specialty": "Medical Oncology",
    "facilityCode": "BLR-MEM",
    "facilityName": "BlueRiver Memphis",
    "status": "ACTIVE",
    "effectiveFrom": "2025-07-28",
    "updatedAt": "2025-07-29T02:00:00Z"
  }
]
```

## Error Handling

The integration includes comprehensive error handling for:

- **FTP Connection Errors**: Network connectivity, authentication failures
- **File Access Errors**: Permission issues, file not found scenarios
- **JSON Parsing Errors**: Invalid JSON format, encoding issues
- **Database Connection Errors**: MySQL connectivity, authentication issues
- **Database Insertion Errors**: Constraint violations, data type mismatches
- **Stream Processing Errors**: Data conversion and byte stream handling

Failed operations are logged with detailed error messages, and processing continues with remaining files.

## Troubleshooting

### Common Issues

1. **Database Driver Error**: Ensure `Ballerina.toml` includes the MySQL JDBC driver dependency
2. **Connection Refused (FTP)**: Verify FTP server address, port, and network connectivity
3. **Authentication Failed (FTP)**: Check username/password in Config.toml
4. **Database Connection Failed**: Verify MySQL server is running and credentials are correct
5. **Table Not Found**: Ensure the `clinician_contact` table exists in the specified database
6. **No Files Found**: Verify directory path and file permissions

### Debug Tips

- Test FTP connection manually using an FTP client
- Test MySQL connection using a database client
- Verify JSON file format using online JSON validators
- Check database table structure matches the expected schema
- Review Ballerina logs for detailed error messages

## Contributing

To extend this integration:

1. Add new file type support in `functions.bal`
2. Implement additional processing logic in the main workflow
3. Add new configuration options in `config.bal`
4. Update type definitions in `types.bal` as needed
5. Modify database schema for additional data fields

## License

This project is available under the Apache License 2.0.