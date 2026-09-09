// server.js - Full Version with All Features
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// ============================================================
// MIDDLEWARE
// ============================================================
app.use(cors());
app.use(express.json());

// ============================================================
// DATABASE CONNECTION
// ============================================================
const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'taskmanager',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

const promisePool = pool.promise();

// ============================================================
// MIDDLEWARE - Authentication
// ============================================================
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ 
            success: false, 
            message: 'Access denied. No token provided.' 
        });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secretkey');
        req.user = decoded;
        next();
    } catch (error) {
        return res.status(403).json({ 
            success: false, 
            message: 'Invalid or expired token.' 
        });
    }
};

// ============================================================
// AUTH ROUTES
// ============================================================

// Register
app.post('/api/auth/register', async (req, res) => {
    try {
        const { email, password, full_name, role, department } = req.body;

        // Check if user exists
        const [existing] = await promisePool.query(
            'SELECT id FROM users WHERE email = ?',
            [email]
        );

        if (existing.length > 0) {
            return res.status(400).json({
                success: false,
                message: 'User already exists'
            });
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Insert user
        const [result] = await promisePool.query(
            `INSERT INTO users (email, password, full_name, role, department, status) 
             VALUES (?, ?, ?, ?, ?, 'active')`,
            [email, hashedPassword, full_name, role || 'employee', department]
        );

        res.status(201).json({
            success: true,
            message: 'User registered successfully',
            userId: result.insertId
        });

    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// Login
app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        // Find user
        const [users] = await promisePool.query(
            'SELECT * FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'Invalid credentials'
            });
        }

        const user = users[0];

        // Check password
        const isValid = await bcrypt.compare(password, user.password);
        if (!isValid) {
            return res.status(401).json({
                success: false,
                message: 'Invalid credentials'
            });
        }

        // Check if active
        if (user.status === 'inactive') {
            return res.status(403).json({
                success: false,
                message: 'Account is deactivated'
            });
        }

        // Create token
        const token = jwt.sign(
            { id: user.id, email: user.email, role: user.role },
            process.env.JWT_SECRET || 'secretkey',
            { expiresIn: '24h' }
        );

        // Log activity
        await promisePool.query(
            'INSERT INTO activity_logs (user_id, action, description, ip_address) VALUES (?, ?, ?, ?)',
            [user.id, 'login', 'User logged in', req.ip]
        );

        // Remove password from response
        delete user.password;

        res.json({
            success: true,
            message: 'Login successful',
            token,
            user
        });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// ============================================================
// USER ROUTES
// ============================================================

// Get all users
app.get('/api/users', authenticateToken, async (req, res) => {
    try {
        const [users] = await promisePool.query(
            'SELECT id, email, full_name, role, status, department, created_at FROM users ORDER BY created_at DESC'
        );

        res.json({
            success: true,
            users
        });

    } catch (error) {
        console.error('Get users error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// Get single user
app.get('/api/users/:id', authenticateToken, async (req, res) => {
    try {
        const [users] = await promisePool.query(
            'SELECT id, email, full_name, role, status, department, created_at FROM users WHERE id = ?',
            [req.params.id]
        );

        if (users.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        res.json({
            success: true,
            user: users[0]
        });

    } catch (error) {
        console.error('Get user error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// Create user (admin only)
app.post('/api/users', authenticateToken, async (req, res) => {
    try {
        // Check if admin
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Admin access required'
            });
        }

        const { email, password, full_name, role, department } = req.body;

        // Check if user exists
        const [existing] = await promisePool.query(
            'SELECT id FROM users WHERE email = ?',
            [email]
        );

        if (existing.length > 0) {
            return res.status(400).json({
                success: false,
                message: 'User already exists'
            });
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Insert user
        const [result] = await promisePool.query(
            `INSERT INTO users (email, password, full_name, role, department, status) 
             VALUES (?, ?, ?, ?, ?, 'active')`,
            [email, hashedPassword, full_name, role || 'employee', department]
        );

        // Log activity
        await promisePool.query(
            'INSERT INTO activity_logs (user_id, action, description) VALUES (?, ?, ?)',
            [req.user.id, 'create_user', `Created user: ${email}`]
        );

        res.status(201).json({
            success: true,
            message: 'User created successfully',
            userId: result.insertId
        });

    } catch (error) {
        console.error('Create user error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// Update user
app.put('/api/users/:id', authenticateToken, async (req, res) => {
    try {
        const { full_name, role, department, status } = req.body;
        const userId = req.params.id;

        // Check if user exists
        const [users] = await promisePool.query(
            'SELECT id FROM users WHERE id = ?',
            [userId]
        );

        if (users.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        // Build update query
        const updates = [];
        const values = [];

        if (full_name) {
            updates.push('full_name = ?');
            values.push(full_name);
        }
        if (role) {
            updates.push('role = ?');
            values.push(role);
        }
        if (department) {
            updates.push('department = ?');
            values.push(department);
        }
        if (status) {
            updates.push('status = ?');
            values.push(status);
        }

        if (updates.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'No fields to update'
            });
        }

        values.push(userId);
        await promisePool.query(
            `UPDATE users SET ${updates.join(', ')} WHERE id = ?`,
            values
        );

        // Log activity
        await promisePool.query(
            'INSERT INTO activity_logs (user_id, action, description) VALUES (?, ?, ?)',
            [req.user.id, 'update_user', `Updated user ID: ${userId}`]
        );

        res.json({
            success: true,
            message: 'User updated successfully'
        });

    } catch (error) {
        console.error('Update user error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// Delete user
app.delete('/api/users/:id', authenticateToken, async (req, res) => {
    try {
        // Check if admin
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Admin access required'
            });
        }

        const userId = req.params.id;

        // Check if user exists
        const [users] = await promisePool.query(
            'SELECT id, email FROM users WHERE id = ?',
            [userId]
        );

        if (users.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        // Prevent deleting yourself
        if (userId == req.user.id) {
            return res.status(400).json({
                success: false,
                message: 'Cannot delete your own account'
            });
        }

        await promisePool.query('DELETE FROM users WHERE id = ?', [userId]);

        // Log activity
        await promisePool.query(
            'INSERT INTO activity_logs (user_id, action, description) VALUES (?, ?, ?)',
            [req.user.id, 'delete_user', `Deleted user: ${users[0].email}`]
        );

        res.json({
            success: true,
            message: 'User deleted successfully'
        });

    } catch (error) {
        console.error('Delete user error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// ============================================================
// TASK ROUTES
// ============================================================

// Get all tasks
app.get('/api/tasks', authenticateToken, async (req, res) => {
    try {
        let query = `
            SELECT 
                t.*,
                assigned.full_name as assigned_to_name,
                creator.full_name as created_by_name
            FROM tasks t
            LEFT JOIN users assigned ON t.assigned_to = assigned.id
            LEFT JOIN users creator ON t.created_by = creator.id
        `;
        const params = [];

        // If employee, only show their tasks
        if (req.user.role === 'employee') {
            query += ' WHERE t.assigned_to = ?';
            params.push(req.user.id);
        }

        query += ' ORDER BY t.created_at DESC';

        const [tasks] = await promisePool.query(query, params);

        res.json({
            success: true,
            tasks
        });

    } catch (error) {
        console.error('Get tasks error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// Get single task
app.get('/api/tasks/:id', authenticateToken, async (req, res) => {
    try {
        const [tasks] = await promisePool.query(
            `SELECT 
                t.*,
                assigned.full_name as assigned_to_name,
                creator.full_name as created_by_name
            FROM tasks t
            LEFT JOIN users assigned ON t.assigned_to = assigned.id
            LEFT JOIN users creator ON t.created_by = creator.id
            WHERE t.id = ?`,
            [req.params.id]
        );

        if (tasks.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Task not found'
            });
        }

        // Get comments
        const [comments] = await promisePool.query(
            `SELECT c.*, u.full_name 
            FROM task_comments c
            JOIN users u ON c.user_id = u.id
            WHERE c.task_id = ?
            ORDER BY c.created_at DESC`,
            [req.params.id]
        );

        // Get subtasks
        const [subtasks] = await promisePool.query(
            'SELECT * FROM subtasks WHERE task_id = ?',
            [req.params.id]
        );

        res.json({
            success: true,
            task: tasks[0],
            comments,
            subtasks
        });

    } catch (error) {
        console.error('Get task error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// Create task
app.post('/api/tasks', authenticateToken, async (req, res) => {
    try {
        const { title, description, assigned_to, priority, due_date } = req.body;
        const created_by = req.user.id;

        // Validate assigned user
        if (assigned_to) {
            const [users] = await promisePool.query(
                'SELECT id FROM users WHERE id = ? AND status = "active"',
                [assigned_to]
            );
            if (users.length === 0) {
                return res.status(400).json({
                    success: false,
                    message: 'Invalid or inactive employee'
                });
            }
        }

        // Insert task
        const [result] = await promisePool.query(
            `INSERT INTO tasks 
            (title, description, assigned_to, created_by, priority, due_date, status) 
            VALUES (?, ?, ?, ?, ?, ?, 'pending')`,
            [title, description, assigned_to, created_by, priority, due_date]
        );

        // Create notification for assigned employee
        if (assigned_to) {
            await promisePool.query(
                `INSERT INTO notifications (user_id, type, message, task_id) 
                VALUES (?, 'task_assigned', ?, ?)`,
                [assigned_to, `New task assigned: ${title}`, result.insertId]
            );
        }

        // Log activity
        await promisePool.query(
            'INSERT INTO activity_logs (user_id, action, description) VALUES (?, ?, ?)',
            [req.user.id, 'create_task', `Created task: ${title}`]
        );

        res.status(201).json({
            success: true,
            message: 'Task created successfully',
            taskId: result.insertId
        });

    } catch (error) {
        console.error('Create task error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// Update task
app.put('/api/tasks/:id', authenticateToken, async (req, res) => {
    try {
        const taskId = req.params.id;
        const { title, description, status, priority, assigned_to, due_date, progress_percentage } = req.body;

        // Check if task exists
        const [tasks] = await promisePool.query(
            'SELECT * FROM tasks WHERE id = ?',
            [taskId]
        );

        if (tasks.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Task not found'
            });
        }

        // Build update query
        const updates = [];
        const values = [];

        if (title) {
            updates.push('title = ?');
            values.push(title);
        }
        if (description) {
            updates.push('description = ?');
            values.push(description);
        }
        if (status) {
            updates.push('status = ?');
            values.push(status);
            if (status === 'completed') {
                updates.push('completion_date = CURDATE()');
            }
        }
        if (priority) {
            updates.push('priority = ?');
            values.push(priority);
        }
        if (assigned_to) {
            updates.push('assigned_to = ?');
            values.push(assigned_to);
        }
        if (due_date) {
            updates.push('due_date = ?');
            values.push(due_date);
        }
        if (progress_percentage !== undefined) {
            updates.push('progress_percentage = ?');
            values.push(progress_percentage);
        }

        if (updates.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'No fields to update'
            });
        }

        values.push(taskId);
        await promisePool.query(
            `UPDATE tasks SET ${updates.join(', ')} WHERE id = ?`,
            values
        );

        // Log activity
        await promisePool.query(
            'INSERT INTO activity_logs (user_id, action, description) VALUES (?, ?, ?)',
            [req.user.id, 'update_task', `Updated task ID: ${taskId}`]
        );

        res.json({
            success: true,
            message: 'Task updated successfully'
        });

    } catch (error) {
        console.error('Update task error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// Delete task
app.delete('/api/tasks/:id', authenticateToken, async (req, res) => {
    try {
        // Check if admin or manager
        if (!['admin', 'manager'].includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: 'Insufficient permissions'
            });
        }

        const [tasks] = await promisePool.query(
            'SELECT title FROM tasks WHERE id = ?',
            [req.params.id]
        );

        if (tasks.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Task not found'
            });
        }

        await promisePool.query('DELETE FROM tasks WHERE id = ?', [req.params.id]);

        // Log activity
        await promisePool.query(
            'INSERT INTO activity_logs (user_id, action, description) VALUES (?, ?, ?)',
            [req.user.id, 'delete_task', `Deleted task: ${tasks[0].title}`]
        );

        res.json({
            success: true,
            message: 'Task deleted successfully'
        });

    } catch (error) {
        console.error('Delete task error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// Add comment to task
app.post('/api/tasks/:id/comments', authenticateToken, async (req, res) => {
    try {
        const taskId = req.params.id;
        const { comment } = req.body;
        const userId = req.user.id;

        // Check if task exists
        const [tasks] = await promisePool.query(
            'SELECT assigned_to, title FROM tasks WHERE id = ?',
            [taskId]
        );

        if (tasks.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Task not found'
            });
        }

        // Add comment
        await promisePool.query(
            'INSERT INTO task_comments (task_id, user_id, comment) VALUES (?, ?, ?)',
            [taskId, userId, comment]
        );

        res.status(201).json({
            success: true,
            message: 'Comment added successfully'
        });

    } catch (error) {
        console.error('Add comment error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// ============================================================
// DASHBOARD ROUTES
// ============================================================

// Get dashboard statistics
app.get('/api/dashboard/stats', authenticateToken, async (req, res) => {
    try {
        let filter = '';
        let params = [];

        if (req.user.role === 'employee') {
            filter = 'WHERE assigned_to = ?';
            params.push(req.user.id);
        }

        // Get counts
        const [total] = await promisePool.query(
            `SELECT COUNT(*) as count FROM tasks ${filter}`,
            params
        );

        const [completed] = await promisePool.query(
            `SELECT COUNT(*) as count FROM tasks ${filter ? filter.replace('WHERE', 'WHERE status = "completed" AND') : 'WHERE status = "completed"'}`,
            params
        );

        const [pending] = await promisePool.query(
            `SELECT COUNT(*) as count FROM tasks ${filter ? filter.replace('WHERE', 'WHERE status IN ("pending", "on_hold") AND') : 'WHERE status IN ("pending", "on_hold")'}`,
            params
        );

        const [inProgress] = await promisePool.query(
            `SELECT COUNT(*) as count FROM tasks ${filter ? filter.replace('WHERE', 'WHERE status = "in_progress" AND') : 'WHERE status = "in_progress"'}`,
            params
        );

        const [overdue] = await promisePool.query(
            `SELECT COUNT(*) as count FROM tasks ${filter ? filter.replace('WHERE', 'WHERE due_date < CURDATE() AND status != "completed" AND') : 'WHERE due_date < CURDATE() AND status != "completed"'}`,
            params
        );

        // Get recent tasks
        let recentQuery = `
            SELECT t.*, u.full_name as assigned_to_name 
            FROM tasks t
            LEFT JOIN users u ON t.assigned_to = u.id
        `;
        if (req.user.role === 'employee') {
            recentQuery += ' WHERE t.assigned_to = ?';
        }
        recentQuery += ' ORDER BY t.created_at DESC LIMIT 5';

        const [recentTasks] = await promisePool.query(
            recentQuery,
            req.user.role === 'employee' ? [req.user.id] : []
        );

        res.json({
            success: true,
            stats: {
                total: total[0].count || 0,
                completed: completed[0].count || 0,
                pending: pending[0].count || 0,
                inProgress: inProgress[0].count || 0,
                overdue: overdue[0].count || 0
            },
            recentTasks
        });

    } catch (error) {
        console.error('Dashboard stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// Get employee performance
app.get('/api/dashboard/performance', authenticateToken, async (req, res) => {
    try {
        const [performance] = await promisePool.query(`
            SELECT 
                u.id,
                u.full_name,
                u.department,
                COUNT(t.id) as total_tasks,
                SUM(CASE WHEN t.status = 'completed' THEN 1 ELSE 0 END) as completed_tasks,
                ROUND(
                    (SUM(CASE WHEN t.status = 'completed' THEN 1 ELSE 0 END) * 100.0) / 
                    NULLIF(COUNT(t.id), 0), 
                    2
                ) as completion_rate
            FROM users u
            LEFT JOIN tasks t ON u.id = t.assigned_to
            WHERE u.role = 'employee'
            GROUP BY u.id
            ORDER BY completion_rate DESC
        `);

        res.json({
            success: true,
            performance
        });

    } catch (error) {
        console.error('Performance stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// ============================================================
// HEALTH CHECK
// ============================================================

app.get('/api/health', (req, res) => {
    res.json({
        success: true,
        message: 'Server is running',
        timestamp: new Date().toISOString()
    });
});

// ============================================================
// ERROR HANDLING
// ============================================================

app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route not found'
    });
});

// ============================================================
// START SERVER
// ============================================================

app.listen(PORT, () => {
    console.log(`\n🚀 Server running on http://localhost:${PORT}`);
    console.log(`\n📡 Available endpoints:`);
    console.log(`   POST   /api/auth/register     - Register user`);
    console.log(`   POST   /api/auth/login        - Login user`);
    console.log(`   GET    /api/users             - Get all users`);
    console.log(`   POST   /api/users             - Create user (admin only)`);
    console.log(`   GET    /api/tasks             - Get all tasks`);
    console.log(`   POST   /api/tasks             - Create task`);
    console.log(`   GET    /api/tasks/:id         - Get task details`);
    console.log(`   PUT    /api/tasks/:id         - Update task`);
    console.log(`   DELETE /api/tasks/:id         - Delete task`);
    console.log(`   POST   /api/tasks/:id/comments - Add comment`);
    console.log(`   GET    /api/dashboard/stats   - Dashboard stats`);
    console.log(`   GET    /api/dashboard/performance - Employee performance`);
    console.log(`   GET    /api/health            - Health check`);
    console.log(`\n📝 Press Ctrl+C to stop\n`);
});