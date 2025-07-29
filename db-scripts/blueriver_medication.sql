5) `sql/schema.sql` — **MySQL schema (medications for different patients)**
```sql
CREATE DATABASE IF NOT EXISTS blueriver;
USE blueriver;

CREATE TABLE IF NOT EXISTS patient (
  id INT PRIMARY KEY AUTO_INCREMENT,
  first_name VARCHAR(80) NOT NULL,
  last_name  VARCHAR(80) NOT NULL,
  phone_e164 VARCHAR(20) NOT NULL,  -- e.g., +19015551234
  tz VARCHAR(50) DEFAULT 'UTC'      -- optional: patient time zone
);

CREATE TABLE IF NOT EXISTS medication (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL,
  dosage VARCHAR(120) NOT NULL      -- e.g., "500 mg", "1 tablet"
);

CREATE TABLE IF NOT EXISTS medication_schedule (
  id INT PRIMARY KEY AUTO_INCREMENT,
  patient_id INT NOT NULL,
  medication_id INT NOT NULL,
  frequency_minutes INT NOT NULL,   -- e.g., every 8 hours => 480
  next_dose_at DATETIME NOT NULL,   -- in UTC
  status ENUM('PENDING','SENDING','SENT','PAUSED') DEFAULT 'PENDING',
  retry_count INT DEFAULT 0,
  CONSTRAINT fk_ms_patient FOREIGN KEY (patient_id) REFERENCES patient(id),
  CONSTRAINT fk_ms_med FOREIGN KEY (medication_id) REFERENCES medication(id),
  INDEX idx_due (status, next_dose_at)
);

CREATE TABLE IF NOT EXISTS reminder_log (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  schedule_id INT NOT NULL,
  attempted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  result ENUM('SUCCESS','FAILURE') NOT NULL,
  provider_msg_id VARCHAR(64) NULL,
  error_text TEXT NULL,
  FOREIGN KEY (schedule_id) REFERENCES medication_schedule(id)
);

-- Sample data
INSERT INTO patient (first_name, last_name, phone_e164, tz) VALUES
  ('Asha','Perera','+19015550101','America/Chicago'),
  ('Nimal','Silva','+19015550102','America/Chicago');

INSERT INTO medication (name, dosage) VALUES
  ('Metformin','500 mg'),
  ('Lisinopril','10 mg');

INSERT INTO medication_schedule (patient_id, medication_id, frequency_minutes, next_dose_at)
VALUES
  (1, 1, 480, UTC_TIMESTAMP()),  -- Asha: Metformin every 8h, due now
  (2, 2, 1440, UTC_TIMESTAMP()); -- Nimal: Lisinopril daily, due now
