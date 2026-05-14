# Review Checklist

Reference checklist for code review. Use as a guide -- not every item applies to every PR.

## Correctness

- [ ] Logic handles edge cases (empty inputs, boundaries, overflow)
- [ ] Error paths are handled and don't silently swallow failures
- [ ] Concurrent access is safe (race conditions, shared state)
- [ ] Resource cleanup (connections, file handles, subscriptions)

## Security

- [ ] User input is validated/sanitized before use
- [ ] No SQL injection, XSS, or command injection vectors
- [ ] Secrets are not hardcoded or logged
- [ ] Auth/authz checks are present where needed
- [ ] Sensitive data is not exposed in error messages

## Performance

- [ ] No N+1 queries or unbounded iterations
- [ ] Large allocations are bounded or streamed
- [ ] Caching is appropriate (not stale, not over-cached)
- [ ] Hot paths avoid unnecessary allocations

## Design

- [ ] Changes are cohesive (single responsibility)
- [ ] Public API surface is minimal and well-named
- [ ] Abstractions earn their complexity
- [ ] No dead code or unused imports introduced

## Tests

- [ ] New behavior has test coverage
- [ ] Edge cases from "Correctness" above are tested
- [ ] Tests are deterministic (no flaky timing, no network)
- [ ] Test names describe the scenario, not the implementation

## Documentation

- [ ] Public APIs have doc comments explaining behavior
- [ ] Non-obvious decisions have inline rationale
- [ ] Breaking changes are called out in commit/PR description
