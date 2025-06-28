# Security Policy

## Reporting Vulnerabilities
- Email: security@example.com
- PGP Key: XXXXX
- **Critical issues**: Response within 24 hours

## Secret Management
- ใช้ environment variables เท่านั้น
- ใช้ .env สำหรับ development (เพิ่มใน .gitignore)
- ใช้ secret manager (Vault/GC Secret Manager) สำหรับ production
