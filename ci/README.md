# CI Test Infrastructure

This directory contains scripts for setting up CI test environments.

## OpenShift Functional Tests

### Current Approach: Kind + OpenShift CRDs

The functional tests use **Kind (Kubernetes in Docker)** with OpenShift Custom Resource Definitions (CRDs) to provide a modern Kubernetes cluster with OpenShift API compatibility.

**Architecture:**
- **Base:** Kind v0.20.0+ (Kubernetes 1.27+)
- **OpenShift APIs:** Custom Resource Definitions for OpenShift resources
- **APIs Provided:**
  - `project.openshift.io/v1` - Project/namespace management
  - `user.openshift.io/v1` - User, Identity, UserIdentityMapping
  - `route.openshift.io/v1` - Route resources

### Why This Approach?

1. **Modern Kubernetes**: Uses latest stable Kubernetes versions (1.27+)
2. **OpenShift API Compatibility**: CRDs provide the same API surface as OpenShift
3. **Lightweight**: No full OpenShift installation, just the APIs needed
4. **Maintainable**: Standard Kubernetes + CRDs, easy to update
5. **CI-Friendly**: Fast startup (~2 minutes), low resource usage

### How It Works

1. **Install Kind** - Creates a Kubernetes cluster in Docker
2. **Install OpenShift CRDs** - Defines OpenShift-specific resource types
3. **Deploy Services** - openshift-acct-mgt for user/project management
4. **Run Tests** - Tests interact with OpenShift APIs via CRDs

The CRDs make Kubernetes understand OpenShift resources (Projects, Users, Identities, Routes) so the tests can create, read, update, and delete these resources just like on real OpenShift.

### Previous Approaches

| Approach | Status | Notes |
|----------|--------|-------|
| **Kind + OpenShift CRDs** | ✅ **Current** | Modern, maintainable, full API support |
| microshift-aio (4.8) | ⏸️ Deprecated | Older (2022), had APIs but unmaintained |
| MINC + MicroShift 4.18 | ❌ | Missing OpenShift APIs |
| Full OKD | ❌ | Too resource-intensive (8GB+ RAM) |

### Technical Details

**CRD Definitions:**
- All CRDs follow OpenShift API specifications
- Support full CRUD operations
- Compatible with OpenShift client libraries
- Schema validation ensures API compatibility

**API Resources Available:**
```bash
kubectl api-resources | grep openshift
projects                                       project.openshift.io/v1        false   Project
users                                          user.openshift.io/v1           false   User
identities                                     user.openshift.io/v1           false   Identity
useridentitymappings                          user.openshift.io/v1           false   UserIdentityMapping
routes                                         route.openshift.io/v1          true    Route
```

**Benefits:**
- ✅ Latest Kubernetes security patches
- ✅ Fast cluster startup (< 2 minutes)
- ✅ Low memory usage (< 2GB)
- ✅ Easy to debug (standard kubectl/oc tools)
- ✅ Reproducible locally and in CI

### Related Files

- `microshift.sh` - Sets up Kind cluster with OpenShift CRDs and openshift-acct-mgt service
- `run_functional_tests_openshift.sh` - Runs the functional test suite
- `../.github/workflows/test-functional-microshift.yaml` - GitHub Actions workflow

### Local Testing

To test locally:

```bash
# Install Kind
curl -Lo kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x kind && sudo mv kind /usr/local/bin/

# Run the setup script
./ci/microshift.sh

# Verify OpenShift APIs
kubectl get crds | grep openshift
kubectl api-resources | grep project.openshift.io

# Run tests
./ci/run_functional_tests_openshift.sh
```

### Future Enhancements

Possible improvements:
- Add more OpenShift CRDs as needed (ClusterRole, etc.)
- Implement custom controllers for complex CRD logic
- Cache Kind images for faster CI startup
- Add OpenShift OAuth CRDs if authentication tests needed

