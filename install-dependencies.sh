#!/bin/sh

###
# Prepare installations
###

ARCH=`uname -m`
echo "Current architecture is $ARCH"

###
# Config summary
###

INSTALL_LG=${LAZYGIT:-no}
INSTALL_NV=${NEOVIM:-no}
INSTALL_K=${KUBECTL:-no}
INSTALL_K9=${K9S:-no}
INSTALL_FL=${FLUXCD:-no}
INSTALL_PL=${POWERLINE_FONTS:-no}
INSTALL_ZP=${ZSH_PLUGINS:-no}
INSTALL_FZ=${FZF:-no}

echo "**************"
echo "You chose to install the following configuration:"
echo "Lazygit: ${INSTALL_LG}"
echo "Neovim: ${INSTALL_NV}"
echo "Kubectl: ${INSTALL_K}"
echo "K9s: ${INSTALL_K9}"
echo "FluxCD: ${INSTALL_FL}"
echo "Powerline fonts: ${INSTALL_PL}"
echo "ZSH plugins: ${INSTALL_ZP}"
echo "FZF: ${INSTALL_FZ}"
echo "**************"

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
if [ $INSTALL_LG = "yes"]; then
  echo "Installing Lazygit"
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
else
  echo "Skipping Lazygit"
fi

# install eza
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update
sudo apt install -y eza

# install nvim from source
if [ $INSTALL_NV = "yes" ]; then
  echo "Installing Neovim"
  git clone https://github.com/neovim/neovim
  cd neovim
  git checkout stable
  make CMAKE_BUILD_TYPE=RelWithDebInfo
  sudo make install
  nvim --version
  cd ../
  rm -rf neovim
else
  echo "Skipping Neovim"
fi

# install kubectl
if [ $INSTALL_K = "yes" ]; then
  echo "Installing Kubectl"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
  echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  kubectl version --client
  rm kubectl kubectl.sha256
else
  echo "Skipping Kubectl"
fi

# install K9s
if [ $INSTALL_K9 = "yes" ]; then
  echo "Installing K9s"
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
else
  echo "Skipping K9s"
fi

# install flux cli
if [ $INSTALL_FL = "yes" ]; then
  echo "Installing FluxCD"
  curl -s https://fluxcd.io/install.sh | sudo bash
else
  echo "Skipping FluxCD"
fi

# install powerline fonts
if [ $INSTALL_PL = "yes" ]; then
  echo "Installing Powerline fonts"
  git clone https://github.com/powerline/fonts.git
  cd fonts
  ./install.sh
  cd .. && rm -rf fonts
else
  echo "Skipping Powerline fonts"
fi

# install oh-my-zsh plugins and theme
if [ $INSTALL_ZP = "yes" ]; then
  echo "Installing zsh plugins"
  zsh -c 'git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting'
  zsh -c 'git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions'
  zsh -c 'git clone https://github.com/zdharma-continuum/fast-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting'
  zsh -c 'git clone https://github.com/marlonrichert/zsh-autocomplete ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete'
  zsh -c 'git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search'
  zsh -c 'git clone --depth 1 https://github.com/spaceship-prompt/spaceship-prompt.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/spaceship-prompt'
  zsh -c 'ln -s ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/spaceship-prompt/spaceship.zsh-theme ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/spaceship.zsh-theme'
else
  echo "Skipping zsh plugins"
fi

# install fzf manually (can't get completion to work for zsh when installing the binary)
if [ $INSTALL_FZ = "yes" ]; then
  echo "Installing fzf"
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish
  echo "fzf has been installed in ~/.fzf; add it to your path"
else
  echo "Skipping fzf"
fi
