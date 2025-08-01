-- blueriver_batch_process_data.sql

-- Optional: keep UTC so timestamps match the feed
SET time_zone = '+00:00';

CREATE DATABASE IF NOT EXISTS card_dev;
USE card_dev;

CREATE TABLE IF NOT EXISTS clinician_contact (
  clinician_id     VARCHAR(32) PRIMARY KEY,
  npi              VARCHAR(20) UNIQUE,
  first_name       VARCHAR(255) NOT NULL,
  middle_name      VARCHAR(255),
  last_name        VARCHAR(255) NOT NULL,
  email            VARCHAR(320),
  phone_mobile     VARCHAR(32),
  phone_office     VARCHAR(32),
  pager            VARCHAR(32),
  department       VARCHAR(255),
  specialty        VARCHAR(255),
  facility_code    VARCHAR(64),
  facility_name    VARCHAR(255),
  status           ENUM('ACTIVE','INACTIVE') NOT NULL,
  effective_from   DATE,
  updated_at       DATETIME NOT NULL,
  source_file      VARCHAR(255),
  last_ingested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ========== Batch: 2025-07-27 ==========
INSERT INTO clinician_contact (
  clinician_id, npi, first_name, middle_name, last_name, email,
  phone_mobile, phone_office, pager, department, specialty,
  facility_code, facility_name, status, effective_from, updated_at, source_file
) VALUES
('C1001','1234567890','Asha',NULL,'Perera','asha.perera@blueriver.org',
 '+19015550011','+19015550001','5001','Cardiology','Interventional Cardiology',
 'BLR-MEM','BlueRiver Memphis','ACTIVE','2023-01-15','2025-07-27 02:00:00','clinician_contacts_2025-07-27.json')
ON DUPLICATE KEY UPDATE
  npi=VALUES(npi), first_name=VALUES(first_name), middle_name=VALUES(middle_name),
  last_name=VALUES(last_name), email=VALUES(email),
  phone_mobile=VALUES(phone_mobile), phone_office=VALUES(phone_office), pager=VALUES(pager),
  department=VALUES(department), specialty=VALUES(specialty),
  facility_code=VALUES(facility_code), facility_name=VALUES(facility_name),
  status=VALUES(status), effective_from=VALUES(effective_from),
  updated_at=VALUES(updated_at), source_file=VALUES(source_file),
  last_ingested_at=CURRENT_TIMESTAMP;

