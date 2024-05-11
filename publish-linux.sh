#!/bin/bash
# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

echo "Publishing to web..."

truncate -s 0 publish.log
mkdir -p exports/web

echo "Building Linux version..."

output=$(godot --headless --export-release "Linux/X11" exports/linux.zip > /dev/null 2>&1)

if [ $? -eq 0 ]; then
    echo "" > publish.log
    echo "$output" > publish.log
    echo "" > publish.log
    echo "Linux version is built successfully."
else
    echo "$output"
    echo "Couldn't build Linux version!"
    exit 1
fi

echo "Uploading..."

scp exports/linux.zip root@meowingcat.io:/home/meowingcatio/webroot/projects/poker/downloads/PokerGameLinux.zip

echo "Removing local build..."

rm -rf exports/linux.zip

echo "Published successfully!"
