import { Router } from 'express';
import { DepositController } from '../controllers/deposit.controller.js';

const router = Router();
const depositController = new DepositController();

// Create deposit
router.post('/', (req, res) => depositController.createDeposit(req, res));

// Get deposit status
router.get('/:paymentIntentId', (req, res) => depositController.getDepositStatus(req, res));

export default router;
