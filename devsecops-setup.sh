#!/bin/bash

set -e

LOG_FILE="$(pwd)/devsecops-setup.log"
touch "$LOG_FILE"

exec > >(tee -a "$LOG_FILE") 2>&1

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear

logo() {
cat << "EOF"

██████╗ ███████╗██╗   ██╗ ██████╗ ██████╗ ███████╗
██╔══██╗██╔════╝██║   ██║██╔═══██╗██╔══██╗██╔════╝
██║  ██║█████╗  ██║   ██║██║   ██║██████╔╝███████╗
██║  ██║██╔══╝  ╚██╗ ██╔╝██║   ██║██╔═══╝ ╚════██║
██████╔╝███████╗ ╚████╔╝ ╚██████╔╝██║     ███████║
╚═════╝ ╚══════╝  ╚═══╝   ╚═════╝ ╚═╝     ╚══════╝

EOF
}

spinner() {
    pid=$1
    msg=$2
    spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    while kill -0 $pid 2>/dev/null; do
        for i in $(seq 0 9); do
            printf "\r${CYAN}%s${NC} %s" "${spin:$i:1}" "$msg"
            sleep 0.1
        done
    done

    printf "\r${GREEN}✔${NC} %s\n" "$msg"
}

run_step() {
    title="$1"
    cmd="$2"

    bash -c "$cmd" >> "$LOG_FILE" 2>&1 &
    PID=$!

    spinner $PID "$title"

    wait $PID || {
        echo -e "${RED}✖ Failed:${NC} $title"
        echo "Logs → $LOG_FILE"
        exit 1
    }
}

wait_ready() {
    TYPE=$1
    NAME=$2
    NS=$3

    echo -e "${YELLOW}➜ Waiting for ${NAME} readiness...${NC}"

    kubectl rollout status ${TYPE}/${NAME} -n ${NS} --timeout=900s >> "$LOG_FILE" 2>&1 || true
}

wait_for_pod_ready() {
    NS=$1
    LABEL=$2
    NAME=$3

    echo "➜ Waiting for ${NAME} pod..."

    for i in {1..60}; do
        READY=$(kubectl get pods -n $NS -l "$LABEL" \
        -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || true)

        if [[ "$READY" == "true" ]]; then
            echo "✔ ${NAME} pod ready"
            return
        fi

        sleep 5
    done

    echo "✖ ${NAME} pod timeout"
}

find_free_port() {
    PORT=$1

    while ss -tuln | grep -q ":$PORT "; do
        PORT=$((PORT+1))
    done

    echo $PORT
}

start_port_forward() {
    NS=$1
    SERVICE=$2
    LOCAL_PORT=$3
    REMOTE_PORT=$4
    NAME=$5

    PORT=$(find_free_port $LOCAL_PORT)

    echo "➜ Starting ${NAME} on port ${PORT}"

    nohup kubectl port-forward svc/${SERVICE} ${PORT}:${REMOTE_PORT} \
    -n ${NS} --address 0.0.0.0 \
    >/tmp/${NAME}.log 2>&1 &

    sleep 5

    if ps aux | grep "port-forward svc/${SERVICE}" | grep -v grep >/dev/null; then
        echo "✔ ${NAME} available at port ${PORT}"
    else
        echo "✖ ${NAME} failed to start"
    fi

    eval ${NAME}_PORT=${PORT}
}

validate_service() {
    NAME=$1
    URL=$2

    if curl -k -s --max-time 5 "$URL" >/dev/null 2>&1; then
        printf "${GREEN}✔ %-12s${NC} reachable\n" "$NAME"
    else
        printf "${RED}✖ %-12s${NC} not reachable yet\n" "$NAME"
    fi
}

logo

echo "Logs → $LOG_FILE"
echo ""

run_step \
"Installing Packages" \
"sudo apt update && sudo apt install -y wget curl git unzip docker.io apt-transport-https ca-certificates gnupg lsb-release software-properties-common"

run_step \
"Installing kubectl" \
"wget -q -O kubectl https://dl.k8s.io/release/v1.34.0/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/"

run_step \
"Installing Helm" \
"wget -q -O helm.tar.gz https://get.helm.sh/helm-v3.18.4-linux-amd64.tar.gz && tar -xzf helm.tar.gz && sudo mv linux-amd64/helm /usr/local/bin/helm"

run_step \
"Installing k3d" \
"curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash"

run_step \
"Creating Kubernetes Cluster" \
"k3d cluster create devops-cluster --agents 2 -p '8081:80@loadbalancer' -p '8443:443@loadbalancer' || true"

cat > jenkins-values.yaml <<EOF
controller:
  testEnabled: false
  admin:
    username: admin
    password: admin123
  serviceType: ClusterIP
persistence:
  enabled: false
EOF

run_step \
"Installing Jenkins" \
"kubectl create namespace jenkins || true && helm repo add jenkins https://charts.jenkins.io || true && helm repo update && helm uninstall jenkins -n jenkins || true && helm install jenkins jenkins/jenkins -n jenkins -f jenkins-values.yaml"

wait_ready statefulset jenkins jenkins

run_step \
"Installing SonarQube" \
"kubectl create namespace sonarqube || true && helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube || true && helm repo update && helm uninstall sonarqube -n sonarqube || true && helm install sonarqube sonarqube/sonarqube -n sonarqube --set community.enabled=true --set persistence.enabled=false --set monitoringPasscode=admin123"

sleep 20

run_step \
"Installing ArgoCD" \
"kubectl create namespace argocd || true && kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml || true"

sleep 20

cat > dashboard-admin.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

run_step \
"Installing Dashboard" \
"kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml && kubectl apply -f dashboard-admin.yaml"

run_step \
"Installing Grafana" \
"kubectl create namespace monitoring || true && helm repo add grafana https://grafana.github.io/helm-charts || true && helm repo update && helm uninstall grafana -n monitoring || true && helm install grafana grafana/grafana -n monitoring --set persistence.enabled=false --set adminPassword=admin123"

echo ""
echo "➜ Waiting for all applications"

wait_for_pod_ready jenkins "app.kubernetes.io/component=jenkins-controller" Jenkins
wait_for_pod_ready sonarqube "app=sonarqube" SonarQube
wait_for_pod_ready monitoring "app.kubernetes.io/name=grafana" Grafana
wait_for_pod_ready argocd "app.kubernetes.io/name=argocd-server" ArgoCD

echo ""
echo "➜ Starting Services"

pkill -f port-forward >/dev/null 2>&1 || true

start_port_forward jenkins jenkins 8081 8080 Jenkins
start_port_forward sonarqube sonarqube-sonarqube 9000 9000 SonarQube
start_port_forward argocd argocd-server 8082 443 ArgoCD
start_port_forward monitoring grafana 3000 80 Grafana
start_port_forward kubernetes-dashboard kubernetes-dashboard 8444 443 Dashboard

ARGO_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d || true)
DASHBOARD_TOKEN=$(kubectl -n kubernetes-dashboard create token admin-user || true)

cp /root/.kube/config /root/k3d-kubeconfig.yaml || true

echo ""
echo "══════════════════════════════════════════════"
echo " SERVICE VALIDATION"
echo "══════════════════════════════════════════════"

validate_service "Jenkins" "http://localhost:${Jenkins_PORT}"
validate_service "SonarQube" "http://localhost:${SonarQube_PORT}"
validate_service "Grafana" "http://localhost:${Grafana_PORT}"

echo ""
echo "══════════════════════════════════════════════"
echo " DEVSECOPS LAB READY"
echo "══════════════════════════════════════════════"
echo ""

printf "%-12s → %s\n" "Jenkins" "http://localhost:${Jenkins_PORT}"
printf "%-12s → %s\n" "SonarQube" "http://localhost:${SonarQube_PORT}"
printf "%-12s → %s\n" "ArgoCD" "https://localhost:${ArgoCD_PORT}"
printf "%-12s → %s\n" "Grafana" "http://localhost:${Grafana_PORT}"
printf "%-12s → %s\n" "Dashboard" "https://localhost:${Dashboard_PORT}"

echo ""
echo "══════════════════════════════════════════════"
echo " CREDENTIALS"
echo "══════════════════════════════════════════════"
echo ""

printf "%-12s → %s\n" "Jenkins" "admin / admin123"
printf "%-12s → %s\n" "SonarQube" "admin / admin"
printf "%-12s → %s\n" "Grafana" "admin / admin123"
printf "%-12s → %s\n" "ArgoCD" "admin / ${ARGO_PASS}"

echo ""
echo "Dashboard Token:"
echo "$DASHBOARD_TOKEN"

echo ""
echo "Kubeconfig → /root/k3d-kubeconfig.yaml"
echo "Logs       → $LOG_FILE"

echo -e "\a"
