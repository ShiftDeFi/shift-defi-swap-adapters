# Fork tests read RPC URLs from .env, which forge loads by itself, and pin
# their blocks, so repeated runs are served from forge's RPC cache.
forge_version := "1.8.3"

# Pass recipe args to the shell as "$@", so quoted args (e.g. `--mc "A|B"`) survive.
set positional-arguments

# List recipes
default:
    @just --list

# Install npm dependencies and use the versioned git hooks in .githooks
setup:
    npm install
    git config core.hooksPath .githooks
    @forge --version | grep -q "{{forge_version}}" || echo "warning: forge is not v{{forge_version}}; run 'foundryup -i v{{forge_version}}'"

# Compile contracts/ with size check, as deployed
build *args:
    forge build contracts --sizes "$@"

# Compile everything, tests and scripts included
build-all *args:
    forge build "$@"

# Run every test: unit tests, then each network's fork tests. Extra args pass through, e.g. `just test --mt test_Swap`
test *args:
    {{just_executable()}} test-unit "$@"
    {{just_executable()}} test-fork "$@"

# Hermetic unit tests (mocks only, no RPC)
test-unit *args:
    forge test --nmp "test/fork/**" "$@"

# Fork tests on every network; forge runs one network's EVM per invocation
test-fork *args:
    {{just_executable()}} test-monad "$@"

# Monad fork tests; forging a Monad block needs a Monad EVM (`--network monad`)
test-monad *args:
    forge test -vvv --network monad --mp "test/fork/**/monad/**" "$@"

# Format sources
fmt:
    forge fmt

# Format check, contracts build, every test (what the pre-commit hook runs)
check:
    forge fmt --check
    {{just_executable()}} build
    {{just_executable()}} test

# Forge lints (not run on build; contracts/ has known findings)
lint *args:
    forge lint "$@"

# Run slither over contracts/; extra args pass through, e.g. `just slither --exclude-low`
slither *args:
    slither . "$@"

# Run aderyn over contracts/; report in reports/aderyn.md
aderyn *args:
    aderyn . --skip-update-check --output reports/aderyn.md "$@"

# Run slither and aderyn before deployment
analyze:
    -{{just_executable()}} slither
    {{just_executable()}} aderyn
