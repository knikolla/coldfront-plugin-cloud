#!/bin/bash

#
# Installs MicroShift using MINC (MicroShift in Container)
# MINC: https://github.com/minc-org/minc
#
set -xe

: "${ACCT_MGT_VERSION:="master"}"
: "${ACCT_MGT_REPOSITORY:="https://github.com/cci-moc/openshift-acct-mgt.git"}"
: "${KUBECONFIG:=$HOME/.kube/config}"
: "${MINC_VERSION:="4.18.0-okd-scos.9"}"  # Modern OpenShift version

test_dir="$PWD/testdata"
rm -rf "$test_dir"
mkdir -p "$test_dir"

echo "::group::Install MINC"
# Download and install MINC CLI
curl -L -o /tmp/minc https://github.com/minc-org/minc/releases/latest/download/minc_linux_amd64
chmod +x /tmp/minc
sudo mv /tmp/minc /usr/local/bin/minc
minc version || true
echo "::endgroup::"

echo "::group::Configure MINC"
# Configure MINC to use Docker instead of Podman
minc config set provider docker
minc config set microshift-version "${MINC_VERSION}"
minc config set log-level info
echo "::endgroup::"

echo "::group::Start MicroShift cluster"
# Clean up any existing cluster
sudo minc delete || true

# Create new MicroShift cluster
sudo minc create

# Wait for cluster to be ready
for try in {1..30}; do
    echo "Checking cluster status (attempt $try/30)..."
    if sudo minc status | grep -q '"apiserver": "running"'; then
        echo "MicroShift cluster is running!"
        break
    fi
    sleep 10
done
echo "::endgroup::"

echo "::group::Setup kubeconfig"
# Generate kubeconfig
sudo minc generate-kubeconfig

# MINC places kubeconfig in ~/.kube/config by default
# Copy it to our desired location
KUBECONFIG_FULL_PATH="$(readlink -f "$KUBECONFIG")"
mkdir -p "${KUBECONFIG_FULL_PATH%/*}"
sudo cp ~/.kube/config "${KUBECONFIG}"
sudo chown $(id -u):$(id -g) "${KUBECONFIG}"

# Setup /etc/hosts entry for onboarding service
microshift_addr="127.0.0.1"
sudo sed -i '/onboarding-onboarding.cluster.local/d' /etc/hosts
echo "$microshift_addr  onboarding-onboarding.cluster.local" | sudo tee -a /etc/hosts

# Verify cluster access
while ! oc get route -A; do
    echo "Waiting for MicroShift API to be accessible..."
    sleep 5
done
echo "::endgroup::"

# Install OpenShift Account Management
git clone "${ACCT_MGT_REPOSITORY}" "$test_dir/openshift-acct-mgt"
git -C "$test_dir/openshift-acct-mgt" config advice.detachedHead false
git -C "$test_dir/openshift-acct-mgt" checkout "$ACCT_MGT_VERSION"

echo "::group::Deploy openshift-acct-mgt"
oc apply -k "$test_dir/openshift-acct-mgt/k8s/overlays/crc"
oc wait -n onboarding --for=condition=available --timeout=800s deployment/onboarding
echo "::endgroup::"

sleep 60
