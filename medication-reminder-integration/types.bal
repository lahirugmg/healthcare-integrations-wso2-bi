// Database configuration record
public type DatabaseConfig record {|
    string host;
    int port;
    string user;
    string password;
    string database;
|};

// Twilio configuration record
public type TwilioConfig record {|
    string accountSid;
    string apiSecret;
    string apiKey;
    string fromNumber;
|};


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

