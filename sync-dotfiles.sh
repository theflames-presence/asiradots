#!/bin/bash

echo "Starting dotfiles sync monitor..."

while true; do
    inotifywait -r -e modify,create,delete,move ./dotfiles/ 2>/dev/null
    rsync -av --force ./dotfiles/ ~/
    echo "$(date): Dotfiles synced"
done
