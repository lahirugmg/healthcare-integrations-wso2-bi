-- blueriver.sql
-- MySQL 8.0+ script to create database and schema for BlueRiver Medical Group Zoom event ingestion
-- Safe to run multiple times (idempotent where possible).

-- 0) Session settings (optional)
SET NAMES utf8mb4;
SET time_zone = '+00:00';

-- 1) Create database
CREATE DATABASE IF NOT EXISTS blueriver
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE blueriver;

-- 2) Table: zoom_visit_events
--   Columns
--     id BIGINT AUTO_INCREMENT primary key
--     meeting_id VARCHAR(64)
--     visit_uuid VARCHAR(128)
--     event_name VARCHAR(128) NOT NULL
--     event_ts BIGINT NOT NULL  -- epoch milliseconds
--     participant_id VARCHAR(64)
--     participant_name VARCHAR(255)
--     latency_ms INT
--     interpreter_requested TINYINT(1)
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
--     raw JSON NOT NULL
--   Constraints
--     UNIQUE KEY uk_event (meeting_id, event_ts, event_name, participant_id)
--   Indexes
--     idx_meeting_ts (meeting_id, event_ts)
--     idx_event_ts (event_ts)

CREATE TABLE IF NOT EXISTS zoom_visit_events (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  meeting_id VARCHAR(64) NULL,
  visit_uuid VARCHAR(128) NULL,
  event_name VARCHAR(128) NOT NULL,
  event_ts BIGINT NOT NULL, -- epoch millis
  participant_id VARCHAR(64) NULL,
  participant_name VARCHAR(255) NULL,
  latency_ms INT NULL,
  interpreter_requested TINYINT(1) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  raw JSON NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_event (meeting_id, event_ts, event_name, participant_id),
  KEY idx_meeting_ts (meeting_id, event_ts),
  KEY idx_event_ts (event_ts)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3) (Optional) Generated column for human-readable time and index (MySQL 8.0+)
-- Uncomment to enable:
-- ALTER TABLE zoom_visit_events
--   ADD COLUMN event_time DATETIME GENERATED ALWAYS AS (FROM_UNIXTIME(event_ts/1000)) STORED,
--   ADD KEY idx_event_time (event_time);

-- 4) (Optional) Create app user & grant minimal privileges (adjust password!)
-- CREATE USER IF NOT EXISTS 'blueriver_app'@'%' IDENTIFIED BY 'change-me';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON blueriver.* TO 'blueriver_app'@'%';
-- FLUSH PRIVILEGES;
