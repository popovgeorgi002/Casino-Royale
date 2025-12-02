import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import authRoutes from "./routes.js";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

app.use(express.json());

const isDevelopment = process.env.NODE_ENV !== 'production';
const corsOptions = {
  origin: isDevelopment
    ? true
    : [
        'http://localhost:3000',
        'http://localhost:3003',
        'http://localhost:3004',
        process.env.FRONTEND_URL || 'http://localhost:3003'
      ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};

app.use(cors(corsOptions));

app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok", service: "auth-service" });
});

app.get("/test", (req, res) => {
  console.log("TEST ENDPOINT HIT!");
  res.json({ message: "Server is working!", timestamp: new Date().toISOString() });
});

app.use("/auth", authRoutes);

app.listen(PORT, () => {
  console.log(`Auth service is running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || "development"}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});

export default app;
