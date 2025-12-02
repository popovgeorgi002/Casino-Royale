import { Router } from 'express';
import { GatewayController } from '../controllers/gateway.controller.js';

const router = Router();
const gatewayController = new GatewayController();

// Gateway-specific route for creating users (called by auth-service)
router.post('/users/create', (req, res) => gatewayController.createUser(req, res));

// Proxy all user-service routes
// IMPORTANT: Order matters - specific routes before generic ones
router.get('/users/:id', (req, res) => gatewayController.getUserById(req, res));
router.put('/users/:id', (req, res) => {
  console.log('[ROUTE] PUT /users/:id matched, path:', req.path, 'params:', req.params);
  gatewayController.proxyToUserService(req, res);
});
router.delete('/users/:id', (req, res) => gatewayController.proxyToUserService(req, res));
router.post('/users', (req, res) => gatewayController.proxyToUserService(req, res));
router.get('/users', (req, res) => gatewayController.proxyToUserService(req, res));

// Proxy all deposit-service routes
router.post('/deposits', (req, res) => gatewayController.proxyToDepositService(req, res));
router.get('/deposits/:paymentIntentId', (req, res) => gatewayController.proxyToDepositService(req, res));

export default router;
