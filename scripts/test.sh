#!/usr/bin/env bash

# Exit script as soon as a command fails.
set -o errexit

# Executes cleanup function at script exit.
trap cleanup EXIT

SOLIDITY_COVERAGE=$1

cleanup() {
  # Kill the ganache instance that we started (if we started one and if it's still running).
  if [ -n "$ganache_pid" ] && ps -p $ganache_pid > /dev/null; then
    kill -9 $ganache_pid
  fi
}

ganache_port=8545

ganache_running() {
  nc -z localhost "$ganache_port"
}

start_ganache() {
  local mnemonic="sport pattern badge pretty abandon venture stone cupboard plunge rm bulk essence"
  local balance=100
  local gasPrice=1000000000

  if [ "$SOLIDITY_COVERAGE" = true ]; then
    node_modules/.bin/testrpc-sc --port "$ganache_port" -m "$mnemonic" -e "$balance" -g "$gasPrice" -a 20 > /dev/null &
  else
    node_modules/.bin/ganache-cli --port "$ganache_port" -m "$mnemonic" -e "$balance" -g "$gasPrice" -a 20 > /dev/null &
  fi

  ganache_pid=$!
}

if ganache_running; then
  echo "Using existing ganache instance"
else
  echo "Starting our own ganache instance"
  start_ganache
fi

if [ "$SOLIDITY_COVERAGE" = true ]; then
  node_modules/.bin/solidity-coverage

  if [ "$CONTINUOUS_INTEGRATION" = true ]; then
    cat coverage/lcov.info | node_modules/.bin/coveralls
  fi
else
  node_modules/.bin/truffle test "$@" --network ganache
fi
