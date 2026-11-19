# AGENTS.md

## Project

Foundry project holding the swap adapters for the Shift platform. Each
contract in `contracts/` implements `ISwapAdapter` from the Shift core
system, which lives in the separate npm package `@shift-defi/core`
(`node_modules/@shift-defi/core/contracts`, remapped to `@shift-defi/core`).
Core's `SwapRouter` whitelists adapters, pulls `tokenIn` from the caller,
approves the adapter and calls `swap`; read `SwapRouter.sol` there before
changing an adapter's swap flow.

These contracts are audited. Every changed line, formatting included, lands
in the next audit diff: change only what the task needs, and never touch
existing code just to make it follow the conventions below. They apply to
code you write or rewrite.

## Commands

`just` wraps the common commands; `just` alone lists them. Forge is pinned
to v1.8.3 (`foundryup -i v1.8.3`).

```shell
just setup        # npm install + git hooks; once per clone
just build        # forge build contracts --sizes
just build-all    # tests and scripts too
just fmt          # forge fmt
just test         # every test, as the pre-commit hook runs it
just test-unit    # hermetic unit tests, no RPC
just test-fork    # fork tests under test/fork/
just test --mt test_Swap                           # one test
just test --mc UniswapV3SwapRouter02AdapterSwapTest  # one contract
just check        # fmt check + build + every test
just lint         # forge lint (not run on build)
just analyze      # slither + aderyn (report in reports/aderyn.md)
```

Everything compiles with via-IR (`via_ir = true` in `foundry.toml`):
`UniswapV3SwapRouter02Adapter.swap` is stack-too-deep under the legacy
pipeline.

Unit tests under `test/unit/` run against mocks. Fork tests under
`test/fork/` pin a fixed block, so results are reproducible and repeat runs
come from forge's RPC cache. Forge loads `MONAD_RPC_URL` (and `ETH_RPC_URL`)
from `.env`, which agent sandboxes cannot read. Before running fork tests,
ask the human to start the agent with those variables exported; if a fork
test cannot reach its RPC, say so instead of skipping it.

Formatting is `forge fmt` with the `[fmt]` section of `foundry.toml`, tuned
so existing code does not reflow. Files in its `ignore` list are audited code
that `forge fmt` would rewrap; take a file off the list only in a change
that is going to audit anyway.

Deploy and whitelist scripts (`script/<Adapter>/`) read their inputs from
env vars and are run by a human.

## Adapter architecture

An adapter is a plain, non-upgradeable contract: configuration that never
changes is a constructor argument stored as an `immutable`, and a change to
code means a new deployment that core's `SwapRouter` whitelists in place of
the old one.

`swap(tokenIn, tokenOut, amountIn, minAmountOut, receiver, data)` pulls
`amountIn` of `tokenIn` from `msg.sender`, swaps it through the venue,
measures the output as the adapter's `tokenOut` balance difference, checks
it against `minAmountOut` (`SlippageCheckFailed` from core's
`ISwapAdapter`) and sends all of it to `receiver`; a venue adapter holds no
tokens between calls. `CustomPool` is the exception: it is the venue,
holds `tokenOut` reserves and prices the swap from a manager-set ratio.

`data` is untrusted: whoever reaches `swap` controls it. An adapter
validates it against state set by a privileged role or against the call
arguments before using it: the Uniswap adapter only accepts whitelisted
paths and checks both ends against `tokenIn` and `tokenOut`; the 1inch
adapter checks the decoded `SwapDescription` against the call arguments.

**Access control.** OpenZeppelin `AccessControl`, with
`WHITELIST_MANAGER_ROLE` (or `TOKEN_MANAGER_ROLE` in `CustomPool`) for the
configuration entry points.

## Comments

- Comment only what the code cannot say: an invariant, a unit, a trust
  assumption, or the reason for a non-obvious choice. Keep it to one line
  unless that loses meaning.
- Do not explain what the code does; if it needs explaining, rename or
  restructure it.
- Describe the code as it is, not how it got here: no "previously",
  "fixed", "now handles", "was reverting when", or bug and issue
  backstories. History belongs in the commit message.
- External functions carry NatSpec in the interface: `@notice`, and
  `@param` and `@return` for each parameter and return value. Each tag is
  one sentence. Add `@dev` only for behaviour a caller would not expect.
  The implementation carries `/// @inheritdoc <Interface>`.

## Code style

**Pragma.** `pragma solidity ^0.8.28;`, as in the rest of `contracts/`.

**Imports.** Named imports only, nothing unused. Groups separated by one
blank line, in this order: OpenZeppelin, `@shift-defi/core`, this repo's
interfaces and vendored protocol interfaces. Inside `contracts/` import this
repo's files by relative path; from `test/` and `script/` write
`contracts/…` and `test/…`.

**Interfaces.** Each adapter implements `contracts/interfaces/I<Adapter>.sol`,
which declares its structs, events, custom errors and external functions.
External protocol interfaces are vendored under
`contracts/dependencies/<protocol>/` rather than pulled in as dependencies,
and keep upstream naming (the `mixed-case-*` lints are off for that reason).

**Errors.** Custom errors only, declared in the adapter's interface. Use
`require(cond, SomeError())`, not `revert` statements or string messages.

**Validation.** Constructors validate every stored address against zero.

**Visibility.** A function not called from inside its contract or a
contract that inherits it is `external`, not `public`.

**Naming.** Internal and private functions are prefixed with an underscore;
state variables are not. A constructor parameter whose name matches an
immutable is prefixed with an underscore (`_swapRouter02`). Events are named
in the past tense (`PathWhitelisted`).

**Storage.** Cache storage and immutable reads in locals suffixed `Cached`
before loops or repeated use. Never read a cached copy after that variable
is written or after an external call.

**Loops.** `++i`, never `i++`. Cache a storage array's length before
iterating.

**Reentrancy.** State-changing functions follow
checks-effects-interactions. An entry point that calls a token or an
external protocol takes `nonReentrant`.

**unchecked.** Every `unchecked` block carries a one-line comment stating
why it cannot overflow or underflow.

**Assembly.** Inline assembly only where Solidity cannot express the
operation or the gas saving is measured, with a comment saying which.

**Arithmetic.** Downcast and convert between signed and unsigned with
OpenZeppelin `SafeCast`; a bare narrowing cast needs a comment stating why
the value fits. Compute `a * b / c` with `Math.mulDiv` and an explicit
`Math.Rounding`.

**Tokens.** Move ERC-20s through `SafeERC20` (`safeTransfer`,
`safeTransferFrom`, `forceApprove`). Adapters support no fee-on-transfer
or rebasing tokens unless the interface `@dev` says so.

**Events.** A state-changing configuration function emits an event carrying
the new value. Index the fields consumers filter by (addresses, ids), not
amounts.

## Dependencies

Solidity libraries are git submodules under `lib/`, pinned in
`foundry.lock`; add them with `forge install`, never by hand, and add the
remapping to `remappings.txt`. Shift core comes from npm
(`@shift-defi/core` in `package.json`); bumping it changes the interface the
adapters implement, so it is its own commit.

## Commits

- One logical change per commit. Keep `forge fmt`-only changes, dependency
  updates and refactors apart from changes in behaviour.
- Header: `<type>(<scope>): <summary>`, at most 72 characters, no trailing
  period. `<type>` is one of `feat`, `fix`, `perf` (gas; the body gives the
  `forge snapshot --diff` result), `refactor`, `test`, `docs`, `style`
  (`forge fmt` only), `chore` (dependencies, tooling), `wip`. `<scope>` is
  lower-case and optional.
- A change to an external function, event or custom error signature takes
  `!` before the colon (`feat(uniswap-v3)!: …`) and the body says what
  changed.
- Body only when the header is not enough: wrapped at 72 characters, says
  why the change is made, not how the code works.
- No `Co-Authored-By` or other AI attribution trailer.
- `.githooks/commit-msg` checks the message and `.githooks/pre-commit` runs
  `forge fmt --check`, `just build` and every test once `just setup` has
  run in the clone.

## Rules

- Never sign or send a transaction except to a local `anvil` node: no
  `--broadcast` on `forge script` or `forge create`, and no `cast send`,
  `cast publish`, `cast mktx` or `cast wallet sign` against any other RPC.
  The deploy and whitelist scripts are for the human.
- Never read or write a private key, keystore, or `.env` file, and never
  write code that reads one (`vm.envUint("PRIVATE_KEY")`). Scripts call
  `vm.startBroadcast()` with no argument; the signer comes from the human's
  `--account` flag.
