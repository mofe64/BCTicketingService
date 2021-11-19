import express from "express";
import bodyParser from "body-parser";
import dotenv from "dotenv";
import cors from "cors";

dotenv.config({ path: "./config.env" });

const app = express();
app.use(cors());
app.use(express.json({ limit: "20kb" }));
app.use(bodyParser.urlencoded({ limit: "20kb", extended: false }));

export default app;
