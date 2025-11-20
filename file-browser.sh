#!/bin/bash

browse() {
    local dir="${1:-$HOME}"
    
    while true; do
        local selected=$(find "$dir" -maxdepth 1 -type f -o -type d | sed "s|$dir/||" | grep -v "^$dir$" | sort | fzf --prompt="$dir > ")
        
        [[ -z "$selected" ]] && return
        
        local full_path="$dir/$selected"
        
        if [[ -d "$full_path" ]]; then
            local action=$(echo -e "open\ncopy" | fzf --prompt="Folder action > ")
            case "$action" in
                "open") browse "$full_path" ;;
                "copy") 
                    local rel_path="${full_path#$HOME/}"
                    local dest_dir="./dotfiles/$(dirname "$rel_path")"
                    mkdir -p "$dest_dir"
                    cp -r "$full_path" "$dest_dir/"
                    echo "Copied to ./dotfiles/$rel_path"
                    ;;
            esac
        else
            local action=$(echo -e "open\ncopy" | fzf --prompt="File action > ")
            case "$action" in
                "open") nvim "$full_path" ;;
                "copy")
                    local rel_path="${full_path#$HOME/}"
                    local dest_dir="./dotfiles/$(dirname "$rel_path")"
                    mkdir -p "$dest_dir"
                    cp "$full_path" "$dest_dir/"
                    echo "Copied to ./dotfiles/$rel_path"
                    ;;
            esac
        fi
    done
}

browse
