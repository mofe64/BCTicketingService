import mongoose from "mongoose";
import app from "./app.js";

if (process.env.NODE_ENV == "test") {
  mongoose
    .connect(process.env.DATABASE_URL_TEST, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    })
    .then(() => console.log("DB connection successful"));
} else if (process.env.NODE_ENV == "production") {
  mongoose
    .connect(process.env.DATABASE_URL_PROD, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    })
    .then(() => console.log("DB connection successful"));
} else {
  mongoose
    .connect(process.env.DATABASE_URL_DEV, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    })
    .then(() => console.log("DB connection successful"));
}

const port = process.env.PORT || 3000;

export const server = app.listen(port, () => {
  console.log(
    `App running in ${process.env.NODE_ENV} mode on port ${port}....`
  );
});

process.on("unhandledRejection", (err) => {
  console.log("unhandled rejection, Shutting down....");
  console.log(err["name"], err["message"]);
  server.close(() => {
    process.exit(1);
  });
});
