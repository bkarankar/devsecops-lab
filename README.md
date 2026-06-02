
# Enterprise DevSecOps Local Lab

Professional DevSecOps local lab setup for:

- Kubernetes (k3d)
- Jenkins
- SonarQube
- ArgoCD
- Grafana
- Kubernetes Dashboard
- Lens Desktop Integration

## Features

- Beautiful terminal UI
- Animated spinners
- Auto pod readiness checks
- Auto port-forwarding
- Auto retries
- Service validation
- Auto dashboard token generation
- Jenkins + SonarQube + ArgoCD setup

## Requirements

- Windows 11
- WSL2 Ubuntu
- Docker Desktop
- WSL Integration enabled

## Run

```bash
chmod +x devsecops-setup.sh
./devsecops-setup.sh
```

## Generated Services

| Service | URL |
|---|---|
| Jenkins | http://localhost:8081 |
| SonarQube | http://localhost:9000 |
| ArgoCD | https://localhost:8082 |
| Grafana | http://localhost:3000 |
| Dashboard | https://localhost:8444 |

## Upload To GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```
