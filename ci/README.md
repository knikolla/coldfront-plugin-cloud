# CI Test Infrastructure

This directory contains scripts for setting up CI test environments.

## MicroShift Functional Tests

### Current Approach

The functional tests use the **microshift-aio (All-In-One) image** which provides OpenShift 4.8 from 2022.

**Image:** `quay.io/microshift/microshift-aio:latest`

### Why OpenShift 4.8?

While this image is older (last updated April 2022), it's currently the best option because:

1. **Full OpenShift API Support**: The functional tests require OpenShift-specific APIs:
   - `project.openshift.io/v1` - Project/namespace management with OpenShift semantics
   - `user.openshift.io/v1` - User and Identity management
   - `rbac.authorization.k8s.io/v1` - Role bindings with OpenShift extensions

2. **Modern MicroShift Limitation**: Newer MicroShift versions (4.18+) are designed as minimal Kubernetes distributions and **exclude these OpenShift-specific APIs** to reduce footprint. They provide core Kubernetes APIs but not the full OpenShift API surface.

3. **Test Requirements**: Our functional tests specifically test OpenShift resource management (projects, users, identities, role bindings) which requires these APIs.

### Alternatives Considered

| Option | Pros | Cons | Status |
|--------|------|------|--------|
| **Modern MicroShift (4.18+)** via MINC | Latest OpenShift, actively maintained | Missing required OpenShift APIs | ❌ Tested - APIs not available |
| **microshift-aio (4.8)** | Has all required APIs, works with tests | Older version (2022), deprecated | ✅ **Current choice** |
| **Kind + OpenShift API server** | Modern, flexible | Complex setup, significant rewrite needed | ⏸️ Future option |
| **Full OKD deployment** | Complete OpenShift | Resource-intensive for CI (8GB+ RAM) | ❌ Too heavy |

### Known Limitations

- **OpenShift Version**: Tests run against OpenShift 4.8 APIs (from 2022)
- **Security**: No newer security patches beyond April 2022
- **Image Status**: The microshift-aio image is deprecated but remains functional

### Future Improvements

To use modern OpenShift versions, one of these approaches would be needed:

1. **Refactor to use Kind + OpenShift API aggregation** - Most sustainable long-term
2. **Mock OpenShift APIs** - If only testing ColdFront integration logic
3. **Use hosted OpenShift test cluster** - If available

### Related Files

- `microshift.sh` - Sets up MicroShift container with openshift-acct-mgt service
- `run_functional_tests_openshift.sh` - Runs the functional test suite
- `../.github/workflows/test-functional-microshift.yaml` - GitHub Actions workflow
