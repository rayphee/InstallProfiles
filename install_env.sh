#!/bin/sh
echo "Installing Rafi's environment profiles"
echo "Note: git, curl, and development tools are expected to be already installed"
echo "Currently supports: nothing"

if [ ! -x "$(command -v brew)" ]; then
	echo "Homebrew not found. Installing..."
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew update

if [ ! -x "$(command -v tmux)" ]; then
	echo "TMux not found. Installing..."
	brew install tmux
fi
if [ ! -x "$(command -v zsh)" ]; then
	echo "ZShell not found. Installing..."
	brew install zsh
fi
if [ ! -x "$(command -v vim)" ]; then
	echo "VIm not found. Installing..."
	brew install vim
fi



# mv files ~/
