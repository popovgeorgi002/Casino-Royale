import { Router } from "express";
import * as authController from "./authController.js";
import { authenticateToken, validateRequest } from "./shared/middleware.js";
import { loginSchema, registerSchema } from "./validation.js";

const router = Router();

router.post(
  "/register",
  validateRequest(registerSchema),
  authController.register
);
router.post("/login", validateRequest(loginSchema), authController.login);

export default router;
