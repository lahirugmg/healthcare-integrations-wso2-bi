import ballerina/lang.runtime;
import ballerina/log;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/twilio;

// Observability counters
int totalReceived = 0;
int totalInserted = 0;


// Reference schema (for context only; do not execute in code)
// Database: blueriver
// Tables: patient, medication, medication_schedule, reminder_log
// See query description for complete schema details

// Global MySQL client - initialized at module level
final mysql:Client mysqlClient = check initializeMysqlClient();

// Global Twilio client - initialized at module level
final twilio:Client twilioClient = check initializeTwilioClient();

// Initialize MySQL client with fail-fast behavior
isolated function initializeMysqlClient() returns mysql:Client|error {
    DatabaseConfig dbConfig = getDatabaseConfig();

    mysql:Client dbClient = check new (
        host = dbConfig.host,
        port = dbConfig.port,
        user = dbConfig.user,
        password = dbConfig.password,
        database = dbConfig.database
    );

    log:printInfo("MySQL client initialized successfully");
    return dbClient;
}

// Initialize Twilio client
isolated function initializeTwilioClient() returns twilio:Client|error {
    TwilioConfig twilioConfig = getTwilioConfig();

    // Initialize Twilio client with ApiKeyConfig
    twilio:ConnectionConfig twilioConnectionConfig = {
        auth: {
            apiKey: twilioConfig.apiKey,
            apiSecret: twilioConfig.apiSecret,
            accountSid: twilioConfig.accountSid
        }
    };

    twilio:Client twilioClientInstance = check new (twilioConnectionConfig);
    log:printInfo("Twilio client initialized successfully");
    return twilioClientInstance;
}

// Main function - starts the medication reminder scheduler
public function main() returns error? {
    log:printInfo("Starting BlueRiver Medical Group - Medication Reminder Service");

    // Start the scheduler loop
    while true {
        do {
            check processMedicationReminders();
        } on fail error e {
            log:printError("Error in medication reminder processing", 'error = e);
        }

        // Wait 5 minutes before next execution
        runtime:sleep(300.0); // 300 seconds = 5 minutes
    }
}

// Process medication reminders - main business logic
function processMedicationReminders() returns error? {
    log:printInfo("Starting medication reminder processing cycle");

    // Step 1: Begin transaction and atomically mark due reminders as SENDING
    DueReminder[] dueReminders = check markAndFetchDueReminders();

    if dueReminders.length() == 0 {
        log:printInfo("No due medication reminders found");
        return;
    }

    log:printInfo(string `Found ${dueReminders.length()} due medication reminders`);

    // Step 2: Process each reminder
    ProcessingSummary summary = {
        totalDue: dueReminders.length(),
        totalSent: 0,
        totalFailed: 0
    };

    foreach DueReminder reminder in dueReminders {
        do {
            check processSingleReminder(reminder);
            summary.totalSent += 1;
        } on fail error e {
            summary.totalFailed += 1;
            log:printError(string `Failed to process reminder for schedule_id: ${reminder.schedule_id}`, 'error = e);

            // Reset status to PENDING and increment retry count
            check handleReminderFailure(reminder, e.message());
        }
    }

    // Step 3: Log summary
    log:printInfo(string `Medication reminder processing completed - Due: ${summary.totalDue}, Sent: ${summary.totalSent}, Failed: ${summary.totalFailed}`);
}

// Atomically mark due reminders as SENDING and fetch them - FIXED VERSION
function markAndFetchDueReminders() returns DueReminder[]|error {
    // Begin transaction
    sql:ExecutionResult _ = check mysqlClient->execute(`START TRANSACTION`);

    do {
        // Step 1: Mark due reminders as SENDING using MySQL's native UTC_TIMESTAMP()
        sql:ParameterizedQuery markQuery = `
            UPDATE medication_schedule 
            SET status = 'SENDING' 
            WHERE next_dose_at <= UTC_TIMESTAMP() 
            AND status = 'PENDING'
        `;

        sql:ExecutionResult markResult = check mysqlClient->execute(markQuery);
        int? affectedRowCount = markResult.affectedRowCount;
        log:printInfo(string `Marked ${affectedRowCount ?: 0} reminders as SENDING`);

        // Step 2: Fetch the marked reminders with joined data
        sql:ParameterizedQuery fetchQuery = `
            SELECT 
                ms.id as schedule_id,
                ms.patient_id,
                ms.medication_id,
                ms.frequency_minutes,
                ms.next_dose_at,
                ms.last_sent_at,
                ms.status,
                ms.retry_count,
                p.first_name,
                p.phone_e164,
                m.name as medication_name,
                m.dosage
            FROM medication_schedule ms
            JOIN patient p ON ms.patient_id = p.id
            JOIN medication m ON ms.medication_id = m.id
            WHERE ms.status = 'SENDING'
        `;

        stream<DueReminder, sql:Error?> reminderStream = mysqlClient->query(fetchQuery);
        DueReminder[] reminders = check from DueReminder reminder in reminderStream
            select reminder;
        check reminderStream.close();

        // Commit transaction
        sql:ExecutionResult _ = check mysqlClient->execute(`COMMIT`);

        return reminders;

    } on fail error e {
        // Rollback transaction on error
        sql:ExecutionResult _ = check mysqlClient->execute(`ROLLBACK`);
        return e;
    }
}

// Process a single medication reminder
function processSingleReminder(DueReminder reminder) returns error? {
    // Build personalized SMS message
    string message = string `Hi ${reminder.first_name}, it's time to take ${reminder.medication_name} ${reminder.dosage}. –BlueRiver`;

    log:printInfo(string `Sending SMS reminder to ${reminder.phone_e164} for schedule_id: ${reminder.schedule_id}`);

    // Send SMS via Twilio
    TwilioConfig twilioConfig = getTwilioConfig();

    log:printInfo(message);
    
    twilio:CreateMessageRequest smsRequest = {
        To: reminder.phone_e164,
        From: twilioConfig.fromNumber,
        Body: message
    };


    twilio:Message|error smsResponse = twilioClient->createMessage(smsRequest);
        

    if smsResponse is error {
        string errorMessage = "Failed to send SMS: " + smsResponse.message();
        log:printError("SMS sending failed - To: " + reminder.phone_e164 + ", Error: " + smsResponse.message());
        return error(errorMessage);
    }
    
    string? messageSid = smsResponse?.sid;
    string? messageStatus = smsResponse?.status;
    
    // Log successful SMS sending
    if messageSid is string {
        log:printInfo("SMS sent successfully - Message SID: " + messageSid + ", To: " + reminder.phone_e164);
    }
    
    if messageStatus is string {
        log:printInfo("SMS Status: " + messageStatus + " for Message SID: " + (messageSid ?: "N/A"));
    }
    
    log:printInfo("SMS sending process completed successfully");
    

    // Update schedule status to SENT and calculate next dose time
    // check updateReminderSuccess(reminder, messageSid);

    // Log successful attempt
    // check logReminderAttempt(reminder.schedule_id, "SUCCESS", messageSid, ());

    log:printInfo(string `Successfully sent SMS reminder for schedule_id: ${reminder.schedule_id}, message_sid: ${messageSid ?: "unknown"}`);
}

// Update reminder status after successful SMS send - FIXED VERSION
function updateReminderSuccess(DueReminder reminder, string? messageSid) returns error? {
    // Use MySQL's native functions for time calculations
    sql:ParameterizedQuery updateQuery = `
        UPDATE medication_schedule 
        SET status = 'SENT',
            last_sent_at = UTC_TIMESTAMP(),
            next_dose_at = DATE_ADD(UTC_TIMESTAMP(), INTERVAL ${reminder.frequency_minutes} MINUTE)
        WHERE id = ${reminder.schedule_id}
    `;

    sql:ExecutionResult _ = check mysqlClient->execute(updateQuery);
}

// Handle reminder failure - reset status and increment retry count
function handleReminderFailure(DueReminder reminder, string errorMessage) returns error? {
    sql:ParameterizedQuery updateQuery = `
        UPDATE medication_schedule 
        SET status = 'PENDING',
            retry_count = retry_count + 1
        WHERE id = ${reminder.schedule_id}
    `;

    sql:ExecutionResult _ = check mysqlClient->execute(updateQuery);

    // Log failed attempt
    check logReminderAttempt(reminder.schedule_id, "FAILURE", (), errorMessage);
}

// Log reminder attempt to audit table - FIXED VERSION
function logReminderAttempt(int scheduleId, string result, string? providerMsgId, string? errorText) returns error? {
    sql:ParameterizedQuery logQuery = `
        INSERT INTO reminder_log 
        (schedule_id, attempted_at, result, provider_msg_id, error_text)
        VALUES (${scheduleId}, UTC_TIMESTAMP(), ${result}, ${providerMsgId}, ${errorText})
    `;

    sql:ExecutionResult _ = check mysqlClient->execute(logQuery);
}