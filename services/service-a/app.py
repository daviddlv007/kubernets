"""
Service A - Python Flask Microservice
Endpoint: GET /call - Llama a Service B y retorna la respuesta
"""

from flask import Flask, jsonify
import requests
import os

app = Flask(__name__)

# URL de Service B (configurar vía variable de entorno)
SERVICE_B_URL = os.getenv('SERVICE_B_URL', 'http://localhost:8082')

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "service": "service-a", "version": "v1.1-gitops"}), 200

@app.route('/call')
def call_service_b():
    """Llama a Service B y retorna su respuesta"""
    try:
        response = requests.get(f"{SERVICE_B_URL}/hello", timeout=5)
        return jsonify({
            "service": "service-a",
            "message": "Successfully called Service B",
            "service_b_response": response.text,
            "status_code": response.status_code
        }), 200
    except requests.exceptions.RequestException as e:
        return jsonify({
            "service": "service-a",
            "message": "Failed to call Service B",
            "error": str(e)
        }), 500

@app.route('/')
def root():
    """Root endpoint con información del servicio"""
    return jsonify({
        "service": "service-a",
        "version": "1.0.0",
        "endpoints": {
            "/": "Service info",
            "/health": "Health check",
            "/call": "Call Service B"
        }
    }), 200

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)
