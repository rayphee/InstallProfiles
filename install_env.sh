#!/bin/bash

declare -a configuration_files=("tmux.conf" "vimrc" "zshrc")
declare -a distribution_folders=("tmux" "vim")
declare -a missing_programs=()

PACKAGE_MANAGER_COMMAND="sudo apt"
FORCE_INSTALL=false

while getopts ":hfcv" opt; do
	case ${opt} in
		h )	echo "Usage:"
			echo "  install_env [options]"
			echo "Options:"
			echo "  -h		Show this help message."
			echo "  -c		Install only configuration files."
			echo "  -f		Overwrite all existing configuration files."
			echo "  -v		Check version and compatibilty for this install script."
			exit 0
			;;
		f )	FORCE_INSTALL=true
			echo "Overwriting existing configuration files"
			;;
		C )	echo "Installing only configuration files"
			run_generic_setup
			;;
		v )	echo "Install Environment Profiles R20.04.21"
			echo ""
			echo "This script sets up the terminal environment to Rafi's configuration. If the base programs (tmux, zsh, pip3, and vim) are not installed, this script automatically installs them. For macOS, there is no default package manager. This script assumes users will use Homebrew as the macOS package manager; therefore, it treats Homebrew as a base program and installs it if not found. The configuration profiles are written to comply with the latest versions of brew, tmux, zsh, and vim as of 4/21/20."
			echo ""
			echo "Note: git, curl, and development tools are expected to be already installed."
			echo ""
			echo "Currently supports:"
			echo "	macOS (Tested on Mojave)"
			echo "	Linux (Tested on Ubuntu 19.10, 20.04 LTS, Arch stubs are built in, but not confirmed to work)"
			exit 0
			;;
		\? )	echo "Usage: cmd [-hv] [-fc]"
			exit -1
			;;
	esac
done

if [ ! -x "$(command -v tmux)" ]; then
	missing_programs+=("tmux")
fi
if [ ! -x "$(command -v zsh)" ]; then
	missing_programs+=("zsh")
fi
if [ ! -x "$(command -v vim)" ]; then
	missing_programs+=("vim")
fi

run_mac_setup () {
	if [ ! -x "$(command -v brew)" ]; then
		echo "Homebrew not found. Installing..."
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	fi
	
	brew update

	missing_programs+=("vim")  # macOS's default vim doesn't support python3... tsk tsk tsk
	
	for i in "${missing_programs[@]}"
	do
		brew install $i
	done

	echo "Installing fonts..."
	cp fonts/operator_mono/* ~/Library/Fonts

	run_generic_setup
}

run_linux_setup () {
	if [ ! -z "$missing_programs" ]; then
		$PACKAGE_MANAGER_COMMAND ${missing_programs[@]}
	fi

	echo "Installing fonts..."
	if [ ! -d ~/.fonts ]; then
		mkdir ~/.fonts
	fi
	if [ ! -d ~/.fonts/operator_mono ]; then
		cp -r fonts/operator_mono/ ~/.fonts/
	fi

	run_generic_setup
}

run_generic_setup (){
	echo "Copying distribution folders..."
	for i in "${distribution_folders[@]}"
	do
		if [ -d ~/.$i ]; then
			if [ "$FORCE_INSTALL" = true ]; then
				echo "Overwriting .$i folder"
				rm -rf ~/.$i
				tar -xzf $i.tgz -C ~
				mv ~/$i ~/.$i
			else
				echo "Found an existing .$i folder and force flag was not set"
				echo "Skipping .$i"
			fi
		else
			tar -xzf $i.tgz -C ~
			mv ~/$i ~/.$i
		fi
	done
	
	if [ ! -d ~/.tmux/plugins/tpm ]; then
		echo "Did not find a TPM installation"
		echo "Installing TPM..."
		git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	fi
	
	if [ ! -d ~/.oh-my-zsh ]; then
		echo "Did not find a Oh My Zsh installation"
		echo "Installing Oh My Zsh..."
		curl -Lo install.sh https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
		sh install.sh --unattended
		cp agnoster-simple.zsh-theme ~/.oh-my-zsh/themes
		git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
		rm -rf install.sh # GDI Oh My Zsh why're you leaving your trash here?
	fi
	
	if [ ! -d ~/.vim/bundle/Vundle.vim ]; then
		echo "Did not find Vundle installation"
		echo "Installing Vundle..."
		git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
	fi

	pip3 install --user powerline-status
	
	echo "Copying configuration files..."
	for i in "${configuration_files[@]}"
	do
		cp $i ~/.$i
	done

	vim +PluginInstall +qall
	echo 'colorscheme afterglow' >> ~/.vimrc
	
	echo "Applying profile changes..."
	tmux source ~/.tmux.conf
	if [[ ${SHELL} != $(which zsh) ]]; then
		echo "Changing default shell to Zsh (Will prompt for password)"
		chsh -s $(which zsh)
		echo "Installation complete!"
		echo "To finalize changes, log out and back in to use Zsh as the default shell"
		exit 0
	fi

	echo "Installation complete!"
	
	exit 0
}

if [[ "$OSTYPE" == "linux-gnu" ]]; then
	echo "Linux-based OS detected"
	if [ -x "$(command -v apt)" ]; then
		PACKAGE_MANAGER_COMMAND="sudo apt install -y"
		if [ ! -x "$(command -v pip3)" ]; then
			missing_programs+=("python3-pip")
		fi
		sudo apt update
		run_linux_setup
	elif [ -x "$(command -v yum)" ]; then
		PACKAGE_MANAGER_COMMAND="yum -y install"
		if [ ! -x "$(command -v pip3)" ]; then
			missing_programs+=("python3-pip")
		fi
		run_linux_setup
	elif [ -x "$(command -v pacman)" ]; then
		PACKAGE_MANAGER_COMMAND="sudo pacman -S"
		if [ ! -x "$(command -v pip3)" ]; then
			missing_programs+=("python-pip")
		fi
		sudo pacman -S python python-setuptools
		run_linux_setup
	else
		echo "No supported package manager found"
		echo "Install ${missing_programs[@]} using your distro's package manager"
		echo "Proceeding with generic installation"
		run_generic_setup
	fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
	echo "Darwin-based OS detected"
	if [ ! -x "$(command -v pip3)" ]; then
		missing_programs+=("python3")
	fi
	run_mac_setup
else
        echo "Unsupported OS detected"
	echo "Aborting environment setup"
	exit -1
fi

