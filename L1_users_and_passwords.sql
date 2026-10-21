-- =====================================================================
-- CSC2209  |  DATABASE SECURITY  |  LECTURE 1
-- L1_users_and_passwords.sql
-- Sections covered: 1 (DCL, CIA, authN vs authZ)
--                   2 (users & authentication)
--                   3 (password management & account locking)
-- ---------------------------------------------------------------------
-- HOW TO USE THIS SCRIPT
--   * Run 00_setup_uni_portal.sql first.
--   * Open TWO terminals in VS Code:
--       Terminal 1 = root            ->  mysql -u root -p
--       Terminal 2 = the test user   ->  mysql -u <user> -p
--   * Lines WITHOUT "--" are run in Terminal 1 (root).
--   * Blocks marked  [TERMINAL 2 as <user>]  are commented out; copy
--     them into Terminal 2 yourself. They show what the USER sees.
--   * Tested on MySQL 8.0.46. Needs MySQL 8.0.19 or newer.
-- =====================================================================

USE uni_portal;

-- Clean up from any previous run (so the script can be re-run)
DROP USER IF EXISTS 'sarah'@'localhost', 'peter'@'localhost',
                    'john'@'localhost',  'john'@'%',
                    'mary'@'localhost',  'mary_n'@'localhost',
                    'intern'@'localhost', 'guest'@'localhost';


-- =====================================================================
-- PART 1.  AUTHENTICATION vs AUTHORIZATION  (see it, don't just hear it)
-- =====================================================================
-- Authentication = "WHO are you?"      -> username + password (+ host)
-- Authorization  = "WHAT may you do?"  -> privileges (GRANT / REVOKE)

CREATE USER 'guest'@'localhost' IDENTIFIED BY 'Guest#2026';

-- [TERMINAL 2] Wrong password  -> AUTHENTICATION fails:
--    mysql -u guest -p          (type a wrong password)
--    ERROR 1045 (28000): Access denied for user 'guest'@'localhost' (using password: YES)
--
-- [TERMINAL 2] Right password  -> logged in, but has NO privileges yet:
--    mysql -u guest -p          (type Guest#2026)
--    mysql> SELECT * FROM uni_portal.students;
--    ERROR 1142 (42000): SELECT command denied to user 'guest'@'localhost' for table 'students'
--    -> AUTHORIZATION fails. He is "in the building" but every door is locked.

-- DCL = Data Control Language = GRANT and REVOKE. One line opens a door:
GRANT SELECT ON uni_portal.courses TO 'guest'@'localhost';

-- [TERMINAL 2 as guest]
--    mysql> SELECT * FROM uni_portal.courses;     -- works now
--    mysql> SELECT * FROM uni_portal.students;    -- still ERROR 1142

REVOKE SELECT ON uni_portal.courses FROM 'guest'@'localhost';
-- [TERMINAL 2 as guest]  run the SELECT on courses again -> ERROR 1142 again
-- (privilege changes apply immediately; the user does not need to log out)


-- =====================================================================
-- PART 2.  CREATING, VIEWING, MODIFYING AND DELETING USER ACCOUNTS
-- =====================================================================
-- A MySQL account = 'username'@'host'.  The HOST is where the user is
-- allowed to connect FROM.

-- 2.1 Local users (can only connect from the same machine as the server)
CREATE USER 'sarah'@'localhost' IDENTIFIED BY 'Registrar#2026';   -- registrar
CREATE USER 'peter'@'localhost' IDENTIFIED BY 'Bursar#2026';      -- bursar

-- 2.2 Remote users
--   '%'               = from ANY computer        (convenient, least safe)
--   '192.168.10.%'    = only from the lab subnet (safer)
--   '192.168.10.25'   = only from one computer   (safest)
CREATE USER 'john'@'localhost' IDENTIFIED BY 'Lecturer#2026';
CREATE USER 'john'@'%'         IDENTIFIED BY 'Lecturer#Remote1';
-- IMPORTANT: 'john'@'localhost' and 'john'@'%' are TWO DIFFERENT accounts,
-- with different passwords and (later) different privileges.

-- 2.3 Viewing accounts (the user list lives in the system table mysql.user)
SELECT user, host, account_locked, password_expired
FROM mysql.user
WHERE user IN ('guest','sarah','peter','john')
ORDER BY user, host;

-- Who am I logged in as?
SELECT USER(), CURRENT_USER();

-- 2.4 Modifying an account: ALTER USER (password, locking, expiry ...)
ALTER USER 'john'@'%' IDENTIFIED BY 'Lecturer#Remote2';

-- 2.5 Changing a username (or host): RENAME USER
CREATE USER 'mary'@'localhost' IDENTIFIED BY 'Intern#2026';
RENAME USER 'mary'@'localhost' TO 'mary_n'@'localhost';
-- Privileges move with the account; the old name no longer exists.
SELECT user, host FROM mysql.user WHERE user LIKE 'mary%';

-- 2.6 Deleting accounts
DROP USER 'john'@'%';                   -- remove the remote account only
DROP USER IF EXISTS 'mary_n'@'localhost';
DROP USER IF EXISTS 'nobody'@'localhost';   -- IF EXISTS: no error, just a note


-- =====================================================================
-- PART 3.  PASSWORD MANAGEMENT
-- =====================================================================

-- 3.1 Setting / resetting a password (done by the administrator)
ALTER USER 'peter'@'localhost' IDENTIFIED BY 'Bursar#Reset1';

-- 3.2 Force a password change on FIRST LOGIN
CREATE USER 'intern'@'localhost' IDENTIFIED BY 'Temp#1234' PASSWORD EXPIRE;
-- [TERMINAL 2] mysql -u intern -p        (password Temp#1234)
--    mysql> SELECT * FROM uni_portal.courses;
--    ERROR 1820 (HY000): You must reset your password using ALTER USER statement before executing this statement.
--    mysql> ALTER USER USER() IDENTIFIED BY 'MyOwn#Pass1';
--    Query OK, 0 rows affected
--    (Now the account works normally.)

-- You can also expire an EXISTING account's password at any time
-- (e.g. you suspect it was shared). Next login, guest must change it:
ALTER USER 'guest'@'localhost' PASSWORD EXPIRE;

-- 3.3 Password expiry policy (how long a password stays valid)
ALTER USER 'sarah'@'localhost' PASSWORD EXPIRE INTERVAL 90 DAY;  -- change every 90 days
ALTER USER 'john'@'localhost'  PASSWORD EXPIRE NEVER;            -- never expires
-- PASSWORD EXPIRE DEFAULT  -> follow the server-wide setting
SHOW VARIABLES LIKE 'default_password_lifetime';                  -- 0 = never

-- 3.4 Password REUSE policy (stop people recycling old passwords)
ALTER USER 'sarah'@'localhost'
    PASSWORD HISTORY 3                -- cannot reuse any of the last 3 passwords
    PASSWORD REUSE INTERVAL 180 DAY;  -- ...or any password used in the last 180 days

-- 3.5 Users changing THEIR OWN password
--   Require them to type the current password first (stops someone at an
--   unattended, logged-in computer from changing it):
ALTER USER 'sarah'@'localhost' PASSWORD REQUIRE CURRENT;
-- [TERMINAL 2 as sarah]
--    mysql> ALTER USER USER() IDENTIFIED BY 'Registrar#New1';
--    ERROR 3892 (HY000): Current password needs to be specified in the REPLACE clause in order to change it.
--    mysql> ALTER USER USER() IDENTIFIED BY 'Registrar#New1' REPLACE 'Registrar#2026';
--    Query OK
--    mysql> ALTER USER USER() IDENTIFIED BY 'Registrar#New2' REPLACE 'Registrar#New1';
--    Query OK
--    Now try to go BACK to New1 (reuse) -> blocked by PASSWORD HISTORY 3:
--    mysql> ALTER USER USER() IDENTIFIED BY 'Registrar#New1' REPLACE 'Registrar#New2';
--    ERROR 3638 (HY000): Cannot use these credentials for 'sarah@localhost' because they contradict the password history policy
--    NOTE: history only remembers passwords set AFTER the policy was switched
--    on, so put PASSWORD HISTORY in the CREATE USER statement (see 4.5).
--    (Shorter alternative:  SET PASSWORD = 'NewPass' REPLACE 'OldPass';)


-- =====================================================================
-- PART 4.  LOCKING AND UNLOCKING ACCOUNTS
-- =====================================================================

-- 4.1 Manual lock / unlock (e.g. staff member on leave, suspected misuse)
ALTER USER 'peter'@'localhost' ACCOUNT LOCK;
-- [TERMINAL 2] mysql -u peter -p
--    ERROR 3118 (HY000): Access denied for user 'peter'@'localhost'. Account is locked.
ALTER USER 'peter'@'localhost' ACCOUNT UNLOCK;

-- 4.2 TEMPORARY lock after failed login attempts  (MySQL 8.0.19+)
--   FAILED_LOGIN_ATTEMPTS n   -> lock after n wrong passwords IN A ROW
--   PASSWORD_LOCK_TIME d      -> stay locked for d DAYS (whole days only)
--   PASSWORD_LOCK_TIME UNBOUNDED -> stay locked until an admin unlocks it
ALTER USER 'john'@'localhost'
    FAILED_LOGIN_ATTEMPTS 3
    PASSWORD_LOCK_TIME 1;
-- [TERMINAL 2] type a wrong password for john 3 times:
--    ERROR 1045 ... (attempt 1)   ERROR 1045 ... (attempt 2)
--    ERROR 3955 (HY000): Access denied for user 'john'@'localhost'. Account is blocked for 1 day(s) (1 day(s) remaining) due to 3 consecutive failed logins.
--    Even the CORRECT password is now refused until the lock time ends.

-- 4.3 Configuring the lock duration
--   NOTE (tested): any ALTER USER that sets FAILED_LOGIN_ATTEMPTS or
--   PASSWORD_LOCK_TIME also RESETS the counter and unlocks the account.
ALTER USER 'john'@'localhost' PASSWORD_LOCK_TIME 2;          -- 2 days
ALTER USER 'john'@'localhost' PASSWORD_LOCK_TIME UNBOUNDED;  -- until admin unlocks
ALTER USER 'john'@'localhost' PASSWORD_LOCK_TIME 1;          -- back to 1 day

-- 4.4 Admin unlocks early (also resets the failed-attempt counter)
ALTER USER 'john'@'localhost' ACCOUNT UNLOCK;

-- 4.5 Everything in ONE statement (what you will write for your project)
DROP USER IF EXISTS 'intern'@'localhost';
CREATE USER 'intern'@'localhost'
    IDENTIFIED BY 'Temp#1234'
    PASSWORD EXPIRE                 
    PASSWORD HISTORY 3              
    FAILED_LOGIN_ATTEMPTS 3        
    PASSWORD_LOCK_TIME 1;           
-- !! Do NOT put both "PASSWORD EXPIRE" and "PASSWORD EXPIRE INTERVAL n DAY"
--    in the same statement: only the LAST one is kept. If you need both,
--    use CREATE USER ... PASSWORD EXPIRE INTERVAL 90 DAY, then a separate
--    ALTER USER ... PASSWORD EXPIRE;


-- =====================================================================
-- PART 5.  CHECK YOUR WORK  (the "account register")
-- =====================================================================
SELECT user, host,
       account_locked,          -- Y / N  (manual ACCOUNT LOCK)
       password_expired,        -- Y = must change at next login
       password_lifetime,       -- NULL = server default, 0 = never, n = days
       password_reuse_history,
       password_last_changed
FROM mysql.user
WHERE user IN ('guest','sarah','peter','john','intern')
ORDER BY user;

-- SHOW CREATE USER shows ALL the settings of one account in one go:
SHOW CREATE USER 'intern'@'localhost'\G
