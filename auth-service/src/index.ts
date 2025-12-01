import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import authRoutes from "./routes.js";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// setup middlewares
app.use(express.json());
app.use(cors());

// Health check endpoint
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
