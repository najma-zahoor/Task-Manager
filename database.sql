-- ============================================================
-- TASK MANAGER SYSTEM - COMPLETE DATABASE SETUP
-- ============================================================
-- This file contains all the SQL commands needed to set up
-- the database for your Task Manager System.
-- 
-- HOW TO USE THIS FILE:
-- 1. Open MySQL Workbench or your MySQL command line
-- 2. Copy and paste this entire file
-- 3. Run it to create the database and all tables
-- ============================================================

-- ============================================================
-- STEP 1: CREATE THE DATABASE
-- ============================================================
-- This creates a new database named 'taskmanager'
-- If it already exists, we'll delete it and start fresh
-- ============================================================

DROP DATABASE IF EXISTS taskmanager;
CREATE DATABASE taskmanager;
USE taskmanager;

-- ============================================================
-- STEP 2: CREATE TABLES
-- ============================================================
-- Tables are like folders that organize our data
-- Each table stores different types of information
-- ============================================================

-- ============================================================
-- TABLE 1: users
-- ============================================================
-- Stores all user accounts in the system
-- Every person who uses the system will have a record here
-- ============================================================

CREATE TABLE users (
    -- id: A unique number for each user (like a student ID)
    -- AUTO_INCREMENT means MySQL automatically gives a new number
    -- PRIMARY KEY means this is the main way to find a user
    id INT PRIMARY KEY AUTO_INCREMENT,
    
    -- email: User's login email (must be unique)
    -- VARCHAR(255) means text up to 255 characters
    -- UNIQUE means no two users can have the same email
    email VARCHAR(255) UNIQUE NOT NULL,
    
    -- password: User's password (will be encrypted in a real app)
    -- NOT NULL means this field must have a value
    password VARCHAR(255) NOT NULL,
    
    -- full_name: User's complete name
    full_name VARCHAR(255) NOT NULL,
    
    -- role: What type of user they are
    -- admin = can do everything
    -- manager = can manage team tasks
    -- employee = regular worker
    -- DEFAULT 'employee' means if not specified, they're an employee
    role ENUM('admin', 'manager', 'employee') DEFAULT 'employee',
    
    -- status: Is the user active or inactive?
    -- active = can login and work
    -- inactive = cannot login
    -- DEFAULT 'active' means new users can login immediately
    status ENUM('active', 'inactive') DEFAULT 'active',
    
    -- profile_picture: URL to user's profile picture (optional)
    profile_picture VARCHAR(255) DEFAULT NULL,
    
    -- department: Which department the user works in
    department VARCHAR(100) DEFAULT NULL,
    
    -- created_at: When the user account was created
    -- TIMESTAMP = date and time
    -- DEFAULT CURRENT_TIMESTAMP = automatically set to now
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- updated_at: When the user info was last updated
    -- ON UPDATE CURRENT_TIMESTAMP = automatically update when changed
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================================
-- TABLE 2: tasks
-- ============================================================
-- Stores all tasks in the system
-- Each task has a title, description, status, priority, etc.
-- ============================================================

CREATE TABLE tasks (
    -- id: Unique number for each task
    id INT PRIMARY KEY AUTO_INCREMENT,
    
    -- title: Short name of the task
    title VARCHAR(255) NOT NULL,
    
    -- description: Detailed information about the task
    -- TEXT means longer text without length limit
    description TEXT,
    
    -- status: Current progress of the task
    -- pending = not started
    -- in_progress = working on it
    -- completed = finished
    -- on_hold = temporarily paused
    status ENUM('pending', 'in_progress', 'completed', 'on_hold') DEFAULT 'pending',
    
    -- priority: How important is this task
    -- high = do immediately
    -- medium = important but not urgent
    -- low = can wait
    priority ENUM('high', 'medium', 'low') DEFAULT 'medium',
    
    -- assigned_to: Which employee is working on this task
    -- FOREIGN KEY means this must match an id from users table
    -- ON DELETE SET NULL = if user is deleted, set this to NULL
    assigned_to INT,
    
    -- created_by: Who created this task
    -- FOREIGN KEY references the users table
    created_by INT NOT NULL,
    
    -- due_date: When the task must be completed
    -- DATE = only date, no time
    due_date DATE,
    
    -- completion_date: When the task was actually completed
    completion_date DATE DEFAULT NULL,
    
    -- progress_percentage: How much is done (0-100)
    progress_percentage INT DEFAULT 0,
    
    -- created_at: When task was created
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- updated_at: When task was last updated
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- FOREIGN KEY constraints - these are like rules that:
    -- 1. assigned_to must be a valid user id
    -- 2. created_by must be a valid user id
    FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================
-- TABLE 3: task_comments
-- ============================================================
-- Stores comments made on tasks
-- Users can add comments to discuss tasks
-- ============================================================

CREATE TABLE task_comments (
    -- id: Unique number for each comment
    id INT PRIMARY KEY AUTO_INCREMENT,
    
    -- task_id: Which task this comment is for
    task_id INT NOT NULL,
    
    -- user_id: Who wrote the comment
    user_id INT NOT NULL,
    
    -- comment: The actual comment text
    comment TEXT NOT NULL,
    
    -- created_at: When the comment was posted
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- updated_at: When comment was last edited
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- FOREIGN KEY constraints:
    -- 1. task_id must be a valid task
    -- 2. user_id must be a valid user
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================
-- TABLE 4: task_attachments
-- ============================================================
-- Stores files attached to tasks
-- Users can upload documents, images, etc.
-- ============================================================

CREATE TABLE task_attachments (
    -- id: Unique number for each attachment
    id INT PRIMARY KEY AUTO_INCREMENT,
    
    -- task_id: Which task this attachment is for
    task_id INT NOT NULL,
    
    -- uploaded_by: Who uploaded this file
    uploaded_by INT NOT NULL,
    
    -- file_name: Original name of the file
    file_name VARCHAR(255) NOT NULL,
    
    -- file_path: Where the file is stored on the server
    file_path VARCHAR(500) NOT NULL,
    
    -- file_size: Size of the file in bytes
    file_size INT DEFAULT 0,
    
    -- file_type: MIME type (e.g., 'image/jpeg', 'application/pdf')
    file_type VARCHAR(100) DEFAULT NULL,
    
    -- uploaded_at: When the file was uploaded
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- FOREIGN KEY constraints
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================
-- TABLE 5: subtasks
-- ============================================================
-- Stores subtasks - smaller tasks that are part of a main task
-- Example: Main task "Build Website" has subtasks like:
-- 1. Design homepage
-- 2. Create login page
-- 3. Test functionality
-- ============================================================

CREATE TABLE subtasks (
    -- id: Unique number for each subtask
    id INT PRIMARY KEY AUTO_INCREMENT,
    
    -- task_id: Which main task this subtask belongs to
    task_id INT NOT NULL,
    
    -- title: Name of the subtask
    title VARCHAR(255) NOT NULL,
    
    -- description: Details about the subtask
    description TEXT,
    
    -- status: Is this subtask done or not?
    is_completed BOOLEAN DEFAULT FALSE,
    
    -- assigned_to: Who is working on this subtask
    assigned_to INT,
    
    -- created_at: When subtask was created
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- updated_at: When subtask was last updated
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- FOREIGN KEY constraints
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL
);

-- ============================================================
-- TABLE 6: notifications
-- ============================================================
-- Stores notifications for users
-- Examples: "Task assigned to you", "Task deadline approaching", etc.
-- ============================================================

CREATE TABLE notifications (
    -- id: Unique number for each notification
    id INT PRIMARY KEY AUTO_INCREMENT,
    
    -- user_id: Who should receive this notification
    user_id INT NOT NULL,
    
    -- type: What kind of notification
    -- task_assigned = new task assigned
    -- task_updated = task was changed
    -- task_completed = task was completed
    -- due_reminder = deadline approaching
    -- overdue = task is overdue
    -- comment_added = someone commented
    type ENUM('task_assigned', 'task_updated', 'task_completed', 
              'due_reminder', 'overdue', 'comment_added') NOT NULL,
    
    -- message: The notification text
    message TEXT NOT NULL,
    
    -- task_id: Which task this notification is about (optional)
    task_id INT DEFAULT NULL,
    
    -- is_read: Has the user seen this notification?
    -- FALSE by default (unread)
    is_read BOOLEAN DEFAULT FALSE,
    
    -- created_at: When the notification was created
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- FOREIGN KEY constraints
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);

-- ============================================================
-- TABLE 7: activity_logs
-- ============================================================
-- Tracks all user activities for security and monitoring
-- Every action a user takes is recorded here
-- ============================================================

CREATE TABLE activity_logs (
    -- id: Unique number for each log entry
    id INT PRIMARY KEY AUTO_INCREMENT,
    
    -- user_id: Who performed the action
    user_id INT NOT NULL,
    
    -- action: What they did
    -- Examples: 'login', 'create_task', 'update_task', 'delete_user'
    action VARCHAR(100) NOT NULL,
    
    -- description: More details about the action
    description TEXT,
    
    -- ip_address: IP address of the user
    ip_address VARCHAR(45),
    
    -- user_agent: Browser and device information
    user_agent TEXT,
    
    -- created_at: When the action occurred
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- FOREIGN KEY constraint
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================
-- STEP 3: ADD SAMPLE DATA
-- ============================================================
-- These are example users and tasks to get you started
-- You can use these to test the system
-- ============================================================

-- ============================================================
-- Insert Admin User
-- ============================================================
-- Creates the main administrator account
-- Email: admin@taskmanager.com
-- Password: admin123 (in real app, this would be hashed)
-- ============================================================

INSERT INTO users (email, password, full_name, role, status, department)
VALUES ('admin@taskmanager.com', 'admin123', 'System Admin', 'admin', 'active', 'IT');

-- ============================================================
-- Insert Manager User
-- ============================================================

INSERT INTO users (email, password, full_name, role, status, department)
VALUES ('manager@taskmanager.com', 'manager123', 'John Manager', 'manager', 'active', 'Development');

-- ============================================================
-- Insert Employee Users
-- ============================================================

INSERT INTO users (email, password, full_name, role, status, department)
VALUES 
('employee1@taskmanager.com', 'employee123', 'Sarah Worker', 'employee', 'active', 'Development'),
('employee2@taskmanager.com', 'employee123', 'Mike Developer', 'employee', 'active', 'Development'),
('employee3@taskmanager.com', 'employee123', 'Lisa Designer', 'employee', 'active', 'Design');

-- ============================================================
-- Insert Sample Tasks
-- ============================================================

-- Task 1: High priority task assigned to Sarah
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, due_date)
VALUES (
    'Design Homepage Layout', 
    'Create a modern homepage layout with responsive design. Include header, footer, and main content area.',
    'in_progress', 
    'high', 
    4, -- Sarah's id (employee1)
    1, -- Admin's id
    DATE_ADD(CURDATE(), INTERVAL 7 DAY) -- Due in 7 days
);

-- Task 2: Medium priority task assigned to Mike
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, due_date)
VALUES (
    'Implement Login System',
    'Create a secure login system with JWT authentication. Include forgot password functionality.',
    'pending',
    'medium',
    5, -- Mike's id (employee2)
    2, -- Manager's id
    DATE_ADD(CURDATE(), INTERVAL 14 DAY) -- Due in 14 days
);

-- Task 3: Low priority task assigned to Lisa
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, due_date)
VALUES (
    'Update Logo Design',
    'Redesign the company logo with modern colors. Provide 3 variations.',
    'pending',
    'low',
    6, -- Lisa's id (employee3)
    1, -- Admin's id
    DATE_ADD(CURDATE(), INTERVAL 5 DAY) -- Due in 5 days
);

-- Task 4: Completed task (for demonstration)
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, due_date, completion_date)
VALUES (
    'Database Schema Design',
    'Design the complete database schema for the task manager system.',
    'completed',
    'high',
    4, -- Sarah's id
    2, -- Manager's id
    DATE_SUB(CURDATE(), INTERVAL 3 DAY),
    CURDATE() -- Completed today
);

-- ============================================================
-- Insert Sample Task Comments
-- ============================================================

INSERT INTO task_comments (task_id, user_id, comment)
VALUES 
(1, 4, 'I have started working on the homepage layout. Will share the first draft by tomorrow.'),
(1, 1, 'Great! Please focus on mobile responsiveness as well.'),
(2, 5, 'I need to research JWT authentication best practices for this.');

-- ============================================================
-- Insert Sample Subtasks (for Task 1)
-- ============================================================

INSERT INTO subtasks (task_id, title, description, is_completed, assigned_to)
VALUES 
(1, 'Create Wireframe', 'Design the basic layout structure', TRUE, 4),
(1, 'Design Header', 'Create the header with navigation', FALSE, 4),
(1, 'Design Footer', 'Create the footer with links', FALSE, 4);

-- ============================================================
-- Insert Sample Notifications
-- ============================================================

INSERT INTO notifications (user_id, type, message, task_id)
VALUES 
(4, 'task_assigned', 'You have been assigned a new task: Design Homepage Layout', 1),
(5, 'task_assigned', 'You have been assigned a new task: Implement Login System', 2),
(6, 'task_assigned', 'You have been assigned a new task: Update Logo Design', 3);

-- ============================================================
-- Insert Sample Activity Logs
-- ============================================================

INSERT INTO activity_logs (user_id, action, description, ip_address)
VALUES 
(1, 'login', 'Admin logged into the system', '192.168.1.100'),
(1, 'create_task', 'Admin created task: Design Homepage Layout', '192.168.1.100'),
(4, 'login', 'Sarah Worker logged into the system', '192.168.1.101'),
(4, 'update_task', 'Sarah updated task status to In Progress', '192.168.1.101');

-- ============================================================
-- STEP 4: CREATE USEFUL VIEWS
-- ============================================================
-- Views are like virtual tables that make it easier to
-- get specific information without complex queries
-- ============================================================

-- ============================================================
-- View 1: Task Details with User Names
-- ============================================================
-- Shows task information with the names of assigned 
-- employee and the creator instead of just IDs
-- ============================================================

CREATE VIEW task_details AS
SELECT 
    t.id AS task_id,
    t.title AS task_title,
    t.description,
    t.status,
    t.priority,
    t.due_date,
    t.completion_date,
    t.progress_percentage,
    -- Get the assigned employee's name
    assigned_user.full_name AS assigned_to_name,
    -- Get the creator's name
    creator.full_name AS created_by_name,
    -- Show when it was created and last updated
    t.created_at,
    t.updated_at
FROM tasks t
-- Join with users table to get the assigned employee's info
LEFT JOIN users assigned_user ON t.assigned_to = assigned_user.id
-- Join with users table to get the creator's info
JOIN users creator ON t.created_by = creator.id;

-- ============================================================
-- View 2: Task Statistics by User
-- ============================================================
-- Shows how many tasks each user has in each status
-- ============================================================

CREATE VIEW task_statistics AS
SELECT 
    u.id AS user_id,
    u.full_name,
    u.department,
    -- Count tasks in each status
    COUNT(CASE WHEN t.status = 'pending' THEN 1 END) AS pending_tasks,
    COUNT(CASE WHEN t.status = 'in_progress' THEN 1 END) AS in_progress_tasks,
    COUNT(CASE WHEN t.status = 'completed' THEN 1 END) AS completed_tasks,
    COUNT(CASE WHEN t.status = 'on_hold' THEN 1 END) AS on_hold_tasks,
    -- Total tasks
    COUNT(t.id) AS total_tasks
FROM users u
-- Left join with tasks table
LEFT JOIN tasks t ON u.id = t.assigned_to
-- Only include employees (not admins or managers)
WHERE u.role = 'employee'
-- Group by user to get counts per user
GROUP BY u.id;

-- ============================================================
-- View 3: Overdue Tasks
-- ============================================================
-- Shows all tasks that are past their due date and not completed
-- ============================================================

CREATE VIEW overdue_tasks AS
SELECT 
    t.id AS task_id,
    t.title,
    t.due_date,
    -- Calculate how many days overdue
    DATEDIFF(CURDATE(), t.due_date) AS days_overdue,
    u.full_name AS assigned_to,
    t.priority,
    t.status
FROM tasks t
JOIN users u ON t.assigned_to = u.id
WHERE 
    -- Due date has passed
    t.due_date < CURDATE()
    -- Task is not completed
    AND t.status != 'completed';

-- ============================================================
-- STEP 5: CREATE USEFUL INDEXES
-- ============================================================
-- Indexes make your database queries faster
-- ============================================================

-- Index for faster task searches by status
CREATE INDEX idx_task_status ON tasks(status);

-- Index for faster task searches by priority
CREATE INDEX idx_task_priority ON tasks(priority);

-- Index for faster task searches by due date
CREATE INDEX idx_task_due_date ON tasks(due_date);

-- Index for faster user searches by role
CREATE INDEX idx_user_role ON users(role);

-- Index for faster notification searches by user and read status
CREATE INDEX idx_notification_user_read ON notifications(user_id, is_read);

-- ============================================================
-- STEP 6: CREATE STORED PROCEDURES
-- ============================================================
-- Stored procedures are like functions that you can call
-- They make common operations easier
-- ============================================================

-- ============================================================
-- Procedure 1: Get User Tasks
-- ============================================================
-- Gets all tasks for a specific user
-- Usage: CALL get_user_tasks(4); -- Gets tasks for user with id 4
-- ============================================================

DELIMITER //

CREATE PROCEDURE get_user_tasks(IN user_id_param INT)
BEGIN
    SELECT 
        t.id,
        t.title,
        t.description,
        t.status,
        t.priority,
        t.due_date,
        t.progress_percentage,
        t.created_at,
        -- Get the creator's name
        creator.full_name AS created_by_name
    FROM tasks t
    JOIN users creator ON t.created_by = creator.id
    WHERE t.assigned_to = user_id_param
    ORDER BY t.due_date ASC;
END //

DELIMITER ;

-- ============================================================
-- Procedure 2: Mark Task as Complete
-- ============================================================
-- Updates a task to completed status and sets the completion date
-- Usage: CALL mark_task_complete(1); -- Marks task with id 1 as complete
-- ============================================================

DELIMITER //

CREATE PROCEDURE mark_task_complete(IN task_id_param INT)
BEGIN
    -- Update the task
    UPDATE tasks 
    SET 
        status = 'completed',
        completion_date = CURDATE(),
        progress_percentage = 100,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = task_id_param;
    
    -- Create a notification for the task creator
    INSERT INTO notifications (user_id, type, message, task_id)
    SELECT 
        created_by,
        'task_completed',
        CONCAT('Task "', title, '" has been completed.'),
        id
    FROM tasks
    WHERE id = task_id_param;
END //

DELIMITER ;

-- ============================================================
-- Procedure 3: Get Dashboard Statistics
-- ============================================================
-- Gets all statistics for the admin dashboard
-- Usage: CALL get_dashboard_stats();
-- ============================================================

DELIMITER //

CREATE PROCEDURE get_dashboard_stats()
BEGIN
    -- Total tasks
    SELECT COUNT(*) AS total_tasks FROM tasks;
    
    -- Completed tasks
    SELECT COUNT(*) AS completed_tasks FROM tasks WHERE status = 'completed';
    
    -- Pending tasks
    SELECT COUNT(*) AS pending_tasks FROM tasks WHERE status = 'pending' OR status = 'on_hold';
    
    -- In progress tasks
    SELECT COUNT(*) AS in_progress_tasks FROM tasks WHERE status = 'in_progress';
    
    -- Overdue tasks
    SELECT COUNT(*) AS overdue_tasks 
    FROM tasks 
    WHERE due_date < CURDATE() AND status != 'completed';
    
    -- Total users
    SELECT COUNT(*) AS total_users FROM users;
    
    -- Active users
    SELECT COUNT(*) AS active_users FROM users WHERE status = 'active';
END //

DELIMITER ;

-- ============================================================
-- STEP 7: QUICK REFERENCE - USEFUL QUERIES
-- ============================================================
-- Here are some common queries you might use in your React app
-- ============================================================

-- ============================================================
-- Example Query 1: Get all active employees
-- ============================================================
-- SELECT * FROM users WHERE role = 'employee' AND status = 'active';

-- ============================================================
-- Example Query 2: Get all tasks assigned to a specific employee
-- ============================================================
-- SELECT * FROM tasks WHERE assigned_to = 4; -- 4 is the user ID

-- ============================================================
-- Example Query 3: Get all comments for a specific task
-- ============================================================
-- SELECT c.*, u.full_name 
-- FROM task_comments c
-- JOIN users u ON c.user_id = u.id
-- WHERE c.task_id = 1
-- ORDER BY c.created_at DESC;

-- ============================================================
-- Example Query 4: Get unread notifications for a user
-- ============================================================
-- SELECT * FROM notifications 
-- WHERE user_id = 4 AND is_read = FALSE
-- ORDER BY created_at DESC;

-- ============================================================
-- Example Query 5: Get task completion rate by employee
-- ============================================================
-- SELECT 
--     u.full_name,
--     COUNT(t.id) AS total_tasks,
--     SUM(CASE WHEN t.status = 'completed' THEN 1 ELSE 0 END) AS completed_tasks,
--     ROUND((SUM(CASE WHEN t.status = 'completed' THEN 1 ELSE 0 END) * 100.0) / COUNT(t.id), 2) AS completion_rate
-- FROM users u
-- LEFT JOIN tasks t ON u.id = t.assigned_to
-- WHERE u.role = 'employee'
-- GROUP BY u.id;

-- ============================================================
-- END OF DATABASE SETUP
-- ============================================================
-- CONGRATULATIONS! Your database is now ready to use!
-- 
-- Next Steps:
-- 1. Connect your React app to this database using a Node.js backend
-- 2. Use Express.js and mysql2 package for database connection
-- 3. Test the queries above in your backend code
-- ============================================================