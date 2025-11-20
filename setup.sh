#!/bin/bash

echo "
███████╗██╗      █████╗ ███╗   ███╗███████╗    ██████╗  ██████╗ ████████╗███████╗
██╔════╝██║     ██╔══██╗████╗ ████║██╔════╝    ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝
█████╗  ██║     ███████║██╔████╔██║█████╗      ██║  ██║██║   ██║   ██║   ███████╗
██╔══╝  ██║     ██╔══██║██║╚██╔╝██║██╔══╝      ██║  ██║██║   ██║   ██║   ╚════██║
██║     ███████╗██║  ██║██║ ╚═╝ ██║███████╗    ██████╔╝╚██████╔╝   ██║   ███████║
╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝    ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝
"

echo "Setting up Flame Dots..."

install_zshplugins() {
    sudo rm -rf ~/.oh-my-zsh
    CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    touch ~/.zshrc
    echo "Installing plugins"
    sed -i '/^plugins=/,/)/c\plugins=(\n  git\n  zsh-autosuggestions\n  zsh-syntax-highlighting\n \n zsh-history-substring-search)' ~/.zshrc
    echo "Setup pokemon colorscripts"
    if ! grep -q "pokemon-colorscripts -r" ~/.zshrc; then
        sed -i '1s/^/pokemon-colorscripts -r\n/' ~/.zshrc
        echo "Added pokemon-colorscripts -r to the beginning of ~/.zshrc"
    else
        echo "pokemon-colorscripts -r already exists in ~/.zshrc. Skipping."
    fi
    
    if [ -d "~/powerlevel10k" ]; then
        echo "Removing ~/powerlevel10k..."
        sudo rm -r ~/powerlevel10k
    else
        echo "~/powerlevel10k does not exist, skipping removal."
    fi

    if [ -d "~/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
        echo "Removing ~/.oh-my-zsh/custom/themes/powerlevel10k..."
        sudo rm -r ~/.oh-my-zsh/custom/themes/powerlevel10k
    else
        echo "~/.oh-my-zsh/custom/themes/powerlevel10k does not exist, skipping removal."
    fi

    if [ ! -d "~/powerlevel10k" ]; then
        echo "Cloning powerlevel10k repository..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
    else
        echo "~/powerlevel10k already exists, skipping clone."
    fi
    
    sed -i 's|ZSH_THEME="robbyrussell"|ZSH_THEME="powerlevel10k/powerlevel10k"|g' ~/.zshrc
    
    LINES_TO_ADD=(
        'source ~/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme'
        'source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'
        'source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh'
        'source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh'
        'typeset -g POWERLEVEL9K_INSTANT_PROMPT=off'
    )

    if grep -q '^ZSH_THEME=' ~/.zshrc; then
        tmpfile=$(mktemp)
        inserted=0
        while IFS= read -r line; do
            echo "$line" >>"$tmpfile"
            if [[ $inserted -eq 0 && "$line" == ZSH_THEME=* ]]; then
                for add_line in "${LINES_TO_ADD[@]}"; do
                    grep -qxF "$add_line" ~/.zshrc || echo "$add_line" >>"$tmpfile"
                done
                inserted=1
            fi
        done <~/.zshrc
        mv "$tmpfile" ~/.zshrc
    else
        echo "ZSH_THEME line not found in ~/.zshrc"
    fi
    
    chsh -s $(which zsh)
    
    if [ -f "./dotfiles/.zshrc" ]; then
        cp ./dotfiles/.zshrc ~/.zshrc
    fi
    if [ -f "./dotfiles/.p10k.zsh" ]; then
        cp ./dotfiles/.p10k.zsh ~/.p10k.zsh
    fi
}

# Install yay if not present
if ! command -v yay &> /dev/null; then
    if gum confirm "Install yay AUR helper?"; then
        echo "
██╗   ██╗ █████╗ ██╗   ██╗
╚██╗ ██╔╝██╔══██╗╚██╗ ██╔╝
 ╚████╔╝ ███████║ ╚████╔╝ 
  ╚██╔╝  ██╔══██║  ╚██╔╝  
   ██║   ██║  ██║   ██║   
   ╚═╝   ╚═╝  ╚═╝   ╚═╝   
"
        echo "Installing yay..."
        sudo pacman -S --needed git base-devel --noconfirm
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay && makepkg -si --noconfirm
        cd -
    else
        echo "Skipping yay installation..."
    fi
fi

if gum confirm "Install packages from packages.txt?"; then
    echo "
██████╗  █████╗  ██████╗██╗  ██╗ █████╗  ██████╗ ███████╗███████╗
██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔════╝ ██╔════╝██╔════╝
██████╔╝███████║██║     █████╔╝ ███████║██║  ███╗█████╗  ███████╗
██╔═══╝ ██╔══██║██║     ██╔═██╗ ██╔══██║██║   ██║██╔══╝  ╚════██║
██║     ██║  ██║╚██████╗██║  ██╗██║  ██║╚██████╔╝███████╗███████║
╚═╝     ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝
"

    # Read packages from file
    official_packages=($(grep -v "^#" packages.txt | grep -A 1000 "# Official Packages" | grep -B 1000 "# AUR Packages" | grep -v "^#" | grep -v "^$"))
    aur_packages=($(grep -v "^#" packages.txt | grep -A 1000 "# AUR Packages" | grep -v "^#" | grep -v "^$"))

    all_packages=("${official_packages[@]}" "${aur_packages[@]}")
    total=${#all_packages[@]}
    current=0

    echo "Installing packages..."
    for package in "${all_packages[@]}"; do
        current=$((current + 1))
        progress=$((current * 100 / total))
        
        printf "\r[%-50s] %d%% (%d/%d) Installing %s" \
            $(printf "#%.0s" $(seq 1 $((progress / 2)))) \
            $progress $current $total $package
        
        yay -S --noconfirm --needed "$package" &>/dev/null
    done
else
    echo "Skipping package installation..."
fi

if gum confirm "Copy dotfiles to home directory?"; then
    echo -e "\n
██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
"

    echo "Copying dotfiles to home directory..."
    rsync -av --force ./dotfiles/ ~/
else
    echo "Skipping dotfiles copy..."
fi

if gum confirm "Setup zsh with oh-my-zsh and powerlevel10k?"; then
    echo "
▒███████▒  ██████  ██░ ██      ██████ ▓█████▄▄▄█████▓ █    ██  ██▓███  
▒ ▒ ▒ ▄▀░▒██    ▒ ▓██░ ██▒   ▒██    ▒ ▓█   ▀▓  ██▒ ▓▒ ██  ▓██▒▓██░  ██▒
░ ▒ ▄▀▒░ ░ ▓██▄   ▒██▀▀██░   ░ ▓██▄   ▒███  ▒ ▓██░ ▒░▓██  ▒██░▓██░ ██▓▒
  ▄▀▒   ░  ▒   ██▒░▓█ ░██      ▒   ██▒▒▓█  ▄░ ▓██▓ ░ ▓▓█  ░██░▒██▄█▓▒ ▒
▒███████▒▒██████▒▒░▓█▒░██▓   ▒██████▒▒░▒████▒ ▒██▒ ░ ▒▒█████▓ ▒██▒ ░  ░
░▒▒ ▓░▒░▒▒ ▒▓▒ ▒ ░ ▒ ░░▒░▒   ▒ ▒▓▒ ▒ ░░░ ▒░ ░ ▒ ░░   ░▒▓▒ ▒ ▒ ▒▓▒░ ░  ░
░░▒ ▒ ░ ▒░ ░▒  ░ ░ ▒ ░▒░ ░   ░ ░▒  ░ ░ ░ ░  ░   ░    ░░▒░ ░ ░ ░▒ ░     
░ ░ ░ ░ ░░  ░  ░   ░  ░░ ░   ░  ░  ░     ░    ░       ░░░ ░ ░ ░░       
  ░ ░          ░   ░  ░  ░         ░     ░  ░           ░              
░
"
    echo "Zsh setup installing..."
    install_zshplugins
else
    echo "Skipping Zsh setup...."
fi

install_zshplugins() {
    sudo rm -rf ~/.oh-my-zsh
    CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    touch ~/.zshrc
    echo "Installing plugins"
    sed -i '/^plugins=/,/)/c\plugins=(\n  git\n  zsh-autosuggestions\n  zsh-syntax-highlighting\n  zsh-history-substring-search)' ~/.zshrc
    echo "Setup pokemon colorscripts"
    if ! grep -q "pokemon-colorscripts -r" ~/.zshrc; then
        sed -i '1s/^/pokemon-colorscripts -r\n/' ~/.zshrc
    fi
    
    if [ -d "~/powerlevel10k" ]; then
        sudo rm -r ~/powerlevel10k
    fi
    
    if [ -d "~/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
        sudo rm -r ~/.oh-my-zsh/custom/themes/powerlevel10k
    fi
    
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
    sed -i 's|ZSH_THEME="robbyrussell"|ZSH_THEME="powerlevel10k/powerlevel10k"|g' ~/.zshrc
    
    LINES_TO_ADD=(
        'source ~/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme'
        'source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'
        'source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh'
        'source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh'
        'typeset -g POWERLEVEL9K_INSTANT_PROMPT=off'
    )
    
    for add_line in "${LINES_TO_ADD[@]}"; do
        grep -qxF "$add_line" ~/.zshrc || echo "$add_line" >> ~/.zshrc
    done
    
    chsh -s $(which zsh)
    
    if [ -f "./dotfiles/.zshrc" ]; then
        cp ./dotfiles/.zshrc ~/.zshrc
    fi
    if [ -f "./dotfiles/.p10k.zsh" ]; then
        cp ./dotfiles/.p10k.zsh ~/.p10k.zsh
    fi
}

if gum confirm "Enable services and reboot system?"; then
    echo "
██████╗ ███████╗██████╗  ██████╗  ██████╗ ████████╗
██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝
██████╔╝█████╗  ██████╔╝██║   ██║██║   ██║   ██║   
██╔══██╗██╔══╝  ██╔══██╗██║   ██║██║   ██║   ██║   
██║  ██║███████╗██████╔╝╚██████╔╝╚██████╔╝   ██║   
╚═╝  ╚═╝╚══════╝╚═════╝  ╚═════╝  ╚═════╝    ╚═╝   
"
    reboot_system
else
    echo "Skipping reboot..."
    echo "
 ██████╗ ██████╗ ███╗   ███╗██████╗ ██╗     ███████╗████████╗███████╗
██╔════╝██╔═══██╗████╗ ████║██╔══██╗██║     ██╔════╝╚══██╔══╝██╔════╝
██║     ██║   ██║██╔████╔██║██████╔╝██║     █████╗     ██║   █████╗  
██║     ██║   ██║██╔╚██╔╝██║██╔═══╝ ██║     ██╔══╝     ██║   ██╔══╝  
╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ███████╗███████╗   ██║   ███████║
 ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝   ╚═╝   ╚══════╝
"
    echo "Setup complete!"
fi

reboot_system() {
    systemctl enable sddm
    systemctl enable networkmanager
    systemctl enable blueman
    echo "Rebooting the system"
    reboot
}
