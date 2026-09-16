# test/CLAUDE.md

Layout and naming for tests. Both are enforced by `script/gate_tests.py`, which
runs in the `test` lane ahead of `forge test` — see its docstring for why each
check exists and what it cannot catch.

## Layout

- `test/` — shared fixtures (`Base.t.sol`) and, below it, `unit/` and `fork/`.
- `test/unit/<ContractName>/` — one directory per adapter contract. Hermetic:
  mock tokens, a placeholder router address, no real network constants.
  Adapter logic that doesn't touch a real venue (path encoding, whitelisting,
  access control) is network-agnostic, so these suites are not split by
  network.
- `test/fork/<ContractName>/<network>/` — mainnet/testnet fork tests, one
  directory per network the adapter is actually deployed to (`ethereum/`,
  `monad/`, …), because these tests do call live, chain-specific venue
  addresses (a real router, a real pool). Named after the pair or asset under
  test (`WMON.t.sol`, `CrvUSDC.t.sol`), not `<ContractName>.<Aspect>.t.sol` —
  there's one adapter contract per suite already, from the directory. Not part
  of `verify`; run via `make fork` with `ETH_RPC_URL` set. Pin the block in
  `setUp()` — forking `latest` makes runs non-reproducible.
- `test/mocks/` — stand-ins for third-party contracts, shared by every test
  directory. They contain no test functions and mirror only the surface an
  adapter calls.
- `test/invariant/` — property/invariant and fuzz tests. Not yet adopted here
  (`WALL_REQUIRE_INVARIANT=0` in the Makefile stages it) — create this
  directory and flip the flag once a suite exists.

## Suite structure

Within a `test/unit/<ContractName>/` directory, tests live alongside a
`<ContractName>Base.t.sol` fixture — the base holds constants, deployed
contracts and `setUp`, and no test functions, hence no `.t.sol` suffix
ambiguity is avoided by keeping it minimal. `setUp` is `virtual`, and every
override calls `super.setUp()` first. Split a contract's tests into
`<ContractName>.<Aspect>.t.sol` files as they grow past one sitting
(`UniswapV3AdapterSwapRouter02.Path.t.sol`, `.Swap.t.sol`); a contract whose
tests still read in one sitting stays in a single file. Invariant suites for
the same contract inherit the same base.

## Naming

Every segment is PascalCase:

| Form | For |
|---|---|
| `test_Subject` | a behaviour that should succeed |
| `test_Subject_Detail` | one aspect of that behaviour |
| `test_RevertIf_Subject_Reason` | a behaviour that should revert |
| `testFuzz_Subject`, `testFuzz_RevertIf_Subject_Reason` | fuzzed variants |
| `invariant_Property` | invariant and property tests |

`Subject` is the function under test — `test_WhitelistPathSingleHop`. It stays
in the name even when the file and contract already identify the function.

The reason segment is required on a reverting test: it is what separates one
revert path from another, and a test that reverts for the wrong reason still
passes. `test_RevertIf_Subject` alone is rejected for that reason. `testFail_`
is rejected outright — it passes on *any* revert, including one from an
unrelated cause.

The guard has one blind spot worth knowing while writing: it sees only
functions Foundry already recognises as tests, so a misspelled prefix
(`tets_Foo`) is invisible to it, and silently never runs.

## Fixtures

Test code is exempt from the `Code style` rule in the root `CLAUDE.md` that
contracts cross boundaries as `address`: a fixture may hold and pass interface
or contract types directly. The `lint` lane is scoped to `contracts/` for the
same reason — fixtures legitimately use idioms the linter flags.
