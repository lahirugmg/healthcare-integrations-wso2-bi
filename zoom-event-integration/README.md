# Healthcare Integration - Zoom Events Service

A Ballerina-based integration service that captures and processes Zoom meeting events for healthcare applications. This service is designed to handle telehealth visit events, storing them in a MySQL database for further processing and analytics.

## Overview

This integration service provides:
- **Event Ingestion**: Receives Zoom webhook events via HTTP POST endpoint
- **Data Processing**: Normalizes and extracts relevant fields from Zoom event payloads
- **Database Storage**: Stores processed events in MySQL with duplicate prevention
- **Health Monitoring**: Provides health check endpoint with database connectivity status
- **Observability**: Tracks total received and inserted events

## Architecture

```
Zoom Webhooks → HTTP Service (Port 8280) → MySQL Database
                     ↓
              Health Check Endpoint
```

## Features

### Event Processing
- Handles various Zoom meeting events (join, leave, interpreter requests, etc.)
- Extracts key fields: meeting ID, participant details, timestamps, latency metrics
- Stores raw JSON payload alongside normalized data
- Implements duplicate prevention using MySQL's ON DUPLICATE KEY UPDATE

### Monitoring & Observability
- Real-time counters for received and inserted events
- Database connectivity health checks
- Comprehensive logging for troubleshooting
- Non-blocking error handling to maintain service availability

## Prerequisites

- Ballerina Swan Lake (latest version)
- MySQL 8.0 or higher
- Network connectivity to receive Zoom webhooks

## Database Schema

The service expects a MySQL database with the following table structure:

```sql
CREATE TABLE zoom_visit_events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    meeting_id VARCHAR(255) NOT NULL,
    visit_uuid VARCHAR(255) NOT NULL,
    event_name VARCHAR(100) NOT NULL,
    event_ts BIGINT NOT NULL,
    participant_id VARCHAR(255),
    participant_name VARCHAR(500),
    latency_ms INT,
    interpreter_requested TINYINT(1),
    raw JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_event (meeting_id, visit_uuid, event_name, event_ts, participant_id)
);
```

## Configuration

Create a `Config.toml` file in your project root:

```toml
[healthcare_integration.healthcare_integration.db]
host = "localhost"
port = 3306
user = "your_db_user"
password = "your_db_password"
database = "blueriver"
```

### Configuration Parameters

| Parameter | Description | Required |
|-----------|-------------|----------|
| `host` | MySQL server hostname | Yes |
| `port` | MySQL server port | Yes |
| `user` | Database username | Yes |
| `password` | Database password | Yes |
| `database` | Database name | Yes |

## Installation & Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd healthcare_integration
   ```

2. **Configure the database**
   - Create the MySQL database and table (see Database Schema section)
   - Update `Config.toml` with your database credentials

3. **Install dependencies**
   ```bash
   bal build
   ```

4. **Run the service**
   ```bash
   bal run
   ```

The service will start on port 8280 and be ready to receive Zoom webhooks.

## API Endpoints

### POST /zoom_events/events
Receives and processes Zoom webhook events.

**Request:**
- Content-Type: `application/json`
- Body: Zoom webhook payload

**Response:**
- Status: `202 Accepted`
- Body: `{"status": "accepted"}`

**Example Zoom Webhook Payload:**
```json
{
    "event": "meeting.participant_joined",
    "event_ts": 1234567890,
    "payload": {
        "object": {
            "id": "123456789",
            "uuid": "abc-def-ghi",
            "participant": {
                "user_id": "user123",
                "user_name": "Dr. Smith"
            },
            "latency_ms": 45
        }
    }
}
```

### GET /zoom_events/health
Health check endpoint for monitoring service status.

**Response:**
```json
{
    "status": "ok",
    "db": "up",
    "received": 1250,
    "inserted": 1248
}
```

**Response Fields:**
- `status`: Overall service status ("ok")
- `db`: Database connectivity status ("up" or "down")
- `received`: Total events received since startup
- `inserted`: Total events successfully inserted (excludes duplicates)

## Zoom Webhook Configuration

Configure your Zoom App to send webhooks to:
```
https://your-domain.com/zoom_events/events
```

**Recommended Event Types:**
- `meeting.started`
- `meeting.ended`
- `meeting.participant_joined`
- `meeting.participant_left`
- `meeting.interpreter_requested`

## Error Handling

The service implements robust error handling:
- **Non-blocking**: Processing errors don't affect webhook response
- **Logging**: All errors are logged with context
- **Graceful degradation**: Service continues operating even with database issues
- **Duplicate prevention**: Uses database constraints to handle duplicate events

## Monitoring

### Logs
The service provides structured logging for:
- Successful event processing
- Database connectivity issues
- Processing errors with full context

### Metrics
Track service health using the `/health` endpoint:
- Monitor `received` vs `inserted` counts to identify processing issues
- Check `db` status for database connectivity
- Set up alerts for database downtime

## Development

### Project Structure
```
healthcare_integration/
├── main.bal           # Main service implementation
├── types.bal          # Type definitions
├── config.bal         # Configuration management
├── Config.toml        # Configuration file
└── README.md          # This file
```

### Adding New Event Types
1. Update `ZoomEventPayload` type in `types.bal` if needed
2. Add event-specific processing logic in the POST endpoint
3. Update database schema if new fields are required

## Troubleshooting

### Common Issues

**Database Connection Errors**
- Verify MySQL server is running
- Check network connectivity
- Validate credentials in `Config.toml`

**Missing Events**
- Check Zoom webhook configuration
- Verify endpoint URL is accessible
- Review service logs for processing errors

**High Memory Usage**
- Monitor for large JSON payloads
- Consider implementing payload size limits
- Check for database connection leaks

### Debug Mode
Enable detailed logging by setting log level to DEBUG in your environment.

## Security Considerations

- **Network Security**: Deploy behind a reverse proxy with HTTPS
- **Database Security**: Use dedicated database user with minimal privileges
- **Webhook Validation**: Consider implementing Zoom webhook signature validation
- **Rate Limiting**: Implement rate limiting to prevent abuse

## License

[Add your license information here]

## Support

For issues and questions:
- Check the troubleshooting section
- Review service logs
- Contact the development team

---

**Version**: 1.0.0  
**Last Updated**: [Current Date]