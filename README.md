# DevOps AI Platform Demo

A hybrid homelab & AWS DevOps platform demonstrating:

- GitHub Actions (CI & CD)
- TypeScript (Custom GitHub Actions)
- Terraform (Multi-Provider: Docker + AWS EC2)
- Docker
- Python & FastAPI
- Linux
- CI/CD
- Infrastructure as Code
- AI-assisted development

## Architecture

Three containerized FastAPI services:

- **Server 1 (Homelab):** `http://localhost:8001`
- **Server 2 (Homelab):** `http://localhost:8002`
- **Server 3 (AWS EC2):** `http://<ec2-public-ip>:8000`

Each service exposes:

- `GET /`
- `GET /hello`
- `GET /health`

## Example Response

```json
GET http://<server-url>/hello

{
  "server": "server3",
  "message": "Hello from server3 -ver2 hello-deployed by GitHub Actions and Terraform v4"
}
```

## GitHub Secrets Required

To enable AWS provisioning and GHCR deployment:

| Secret | Description |
|---|---|
| `GHCR_READ_TOKEN` | GitHub Personal Access Token to pull GHCR packages |
| `AWS_ACCESS_KEY_ID` | IAM User Access Key for Terraform AWS provider |
| `AWS_SECRET_ACCESS_KEY` | IAM User Secret Key for Terraform AWS provider |
| `AWS_REGION` | *(Optional, default: `us-east-1`)* Target AWS Region |
