#!/bin/bash

set -e

POLKADOT=/polkadot/target/release/polkadot
COLLATOR=/substrate-parachain-template/target/debug/parachain-collator

RELAY_WS_PORT=9977
PARACHAIN_WS_PORT=9844

function cleanup {
  kill -- -$$ || true
}
trap cleanup EXIT

rm -rf workdir
mkdir workdir

cd workdir

echo Create relay chainspec
$POLKADOT build-spec --chain rococo-local --disable-default-bootnode > rococo-custom-plain.json
$POLKADOT build-spec --chain rococo-custom-plain.json --raw --disable-default-bootnode > rococo-custom.json

echo Create collator chainspec
$COLLATOR build-spec --disable-default-bootnode > chainspec.json
$COLLATOR build-spec --chain=chainspec.json --raw --disable-default-bootnode > chainspecRaw.json

$COLLATOR export-genesis-state --parachain-id 200 > para-200-genesis
$COLLATOR export-genesis-wasm > para-200-wasm


$POLKADOT \
  --chain rococo-custom.json \
  --tmp \
  --ws-port 9944 \
  --port 30333 \
  --alice \
  >alice-log 2>&1 &

$POLKADOT \
  --chain rococo-custom.json \
  --tmp \
  --ws-port 9955 \
  --port 30334 \
  --bob \
  >bob-log 2>&1 &

$COLLATOR \
  --collator \
  --tmp \
  --parachain-id 200 \
  --port 40333 \
  --ws-port $PARACHAIN_WS_PORT \
  -- \
  --execution wasm \
  --chain rococo-custom.json \
  --port 30343 \
  --ws-port $RELAY_WS_PORT &

cd -

echo Registering parachain

WASM=workdir/para-200-wasm \
GENESIS=workdir/para-200-genesis \
NODE_URL="ws://localhost:$RELAY_WS_PORT" \
  node registerPara.js

echo Parachain registered

sleep 400 && exit 1
