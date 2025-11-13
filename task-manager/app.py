from flask import Flask, request, jsonify, render_template
import psycopg2
import time
from datetime import datetime
import os
from dotenv import load_dotenv


load_dotenv()

app = Flask(__name__)
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_PORT = os.getenv("DB_PORT")

def get_db_connection(max_retries=5, delay=2):
    
    for attempt in range(max_retries):
        try:
            conn = psycopg2.connect(
                host=DB_HOST,
                database=DB_NAME,
                user=DB_USER,
                password=DB_PASSWORD,
                port=DB_PORT
            )
            print(f"Database connection successful (attempt {attempt + 1})")
            return conn
        except Exception as e:
            print(f"Database connection failed (attempt {attempt + 1}): {e}")
            if attempt < max_retries - 1:
                print(f"Waiting {delay} seconds before retry...")
                time.sleep(delay)
            else:
                raise e

def init_database():
    
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
            # Create tasks table if it doesn't exist
        cur.execute("""
            CREATE TABLE IF NOT EXISTS tasks (
                id SERIAL PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                description TEXT,
                status VARCHAR(50) DEFAULT 'pending',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        
        # Check if table has any data
        cur.execute("SELECT COUNT(*) FROM tasks;")
        count = cur.fetchone()[0]
        
        conn.commit()
        cur.close()
        conn.close()
        
        print(f" Database initialized. Found {count} existing tasks.")
        return True
        
    except Exception as e:
        print(f"Database initialization failed: {e}")
        return False

@app.route("/")
def home():
    return render_template('index.html')

@app.route('/tasks', methods=['GET'])
def get_tasks():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT id, title, description, status, created_at FROM tasks ORDER BY created_at DESC;')
        tasks = cur.fetchall()
        cur.close()
        conn.close()
        
        return jsonify([
            {
                'id': task[0],
                'title': task[1],
                'description': task[2],
                'status': task[3],
                'created_at': task[4].isoformat() if task[4] else None
            } for task in tasks
        ])
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/tasks', methods=['POST'])
def create_task():
    try:
        data = request.get_json()
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            'INSERT INTO tasks (title, description, status) VALUES (%s, %s, %s) RETURNING id;',
            (data['title'], data['description'], data.get('status', 'pending'))
        )
        task_id = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({'id': task_id, 'message': 'Task created successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/tasks/<int:task_id>', methods=['PUT'])
def update_task(task_id):
    try:
        data = request.get_json()
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            'UPDATE tasks SET title = %s, description = %s, status = %s WHERE id = %s;',
            (data['title'], data['description'], data['status'], task_id)
        )
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({'message': 'Task updated successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/tasks/<int:task_id>', methods=['DELETE'])
def delete_task(task_id):
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('DELETE FROM tasks WHERE id = %s;', (task_id,))
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({'message': 'Task deleted successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health')
def health_check():
    try:
        # Test database connection
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            port=DB_PORT
        )
        conn.close()
        return jsonify({"status": "healthy", "database": "connected"}), 200
    except Exception as e:
        return jsonify({"status": "unhealthy", "error": str(e)}), 500


# Initialize database when app starts
print("Starting Flask application...")
time.sleep(5) 
init_database()


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True, use_reloader=False)





