#!/usr/bin/env python3
"""
Backend API Service for Telepresence Demo
This service provides REST endpoints and communicates with other services
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
import requests
import os
import logging
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
DATASERVICE_URL = os.getenv('DATASERVICE_URL', 'http://dataservice:5001')
SERVICE_NAME = os.getenv('SERVICE_NAME', 'backend')
ENVIRONMENT = os.getenv('ENVIRONMENT', 'local')

@app.route('/')
def home():
    """Home endpoint"""
    return jsonify({
        'service': SERVICE_NAME,
        'environment': ENVIRONMENT,
        'message': '🚀 Backend API Service is running!',
        'timestamp': datetime.utcnow().isoformat(),
        'version': '1.0.0',
        'endpoints': {
            'health': '/api/health',
            'info': '/api/info',
            'data': '/api/data',
            'users': '/api/users',
            'status': '/api/status'
        }
    })

@app.route('/api/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': SERVICE_NAME,
        'environment': ENVIRONMENT,
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/info')
def info():
    """Service information endpoint"""
    return jsonify({
        'service': SERVICE_NAME,
        'environment': ENVIRONMENT,
        'version': '1.0.0',
        'hostname': os.getenv('HOSTNAME', 'localhost'),
        'pod_ip': os.getenv('POD_IP', '127.0.0.1'),
        'node_name': os.getenv('NODE_NAME', 'local'),
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/data')
def get_data():
    """
    Fetch data from the data service
    This demonstrates inter-service communication
    """
    try:
        logger.info(f"Fetching data from {DATASERVICE_URL}/data")
        response = requests.get(f"{DATASERVICE_URL}/data", timeout=5)
        response.raise_for_status()
        
        data = response.json()
        return jsonify({
            'status': 'success',
            'source': 'dataservice',
            'backend_service': SERVICE_NAME,
            'backend_environment': ENVIRONMENT,
            'data': data,
            'timestamp': datetime.utcnow().isoformat()
        })
    except requests.exceptions.RequestException as e:
        logger.error(f"Error fetching data: {str(e)}")
        return jsonify({
            'status': 'error',
            'message': f'Failed to fetch data from dataservice: {str(e)}',
            'backend_service': SERVICE_NAME,
            'timestamp': datetime.utcnow().isoformat()
        }), 500

@app.route('/api/users')
def get_users():
    """Get list of users"""
    users = [
        {'id': 1, 'name': 'Alice Johnson', 'email': 'alice@example.com', 'role': 'Developer'},
        {'id': 2, 'name': 'Bob Smith', 'email': 'bob@example.com', 'role': 'DevOps Engineer'},
        {'id': 3, 'name': 'Charlie Brown', 'email': 'charlie@example.com', 'role': 'Architect'},
        {'id': 4, 'name': 'Diana Prince', 'email': 'diana@example.com', 'role': 'Product Manager'}
    ]
    
    return jsonify({
        'status': 'success',
        'service': SERVICE_NAME,
        'environment': ENVIRONMENT,
        'count': len(users),
        'users': users,
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/users/<int:user_id>')
def get_user(user_id):
    """Get specific user by ID"""
    users = {
        1: {'id': 1, 'name': 'Alice Johnson', 'email': 'alice@example.com', 'role': 'Developer'},
        2: {'id': 2, 'name': 'Bob Smith', 'email': 'bob@example.com', 'role': 'DevOps Engineer'},
        3: {'id': 3, 'name': 'Charlie Brown', 'email': 'charlie@example.com', 'role': 'Architect'},
        4: {'id': 4, 'name': 'Diana Prince', 'email': 'diana@example.com', 'role': 'Product Manager'}
    }
    
    user = users.get(user_id)
    if user:
        return jsonify({
            'status': 'success',
            'service': SERVICE_NAME,
            'environment': ENVIRONMENT,
            'user': user,
            'timestamp': datetime.utcnow().isoformat()
        })
    else:
        return jsonify({
            'status': 'error',
            'message': f'User with ID {user_id} not found',
            'service': SERVICE_NAME,
            'timestamp': datetime.utcnow().isoformat()
        }), 404

@app.route('/api/status')
def get_status():
    """
    Comprehensive status endpoint showing all dependencies
    """
    status = {
        'service': SERVICE_NAME,
        'environment': ENVIRONMENT,
        'status': 'running',
        'timestamp': datetime.utcnow().isoformat()
    }
    
    # Check dataservice connectivity
    try:
        response = requests.get(f"{DATASERVICE_URL}/health", timeout=2)
        status['dataservice'] = {
            'status': 'connected',
            'url': DATASERVICE_URL,
            'response_code': response.status_code
        }
    except Exception as e:
        status['dataservice'] = {
            'status': 'disconnected',
            'url': DATASERVICE_URL,
            'error': str(e)
        }
    
    return jsonify(status)

@app.route('/api/debug')
def debug():
    """Debug endpoint showing all request headers"""
    return jsonify({
        'service': SERVICE_NAME,
        'environment': ENVIRONMENT,
        'headers': dict(request.headers),
        'remote_addr': request.remote_addr,
        'method': request.method,
        'path': request.path,
        'timestamp': datetime.utcnow().isoformat()
    })

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({
        'status': 'error',
        'message': 'Endpoint not found',
        'service': SERVICE_NAME,
        'timestamp': datetime.utcnow().isoformat()
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    return jsonify({
        'status': 'error',
        'message': 'Internal server error',
        'service': SERVICE_NAME,
        'timestamp': datetime.utcnow().isoformat()
    }), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    logger.info(f"Starting {SERVICE_NAME} service on port {port} (environment: {ENVIRONMENT})")
    logger.info(f"DataService URL: {DATASERVICE_URL}")
    app.run(host='0.0.0.0', port=port, debug=True)
