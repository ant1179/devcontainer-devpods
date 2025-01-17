#!/bin/sh

###
# Prepare installations
###

ARCH=`uname -m`
echo "Current architecture is $ARCH"

###
# Install packages
###

# install all binary packages using apt
sudo apt update && \
  sudo apt install -y software-properties-common && \
  sudo add-apt-repository universe && \
  sudo apt update && \
  sudo apt install -y apt-transport-https ca-certificates gnupg git tree curl wget bat gpg ripgrep stow cmake tmux fd-find direnv

# install lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
  echo "Downloading arm64 version of Lazygit"
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_arm64.tar.gz"
else
  echo "Downloading x86_64 version of Lazygit"
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
fi
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
lazygit --version
rm lazygit.tar.gz lazygit

# install eza
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update
sudo apt install -y eza

# install nvim from source
git clone https://github.com/neovim/neovim
cd neovim
git checkout stable
make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install
nvim --version
cd ../
rm -rf neovim

# install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
rm kubectl kubectl.sha256

# install K9s
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
  echo "Downloading the k9s version for ARM"
  wget https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_linux_arm64.deb
  sudo apt install ./k9s_linux_arm64.deb
  rm k9s_linux_arm64.deb
else
  echo "Downloading the k9s version for x86_64"
  wget https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_linux_amd64.deb
  sudo apt install ./k9s_linux_amd64.deb
  rm k9s_linux_amd64.deb
fi

# install flux cli
curl -s https://fluxcd.io/install.sh | sudo bash

# install powerline fonts
git clone https://github.com/powerline/fonts.git
cd fonts
./install.sh
cd .. && rm -rf fonts

# install oh-my-zsh plugins
zsh -c 'git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting'
zsh -c 'git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions'
zsh -c 'git clone https://github.com/zdharma-continuum/fast-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting'
zsh -c 'git clone https://github.com/marlonrichert/zsh-autocomplete ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete'
zsh -c 'git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search'

# install oh-my-zsh theme
mkdir -p $ZSH_CUSTOM/themes
zsh -c 'git clone --depth 1 https://github.com/spaceship-prompt/spaceship-prompt.git $ZSH_CUSTOM/themes/spaceship-prompt'
zsh -c 'ln -s $ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme $ZSH_CUSTOM/themes/spaceship.zsh-theme'

# install fzf manually (can't get completion to work for zsh when installing the binary)
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish
echo "fzf has been installed in ~/.fzf; add it to your path"

###
# Delete git files
###

echo "Cleaning up workspace"
rm -rfv $PWD/.git
rm -v $PWD/install-dependencies.sh
rm -v $PWD/.devcontainer.json
rm -v $PWD/.gitignore

