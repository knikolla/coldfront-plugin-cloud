#!/bin/bash

#
# Sets up Kind (Kubernetes in Docker) with OpenShift API components
#
# This provides a modern Kubernetes cluster with OpenShift-specific APIs
# (project.openshift.io/v1, user.openshift.io/v1, route.openshift.io/v1)
# required for functional tests.
#
set -xe

: "${ACCT_MGT_VERSION:="master"}"
: "${ACCT_MGT_REPOSITORY:="https://github.com/cci-moc/openshift-acct-mgt.git"}"
: "${KUBECONFIG:=$HOME/.kube/config}"
: "${KIND_VERSION:="v0.20.0"}"

test_dir="$PWD/testdata"
rm -rf "$test_dir"
mkdir -p "$test_dir"

echo "::group::Install Kind"
# Install Kind (Kubernetes in Docker)
curl -Lo /tmp/kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
chmod +x /tmp/kind
sudo mv /tmp/kind /usr/local/bin/kind
kind version
echo "::endgroup::"

echo "::group::Create Kind cluster"
# Delete any existing cluster
kind delete cluster --name openshift-test 2>/dev/null || true

# Create Kind cluster with appropriate configuration
cat > /tmp/kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 9080
    protocol: TCP
  - containerPort: 30443
    hostPort: 9443
    protocol: TCP
EOF

kind create cluster --name openshift-test --config /tmp/kind-config.yaml --wait 5m

# Set up kubeconfig
kind get kubeconfig --name openshift-test > "${KUBECONFIG}"
chmod 600 "${KUBECONFIG}"

# Verify cluster is running
kubectl cluster-info
kubectl get nodes
echo "::endgroup::"

echo "::group::Install OpenShift CRDs"
# Install OpenShift Custom Resource Definitions
# These define the OpenShift-specific API resources

# Create OpenShift Project CRD
kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: projects.project.openshift.io
spec:
  group: project.openshift.io
  names:
    kind: Project
    listKind: ProjectList
    plural: projects
    singular: project
  scope: Cluster
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          apiVersion:
            type: string
          kind:
            type: string
          metadata:
            type: object
          spec:
            type: object
            properties:
              finalizers:
                type: array
                items:
                  type: string
          status:
            type: object
            properties:
              phase:
                type: string
EOF

# Create OpenShift User CRD
kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: users.user.openshift.io
spec:
  group: user.openshift.io
  names:
    kind: User
    listKind: UserList
    plural: users
    singular: user
  scope: Cluster
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          apiVersion:
            type: string
          kind:
            type: string
          metadata:
            type: object
          identities:
            type: array
            items:
              type: string
          groups:
            type: array
            items:
              type: string
          fullName:
            type: string
EOF

# Create OpenShift Identity CRD
kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: identities.user.openshift.io
spec:
  group: user.openshift.io
  names:
    kind: Identity
    listKind: IdentityList
    plural: identities
    singular: identity
  scope: Cluster
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          apiVersion:
            type: string
          kind:
            type: string
          metadata:
            type: object
          providerName:
            type: string
          providerUserName:
            type: string
          user:
            type: object
            properties:
              name:
                type: string
              uid:
                type: string
EOF

# Create OpenShift UserIdentityMapping CRD
kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: useridentitymappings.user.openshift.io
spec:
  group: user.openshift.io
  names:
    kind: UserIdentityMapping
    listKind: UserIdentityMappingList
    plural: useridentitymappings
    singular: useridentitymapping
  scope: Cluster
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          apiVersion:
            type: string
          kind:
            type: string
          metadata:
            type: object
          identity:
            type: object
            properties:
              name:
                type: string
          user:
            type: object
            properties:
              name:
                type: string
EOF

# Create OpenShift Route CRD (for Routes)
kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: routes.route.openshift.io
spec:
  group: route.openshift.io
  names:
    kind: Route
    listKind: RouteList
    plural: routes
    singular: route
  scope: Namespaced
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          apiVersion:
            type: string
          kind:
            type: string
          metadata:
            type: object
          spec:
            type: object
            properties:
              host:
                type: string
              to:
                type: object
                properties:
                  kind:
                    type: string
                  name:
                    type: string
              port:
                type: object
                properties:
                  targetPort:
                    x-kubernetes-int-or-string: true
              tls:
                type: object
          status:
            type: object
    subresources:
      status: {}
EOF

# Wait for CRDs to be established
echo "Waiting for CRDs to be established..."
kubectl wait --for condition=established --timeout=60s crd/projects.project.openshift.io
kubectl wait --for condition=established --timeout=60s crd/users.user.openshift.io
kubectl wait --for condition=established --timeout=60s crd/identities.user.openshift.io
kubectl wait --for condition=established --timeout=60s crd/routes.route.openshift.io

# Verify OpenShift APIs are available
echo "Verifying OpenShift APIs..."
kubectl api-resources | grep project.openshift.io
kubectl api-resources | grep user.openshift.io
kubectl api-resources | grep route.openshift.io
echo "::endgroup::"

echo "::group::Setup /etc/hosts for services"
# Get the kind cluster's Docker container IP
cluster_ip="127.0.0.1"
sudo sed -i '/onboarding-onboarding.cluster.local/d' /etc/hosts
echo "$cluster_ip  onboarding-onboarding.cluster.local" | sudo tee -a /etc/hosts
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
