# DevOps AI Platform Demo

A homelab DevOps platform demonstrating:

- GitHub Actions
- TypeScript
- Terraform
- Docker
- Python
- FastAPI
- Linux
- CI/CD
- Infrastructure as Code
- AI-assisted development

## Current Architecture

Two containerized FastAPI services run on Linux:

- Server 1: port 8001
- Server 2: port 8002

Each service exposes:

- `GET /`
- `GET /hello`
- `GET /health`

## Example

```text
GET http://localhost:8001/hello

{
  "server": "server1",
  "message": "Hello from server1"
}
