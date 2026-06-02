![Kubernetes](https://img.shields.io/badge/Kubernetes-k3d-blue)
![Jenkins](https://img.shields.io/badge/Jenkins-CI-red)
![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-orange)
![Grafana](https://img.shields.io/badge/Grafana-Monitoring-yellow)
![License](https://img.shields.io/badge/License-MIT-green)

Watch the full automated Enterprise DevSecOps platform installation demo:

▶ Watch Terminal Recording at https://asciinema.org/a/OzET5y7cDMgf8nGx

Features shown in demo:

- Kubernetes (k3d) setup
- Jenkins installation
- SonarQube setup
- ArgoCD GitOps deployment
- Grafana monitoring
- Kubernetes Dashboard
- Automated port-forwarding
- Professional terminal UI
- Service validation

# Enterprise DevSecOps Local Lab

Enterprise-grade **local DevSecOps platform** using Kubernetes (k3d) on WSL2 with automated Jenkins, SonarQube, ArgoCD, Grafana, Kubernetes Dashboard, CI/CD pipelines, GitOps deployment, monitoring, security scanning, and beautiful terminal-based installer UI.

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
git remote add origin https://github.com/bkarankar/devsecops-lab.git
git push -u origin main
```
