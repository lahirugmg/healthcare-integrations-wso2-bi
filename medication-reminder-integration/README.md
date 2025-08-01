# Medication Reminder System

A Ballerina-based healthcare integration service that automatically sends SMS medication reminders to patients using Twilio and MySQL database integration.

## Project Overview

This system helps healthcare providers ensure medication adherence by automatically sending personalized SMS reminders to patients when their medications are due. The service runs continuously, checking for due medications every 5 minutes and sending timely reminders via SMS.

## Features

- **Automated Medication Reminders**: Continuously monitors medication schedules and sends SMS reminders when doses are due
- **Personalized Messages**: Creates customized SMS messages with patient name, medication name, and dosage information
- **Reliable Delivery**: Uses Twilio's SMS service for reliable message delivery with status tracking
- **Failure Handling**: Implements retry mechanisms and comprehensive error logging
- **Database Integration**: Stores patient data, medication schedules, and reminder logs in MySQL
- **Transaction Safety**: Uses database transactions to ensure data consistency
- **Comprehensive Logging**: Tracks all reminder attempts, successes, and failures for audit purposes

## Architecture

The system consists of several key components:

- **Main Scheduler**: Runs every 5 minutes to process due medication reminders
- **Database Layer**: MySQL integration for patient, medication, and schedule management
- **SMS Service**: Twilio integration for reliable SMS delivery
- **Configuration Management**: Configurable database and Twilio settings
- **Logging & Monitoring**: Comprehensive logging for all operations

## Database Schema

The system uses the following MySQL tables:

- **patient**: Stores patient information including contact details
- **medication**: Contains medication details and dosage information
- **medication_schedule**: Manages medication timing and frequency
- **reminder_log**: Audit trail of all reminder attempts

## Configuration

Create a `Config.toml` file with the following structure:

```toml
[healthcare_integration.healthcare_integration.db]
host = "localhost"
port = 3306
user = "your_db_user"
password = "your_db_password"
database = "blueriver"

[healthcare_integration.healthcare_integration.twilio]
accountSid = "your_twilio_account_sid"
apiSecret = "your_twilio_api_secret"
apiKey = "your_twilio_api_key"
fromNumber = "+1234567890"
```

## Prerequisites

- Ballerina Swan Lake (latest version)
- MySQL database server
- Twilio account with SMS capabilities
- Valid phone numbers in E.164 format for patients

## Installation & Setup

1. Clone the repository
2. Set up your MySQL database with the required schema
3. Configure your `Config.toml` file with database and Twilio credentials
4. Install dependencies:
   ```bash
   bal build
   ```

## Running the Service

Start the medication reminder service:

```bash
bal run
```

The service will:
- Initialize database and Twilio connections
- Start the continuous monitoring loop
- Process due medication reminders every 5 minutes
- Send SMS notifications to patients
- Log all activities and handle errors gracefully

## SMS Message Format

Patients receive personalized messages in the format:
```
Hi [Patient Name], it's time to take [Medication Name] [Dosage]. –BlueRiver
```

## Monitoring & Logging

The system provides comprehensive logging including:
- Service startup and initialization status
- Number of due reminders found each cycle
- SMS sending success/failure details
- Database transaction status
- Error handling and retry attempts

## Error Handling

The system includes robust error handling:
- Database connection failures are logged and retried
- SMS sending failures trigger retry mechanisms
- Failed reminders are reset to PENDING status
- All errors are logged with detailed information

## Security Considerations

- Database credentials are stored in configuration files
- Twilio API keys are securely managed
- Patient phone numbers are stored in E.164 format
- All database operations use parameterized queries

## Contributing

This is a healthcare integration project focused on medication adherence. When contributing:
- Follow HIPAA compliance guidelines
- Ensure patient data privacy
- Test thoroughly with sample data
- Document any schema changes

## License

This project is designed for healthcare providers to improve patient medication adherence and should be used in compliance with applicable healthcare regulations.