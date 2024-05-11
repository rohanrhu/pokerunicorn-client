#!/bin/bash
# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

echo "Publishing to Windows..."

truncate -s 0 publish.log
mkdir -p exports/web

echo "Building Windows version..."

output=$(godot --headless --export-release "Windows Desktop" exports/windows.zip > /dev/null 2>&1)

if [ $? -eq 0 ]; then
    echo "" > publish.log
    echo "$output" > publish.log
    echo "" > publish.log
    echo "Windows version is built successfully."
else
    echo "$output"
    echo "Couldn't build Windows version!"
    exit 1
fi

echo "Uploading..."

scp exports/windows.zip root@meowingcat.io:/home/meowingcatio/webroot/projects/poker/downloads/PokerGame.zip

echo "Removing local build..."

rm -rf exports/windows.zip

echo "Published successfully!"
