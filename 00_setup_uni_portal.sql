-- =====================================================================
-- CSC2209 Database Programming  |  Topic: DATABASE SECURITY
-- 00_setup_uni_portal.sql  -  demo database used in ALL 4 lectures
-- ---------------------------------------------------------------------
-- Run as root (once, before Lecture 1). Safe to re-run: it drops and
-- recreates everything.
--
--   Option A (inside the mysql> prompt):
--       mysql> SOURCE "path/to/this/file";
--   Option B (from a terminal / cmd):
--       mysql -u root -p < 00_setup_uni_portal.sql
--   (In PowerShell "<" does not work, so use Option A there.)
--
-- NOTE: Use forward slashes (/) in SOURCE paths, even on Windows.
-- Tested on MySQL 8.0.46.
-- =====================================================================

DROP DATABASE IF EXISTS uni_portal;
CREATE DATABASE uni_portal;
USE uni_portal;

-- Students -------------------------------------------------------------
CREATE TABLE students (
    student_id    INT AUTO_INCREMENT PRIMARY KEY,
    reg_no        VARCHAR(20)  NOT NULL UNIQUE,
    first_name    VARCHAR(50)  NOT NULL,
    last_name     VARCHAR(50)  NOT NULL,
    email         VARCHAR(100) NOT NULL,
    phone         VARCHAR(15),
    date_of_birth DATE,
    programme     VARCHAR(20)  NOT NULL
);

-- Courses ----------------------------------------------------------------
CREATE TABLE courses (
    course_code  VARCHAR(10) PRIMARY KEY,
    title        VARCHAR(100) NOT NULL,
    credit_units INT NOT NULL
);

-- Enrollments (with marks) ----------------------------------------------
CREATE TABLE enrollments (
    enrollment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id    INT NOT NULL,
    course_code   VARCHAR(10) NOT NULL,
    marks         DECIMAL(5,2),
    FOREIGN KEY (student_id)  REFERENCES students(student_id),
    FOREIGN KEY (course_code) REFERENCES courses(course_code)
);

-- Fee payments (sensitive: money) ---------------------------------------
CREATE TABLE fee_payments (
    payment_id  INT AUTO_INCREMENT PRIMARY KEY,
    student_id  INT NOT NULL,
    amount      DECIMAL(12,2) NOT NULL,
    paid_on     DATE NOT NULL,
    received_by VARCHAR(50) NOT NULL,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

-- Sample data ------------------------------------------------------------
INSERT INTO students (reg_no, first_name, last_name, email, phone, date_of_birth, programme) VALUES
('S24B23/001', 'Aisha',   'Namuli',   'anamuli@students.ucu.ac.ug',   '0772000001', '2004-03-12', 'BSIT'),
('S24B23/002', 'Brian',   'Okello',   'bokello@students.ucu.ac.ug',   '0772000002', '2003-11-05', 'BSIT'),
('S24B23/003', 'Carol',   'Atim',     'catim@students.ucu.ac.ug',     '0772000003', '2004-07-21', 'BSIT'),
('S24B23/004', 'Daniel',  'Mugisha',  'dmugisha@students.ucu.ac.ug',  '0772000004', '2002-01-30', 'BSCS'),
('S24B23/005', 'Esther',  'Nakato',   'enakato@students.ucu.ac.ug',   '0772000005', '2004-09-09', 'BSIT');

INSERT INTO courses VALUES
('CSC2209', 'Database Programming',        4),
('CSC2210', 'Object Oriented Programming', 4),
('CSC2211', 'Computer Networks',           3);

INSERT INTO enrollments (student_id, course_code, marks) VALUES
(1, 'CSC2209', 78.0), (1, 'CSC2210', 65.5),
(2, 'CSC2209', 54.0), (2, 'CSC2211', 71.0),
(3, 'CSC2209', 88.5), (4, 'CSC2210', 49.0),
(5, 'CSC2209', 62.0), (5, 'CSC2211', 80.0);

INSERT INTO fee_payments (student_id, amount, paid_on, received_by) VALUES
(1, 1500000.00, '2026-08-10', 'bursar_office'),
(2,  800000.00, '2026-08-12', 'bursar_office'),
(3, 1500000.00, '2026-08-15', 'bursar_office'),
(4, 1200000.00, '2026-08-20', 'bursar_office'),
(5,  500000.00, '2026-09-01', 'bursar_office');

SELECT 'uni_portal is ready' AS status;
SELECT table_name, table_rows
FROM information_schema.tables
WHERE table_schema = 'uni_portal';
