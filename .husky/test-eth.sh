#!/bin/sh

forge test -vvv --mp "test/ethereum/**" --fork-url $ETHEREUM_RPC_URL

if [ $? -ne 0 ]; then
    echo "Forge tests failed! Commit aborted."
    exit 1
fi
