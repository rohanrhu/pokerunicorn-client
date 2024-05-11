#!/bin/bash

echo "Running $1 of clients..."

for ((i = 0; i < $1; i++)); do
    godot $(dirname "$0") --remote-debug tcp://127.0.0.1:6007 --server-address 127.0.0.1 "${@:1}" &
done