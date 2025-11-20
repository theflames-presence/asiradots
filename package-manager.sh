#!/bin/bash

# Get all AUR packages
get_aur_packages() {
    yay -Slq | grep -v "^core/" | grep -v "^extra/" | grep -v "^multilib/" | grep -v "^community/"
}

# Add package to packages file
add_to_packages() {
    local package="$1"
    local is_aur="$2"
    
    if [[ "$is_aur" == "true" ]]; then
        echo "$package" >> packages.txt
        sed -i '/# AUR Packages/a '"$package" packages.txt
    else
        sed -i '/# Official Packages/a '"$package" packages.txt
    fi
}

# Check if package is from AUR
is_aur_package() {
    yay -Si "$1" 2>/dev/null | grep -q "Repository.*aur"
}

# Main function
main() {
    echo "Fetching AUR packages..."
    local selected=$(get_aur_packages | fzf --prompt="Select package to install > ")
    
    [[ -z "$selected" ]] && exit 0
    
    echo "Installing $selected..."
    yay -S --noconfirm "$selected"
    
    if [[ $? -eq 0 ]]; then
        echo "Adding $selected to packages file..."
        if is_aur_package "$selected"; then
            add_to_packages "$selected" "true"
        else
            add_to_packages "$selected" "false"
        fi
        echo "Package $selected installed and added to packages file!"
    else
        echo "Failed to install $selected"
    fi
}

main
