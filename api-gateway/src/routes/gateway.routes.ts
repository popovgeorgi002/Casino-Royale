import { Router } from 'express';
import { GatewayController } from '../controllers/gateway.controller.js';

const router = Router();
const gatewayController = new GatewayController();

// Gateway-specific route for creating users (called by auth-service)
router.post('/users/create', (req, res) => gatewayController.createUser(req, res));

// Proxy all user-service routes
router.get('/users/:id', (req, res) => gatewayController.getUserById(req, res));
router.put('/users/:id', (req, res) => gatewayController.proxyToUserService(req, res));
router.delete('/users/:id', (req, res) => gatewayController.proxyToUserService(req, res));
router.post('/users', (req, res) => gatewayController.proxyToUserService(req, res));
router.get('/users', (req, res) => gatewayController.proxyToUserService(req, res));

export default router;
