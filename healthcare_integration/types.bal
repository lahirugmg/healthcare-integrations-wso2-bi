// Database configuration record
public type DatabaseConfig record {|
    string host;
    int port;
    string user;
    string password;
    string database;
|};


// Zoom event payload structure for normalization - using open records
public type ZoomEventPayload record {
    string event;
    int event_ts;
    ZoomPayload payload;
    // Allow additional fields that we don't need to process
};

public type ZoomPayload record {
    ZoomObject 'object;
    // Allow additional fields like account_id, etc.
};

public type ZoomObject record {
    string id;
    string uuid;
    ZoomParticipant participant?;
    int latency_ms?;
    // Allow additional fields
};

public type ZoomParticipant record {
    string user_id;
    string user_name;
    // Allow additional fields
};

// Health check response
public type HealthResponse record {|
    string status;
    string db;
    int received;
    int inserted;
|};

// API response types
public type AcceptedResponse record {|
    string status;
|};

// Patient record
public type Patient record {|
    int id;
    string first_name;
    string last_name;
    string phone_e164;
    string? tz;
|};

// Medication record
public type Medication record {|
    int id;
    string name;
    string dosage;
|};

// Medication schedule record
public type MedicationSchedule record {|
    int id;
    int patient_id;
    int medication_id;
    int frequency_minutes;
    string next_dose_at;
    string? last_sent_at;
    string status;
    int retry_count;
|};

// Due reminder with joined data
public type DueReminder record {|
    int schedule_id;
    int patient_id;
    int medication_id;
    int frequency_minutes;
    string next_dose_at;
    string? last_sent_at;
    string status;
    int retry_count;
    string first_name;
    string phone_e164;
    string medication_name;
    string dosage;
|};

// Reminder log record
public type ReminderLog record {|
    int id;
    int schedule_id;
    string attempted_at;
    string result;
    string? provider_msg_id;
    string? error_text;
|};

// Processing summary
public type ProcessingSummary record {|
    int totalDue;
    int totalSent;
    int totalFailed;
|};

