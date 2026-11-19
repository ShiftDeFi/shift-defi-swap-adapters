# AGENTS.md — tests

- Do not weaken or delete a test to make a suite pass; if a test is wrong,
  say so.
- Report failing tests with their output rather than as passing. A fork
  test that cannot reach its RPC has not passed.
- Layout: `test/Base.t.sol` (roles, users) → `test/unit/<Adapter>/` with an
  abstract `<Adapter>Base.t.sol` holding the shared setup (mock tokens and
  protocol from `test/mocks/`, a real core `SwapRouter` behind a proxy with
  the adapter whitelisted) and one file per area (`<Adapter>.Swap.t.sol`,
  `<Adapter>.Path.t.sol`) → `test/fork/<Adapter>/<chain>/<Pair>.t.sol`
  against the live protocol. Interfaces only tests need go in
  `test/dependencies/`.
- Test names: `test_<Behavior>` and `test_RevertIf_<Function>_<Reason>`.
- Use `vm.expectRevert` with the specific custom error selector, not a bare
  `vm.expectRevert()`.
- Every fork pins its block in a `<CHAIN>_FORK_BLOCK` constant
  (`vm.createSelectFork(vm.rpcUrl("monad"), MONAD_FORK_BLOCK)`). Never fork
  the latest block. Bump a block deliberately, in its own `test:` commit,
  after the suite passes at the new block.
- Behaviour that does not depend on a live venue is tested in `test/unit/`
  against mocks; a fork test covers what only the live protocol can show.
