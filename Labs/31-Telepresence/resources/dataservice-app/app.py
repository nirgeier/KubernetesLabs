#!/usr/bin/env python3
"""
Data Service for Telepresence Demo
This service provides data to the backend service
"""

from flask import Flask, jsonify
from flask_cors import CORS
import os
import logging
from datetime import datetime
import random

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
SERVICE_NAME = os.getenv('SERVICE_NAME', 'dataservice')
ENVIRONMENT = os.getenv('ENVIRONMENT', 'cluster')

@app.route('/')
def home():
    """Home endpoint"""
    return jsonify({
        'service': SERVICE_NAME,
        'environment': ENVIRONMENT,
        'message': '📊 Data Service is running!',
        'timestamp': datetime.utcnow().isoformat(),
        'version': '1.0.0'
    })

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': SERVICE_NAME,
        'environment': ENVIRONMENT,
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/data')
def get_data():
    """
    Return sample data
    """
    data_items = [
        {
            'id': random.randint(1000, 9999),
            'type': 'metric',
            'name': 'cpu_usage',
            'value': round(random.uniform(10, 95), 2),
            'unit': 'percent',
            'timestamp': datetime.utcnow().isoformat()
        },
        {
            'id': random.randint(1000, 9999),
            'type': 'metric',
            'name': 'memory_usage',
            'value': round(random.uniform(1024, 8192), 2),
            'unit': 'MB',
            'timestamp': datetime.utcnow().isoformat()
        },
        {
            'id': random.randint(1000, 9999),
            'type': 'metric',
            'name': 'request_count',
            'value': random.randint(100, 10000),
            'unit': 'count',
            'timestamp': datetime.utcnow().isoformat()
        },
        {
            'id': random.randint(1000, 9999),
            'type': 'metric',
            'name': 'response_time',
            'value': round(random.uniform(10, 500), 2),
            'unit': 'ms',
            'timestamp': datetime.utcnow().isoformat()
        }
    ]
    
    return jsonify({
        'status': 'success',
        'service': SERVICE_NAME,
        'environment': ENVIRONMENT,
        'count': len(data_items),
        'data': data_items,
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/stats')
def get_stats():
    """Get service statistics"""
    return jsonify({
        'service': SERVICE_NAME,
        'environment': ENVIRONMENT,
        'stats': {
            'total_requests': random.randint(10000, 100000),
            'avg_response_time': round(random.uniform(50, 200), 2),
            'error_rate': round(random.uniform(0.1, 5.0), 2),
            'uptime_hours': random.randint(1, 720)
        },
        'timestamp': datetime.utcnow().isoformat()
    })

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5001))
    logger.info(f"Starting {SERVICE_NAME} service on port {port} (environment: {ENVIRONMENT})")
    app.run(host='0.0.0.0', port=port, debug=True)
