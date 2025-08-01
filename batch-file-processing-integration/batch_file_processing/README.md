# FTP JSON Batch File Processing Integration

A Ballerina-based automation system that processes batches of JSON files from FTP locations and prints their content to the console.

## Overview

This integration connects to an FTP server, discovers JSON files in a specified directory, downloads and processes each file, then outputs the parsed JSON content. It's designed for automated batch processing scenarios where JSON files are regularly uploaded to an FTP server and need to be processed systematically.

## Features

- **Automated FTP Connection**: Connects to FTP servers with configurable authentication
- **JSON File Discovery**: Automatically identifies and filters JSON files from FTP directories
- **Batch Processing**: Processes multiple JSON files sequentially
- **Error Handling**: Comprehensive error handling for FTP operations and JSON parsing
- **Processing Summary**: Provides detailed reports on successful and failed file processing
- **Configurable Settings**: Flexible configuration through Config.toml file

## Prerequisites

- Ballerina Swan Lake (2201.x.x or later)
- Access to an FTP server
- JSON files available on the FTP server

## Configuration

### Config.toml Setup

Create a `Config.toml` file in your project root with the following configuration:

```toml
# FTP Server Configuration
ftpHost = "your-ftp-server.com"
ftpPort = 21
ftpUsername = "your-username"
ftpPassword = "your-password"
ftpDirectory = "/path/to/json/files"
```

### Configuration Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `ftpHost` | string | FTP server hostname or IP address | "127.0.0.1" |
| `ftpPort` | int | FTP server port number | 21 |
| `ftpUsername` | string | FTP authentication username | "" |
| `ftpPassword` | string | FTP authentication password | "" |
| `ftpDirectory` | string | Directory path containing JSON files | "/" |

## Usage

### Running the Integration

1. **Clone or create the project**:
   ```bash
   bal new batch_file_processing
   cd batch_file_processing
   ```

2. **Add the source files** to your project directory

3. **Configure your FTP settings** in `Config.toml`

4. **Run the integration**:
   ```bash
   bal run
   ```

### Expected Output

The integration will display:
- Connection information and directory details
- File discovery results (total files found, JSON files identified)
- Processing status for each JSON file
- File content output for successfully processed files
- Final processing summary with success/failure counts

Example output:
```
Starting batch JSON file processing from FTP location...
FTP Server: ftp.example.com:21
Directory: /data/json
----------------------------------------
Found 5 total files in directory
Found 3 JSON files to process
----------------------------------------
Processing file: data1.json
✓ Successfully processed: data1.json
File Content:
{"id":1,"name":"Sample Data","status":"active"}
----------------------------------------
Processing file: data2.json
✓ Successfully processed: data2.json
File Content:
{"id":2,"name":"Another Sample","status":"inactive"}
----------------------------------------
PROCESSING SUMMARY:
Total JSON files: 3
Successfully processed: 2
Failed to process: 1
Batch processing completed.
```

## Project Structure

```
batch_file_processing/
├── main.bal              # Main application entry point
├── config.bal            # FTP client configuration
├── functions.bal         # Core processing functions
├── types.bal            # Type definitions
├── Config.toml          # Configuration file
└── README.md           # This documentation
```

### Key Components

- **main.bal**: Contains the main function that orchestrates the batch processing workflow
- **config.bal**: Manages FTP client configuration and connection setup
- **functions.bal**: Implements core functionality for file processing, JSON parsing, and filtering
- **types.bal**: Defines custom types for configuration and processing results

## Error Handling

The integration includes comprehensive error handling for:

- **FTP Connection Errors**: Network connectivity, authentication failures
- **File Access Errors**: Permission issues, file not found scenarios
- **JSON Parsing Errors**: Invalid JSON format, encoding issues
- **Stream Processing Errors**: Data conversion and byte stream handling

Failed files are logged with detailed error messages, and processing continues with remaining files.

## Supported File Types

- **JSON Files**: Files with `.json` extension
- **Content Format**: Valid JSON format as per RFC 7159
- **Encoding**: UTF-8 encoded text files

## Limitations

- Sequential processing (files are processed one at a time)
- FTP authentication configuration depends on server setup
- Large files may impact memory usage during processing
- No file modification or deletion capabilities (read-only operations)

## Troubleshooting

### Common Issues

1. **Connection Refused**: Verify FTP server address, port, and network connectivity
2. **Authentication Failed**: Check username/password in Config.toml
3. **No Files Found**: Verify directory path and file permissions
4. **JSON Parse Errors**: Ensure files contain valid JSON content

### Debug Tips

- Test FTP connection manually using an FTP client
- Verify JSON file format using online JSON validators
- Check file permissions on the FTP server
- Review Ballerina logs for detailed error messages

## Contributing

To extend this integration:

1. Add new file type support in `functions.bal`
2. Implement additional processing logic in the main workflow
3. Add new configuration options in `config.bal`
4. Update type definitions in `types.bal` as needed

## License

This project is available under the Apache License 2.0.