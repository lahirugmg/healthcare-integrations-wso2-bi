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