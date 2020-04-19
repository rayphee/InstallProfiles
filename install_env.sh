#!/bin/bash

declare -a configuration_files=("tmux.conf" "vimrc" "zshrc")
declare -a distribution_folders=("tmux" "vim")
declare -a missing_programs=()

echo "Installing Rafi's environment profiles"
echo "Note: git, curl, and development tools are expected to be already installed"
echo "The configuration profiles are written to comply with the latest versions of brew, tmux, zsh, and vim as of 4/18/19"
echo "Currently supports: macOS Mojave+"
echo "	macOS (Tested on Mojave)"
echo "	Linux (Tested on Ubuntu 20.04 LTS, Debian based only)"

if [ ! -x "$(command -v tmux)" ]; then
	missing_programs+=("tmux")
fi
if [ ! -x "$(command -v zsh)" ]; then
	missing_programs+=("zsh")
fi
if [ ! -x "$(command -v vim)" ]; then
	missing_programs+=("vim")
fi
if [ ! -x "$(command -v pip3)" ]; then
	missing_programs+=("python3-pip")
fi

run_mac_setup () {
	if [ ! -x "$(command -v brew)" ]; then
		echo "Homebrew not found. Installing..."
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	fi
	
	brew update
	
	for i in "${missing_programs[@]}"
	do
		brew install $i
	done

	echo "Installing fonts..."
	cp fonts/operator_mono/* ~/Library/Fonts
	

	run_generic_setup
}

run_ubuntu_setup () {
	if [ ! -z "$missing_programs" ]; then
		sudo apt install ${missing_programs[@]} -y
	fi

	echo "Installing fonts..."
	if [ ! -d "~/.fonts" ]; then
		mkdir ~/.fonts
		cp -r fonts/operator_mono/ ~/.fonts/
	fi

	run_generic_setup
}

run_generic_setup (){
	echo "Copying distribution folders..."
	for i in "${distribution_folders[@]}"
	do
		tar -xzf $i.tgz -C ~
		mv ~/$i ~/.$i
	done
	
	echo "Installing TPM..."
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	
	echo "Installing Oh My Zsh..."
	curl -Lo install.sh https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
	sh install.sh --unattended
	cp agnoster-simple.zsh-theme ~/.oh-my-zsh/themes
	git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
	rm -rf install.sh # GDI Oh My Zsh why're you leaving your trash here?
	
	echo "Installing Vundle..."
	git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
	pip3 install --user powerline-status
	
	echo "Copying configuration files..."
	for i in "${configuration_files[@]}"
	do
		cp $i ~/.$i
	done
	
	echo "Applying profile changes..."
	tmux source ~/.tmux.conf
	
	chsh -s $(which zsh)
	
	exit 0
}

if [[ "$OSTYPE" == "linux-gnu" ]]; then
	echo "Linux-based detected"
	run_ubuntu_setup
elif [[ "$OSTYPE" == "darwin"* ]]; then
	echo "Darwin-based OS detected"
	run_mac_setup
else
        echo "Unsupported OS detected"
	echo "Aborting environment setup"
	exit -1
fi

