/**
 * Service B - Node.js Express Microservice
 * Endpoint: GET /hello - Responde con mensaje simple
 */

const express = require('express');
const app = express();

const PORT = process.env.PORT || 8080;
const SERVICE_NAME = 'service-b';
const VERSION = '1.0.0';

// Middleware para logging
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: SERVICE_NAME });
});

// Main endpoint
app.get('/hello', (req, res) => {
    res.json({
        service: SERVICE_NAME,
        message: 'Hello from Service B in Cluster 2!',
        timestamp: new Date().toISOString()
    });
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        service: SERVICE_NAME,
        version: VERSION,
        endpoints: {
            '/': 'Service info',
            '/health': 'Health check',
            '/hello': 'Main endpoint'
        }
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`${SERVICE_NAME} v${VERSION} listening on port ${PORT}`);
});
