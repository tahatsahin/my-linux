#!/bin/bash
#linux initiate personalization
#
#script: github.com/tahatsahin/my-linux

set -euo pipefail

INSTALL_ZSH=true
INSTALL_OMZSH=true

#Git
GIT_NAME="Taha Sahin"
GIT_EMAIL="tahatsahin@gmail.com"

echo "[*] Starting bootstrap..."

# Detect package manager
detect_pm() {
	if command -v apt-get >/dev/null 2>&1; then
		echo "apt-get"
	elif command -v dnf >/dev/null 2>&1; then
		echo "dnf"
	elif command -v pacman >/dev/null 2>&1; then
		echo "pacman"
	else
		echo ""
	fi
}

Pm=$(detect_pm || true)

install_pkg() {
	local pkg="$1"
	if command -v "$pkg" >/dev/null 2>&1; then
		echo "	- $pkg already installed"
		return
	fi

	if [ -z "$PM" ]; then
		echo "	! No supported PM found."
		return
	fi

	echo "[*] Installing $pkg with $PM..."
	case "$PM" in
		apt-get) sudo apt-get update && sudo apt-get install -y "$pkg" ;;
		dnf) sudo dnf install -y "$pkg" ;;
		pacman) sudo pacman -Sy --noconfirm "$pkg";;
	esac
}

echo "[*] Ensuring git is installed..."
install_pkg git

if [ "$INSTALL_ZSH" = true ]; then
	echo "[*] Ensuring zsh is installed..."
fi

backup_file() {
	local file="$1"
	if [ -f "$file" ] || [ -L "$file" ]; then
		local backup="$file.bak.$(date +%Y%m%d-%H%M%S)"
		echo "	- Backing up $file -> $backup"
		mv "$file" "$backup"
	fi
}

echo "[*] Updating dotfiles"
echo "[*] Updating .bashrc"

backup_file "$HOME/.bashrc"
if [ -f ".bashrc" ]; then
	ln -s ".bashrc" "$HOME/.bashrc"
elif [ -f "bashrc" ]; then
	ln -s "bashrc" "$HOME/.bashrc"
else
	echo "	! No bashrc found here, skipped."
fi

if [ "$INSTALL_ZSH" = true ]; then
	echo "[*] Installing .zshrc"

	backup_file "$HOME/.zshrc"
	if [ -f ".zshrc" ]; then
		ln -s ".zshrc" "$HOME/.zshrc"
	elif [ -f "zshrc" ]; then
		ln -s "zshrc" "$HOME/.zshrc"
	else
		"	! No zshrc found here, skipped."
	fi
fi

if [ "$INSTALL_OMZSH" = true ]; then
	echo "[*] Installing oh-my-zsh"
	if [ -d "$HOME/.oh-my-zsh" ]; then
		echo "	- oh-my-zsh already installed."
	else
		RUNZSH="no" KEEP_ZSHRC="yes" sh -c \
		      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	fi
fi

echo "[*] Setting git global config..."

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

git config --global push.default current
git config --global push.autoSetupRemote true
git config --global init.defaultBranch main

echo "[*] Creating ssh-keygen in $HOME/.ssh/ for github..."
ssh-keygen -b 4096 -t rsa -C "tahatsahin@gmail.com" -f $HOME/.ssh/id_rsa_gh -N ""

echo "	- You can copy your public ssh below."
cat $HOME/.ssh/id_rsa_gh.pub 

echo
echo "[✓] All done. run 'exec \$SHELL' to see the changes."
