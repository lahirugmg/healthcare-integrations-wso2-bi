import ballerina/http;
import ballerina/log;
import ballerina/sql;
import ballerinax/mysql;

// Observability counters
int totalReceived = 0;
int totalInserted = 0;

// Reference schema (for context only; do not execute in code)
// Database: blueriver
// Tables: patient, medication, medication_schedule, reminder_log
// See query description for complete schema details

// Global MySQL client - initialized at module level
final mysql:Client mysqlClient = check initializeMysqlClient();

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

// HTTP service listening on port 8280
service /zoom_events on new http:Listener(8280) {

    // POST /zoom/events endpoint
    resource function post events(@http:Payload json payload) returns http:Response {
        http:Response response = new;

        lock {
            totalReceived += 1;
        }

        do {
            // Convert JSON to structured type for easier field extraction
            ZoomEventPayload zoomEvent = check payload.cloneWithType(ZoomEventPayload);

            // Extract normalized fields
            string meetingId = zoomEvent.payload.'object.id;
            string visitUuid = zoomEvent.payload.'object.uuid;
            string eventName = zoomEvent.event;
            int eventTs = zoomEvent.event_ts;

            // Optional participant fields
            string? participantId = zoomEvent.payload.'object.participant?.user_id;
            string? participantName = zoomEvent.payload.'object.participant?.user_name;
            int? latencyMs = zoomEvent.payload.'object.latency_ms;

            // Determine interpreter_requested
            int? interpreterRequested = eventName == "meeting.interpreter_requested" ? 1 : ();

            // Convert payload to JSON string for raw storage
            string rawJson = payload.toJsonString();

            // Insert into database using parameterized query
            sql:ParameterizedQuery insertQuery = `
                INSERT INTO zoom_visit_events 
                (meeting_id, visit_uuid, event_name, event_ts, participant_id, 
                 participant_name, latency_ms, interpreter_requested, raw)
                VALUES (${meetingId}, ${visitUuid}, ${eventName}, ${eventTs}, ${participantId}, 
                        ${participantName}, ${latencyMs}, ${interpreterRequested}, ${rawJson})
                ON DUPLICATE KEY UPDATE id = id
            `;

            sql:ExecutionResult insertResult = check mysqlClient->execute(insertQuery);

            // Check if row was actually inserted (not a duplicate)
            int? affectedRows = insertResult.affectedRowCount;
            if affectedRows is int && affectedRows > 0 {
                lock {
                    totalInserted += 1;
                }
            }

            log:printInfo(string `Successfully processed event: meeting_id=${meetingId}, event_name=${eventName}, event_ts=${eventTs}`);

        } on fail error e {
            // Log error but don't fail the request to keep ingestion non-blocking
            log:printError("Failed to process zoom event", 'error = e);
        }

        // Always return 202 accepted
        AcceptedResponse acceptedResponse = {status: "accepted"};
        response.statusCode = 202;
        response.setJsonPayload(acceptedResponse);
        return response;
    }

    // GET /health endpoint
    resource function get health() returns http:Response {
        http:Response response = new;
        string dbStatus = "up";

        // Test database connectivity
        do {
            sql:ParameterizedQuery testQuery = `SELECT 1`;
            stream<record {}, sql:Error?> resultStream = mysqlClient->query(testQuery);
            _ = check resultStream.next();
            check resultStream.close();
        } on fail error e {
            dbStatus = "down";
            log:printError("Database connectivity check failed", 'error = e);
        }

        int currentReceived;
        lock {
            currentReceived = totalReceived;
        }

        int currentInserted;
        lock {
            currentInserted = totalInserted;
        }

        HealthResponse healthResponse = {
            status: "ok",
            db: dbStatus,
            received: currentReceived,
            inserted: currentInserted
        };

        response.statusCode = 200;
        response.setJsonPayload(healthResponse);
        return response;
    }
}
