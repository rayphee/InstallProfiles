#!/bin/sh

declare -a configuration_files=("tmux.conf" "vimrc" "zshrc")
declare -a distribution_folders=("tmux" "vim")

echo "Installing Rafi's environment profiles"
echo "Note: git, curl, and development tools are expected to be already installed"
echo "The configuration profiles are written to comply with the latest versions of brew, tmux, zsh, and vim as of 6/21/19"
echo "Currently supports: macOS Mojave+"

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
pip install --user powerline-status

echo "Installing fonts..."
cp fonts/operator_mono/* ~/Library/Fonts

echo "Copying configuration files..."
for i in "${configuration_files[@]}"
do
	cp $i ~/.$i
done

echo "Applying profile changes..."
tmux source ~/.tmux.conf

chsh -s $(which zsh)
