import { Router } from 'express';
import { DepositController } from '../controllers/deposit.controller.js';

const router = Router();
const depositController = new DepositController();

router.post('/', (req, res) => depositController.createDeposit(req, res));

router.get('/:paymentIntentId', (req, res) => depositController.getDepositStatus(req, res));

export default router;
