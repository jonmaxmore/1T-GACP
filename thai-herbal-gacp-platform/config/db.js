mongoose.connect(process.env.MONGODB_URI, {
-   useNewUrlParser: true,
-   useUnifiedTopology: true
+   // ไม่ต้องมี options สำหรับ Mongoose > 6.x
});
