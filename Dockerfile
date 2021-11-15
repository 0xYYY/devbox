FROM archlinux:base-devel

# Update databases
RUN pacman -Syyu --noconfirm

# Rank mirrors
RUN pacman -S reflector --noconfirm
RUN cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
# RUN reflector --country CA,CH,DE,FR,GB,JP,KR,SG,TW,US --protocol https --delay 1 --fastest 5 \
#     --save /etc/pacman.d/mirrorlist --verbose
RUN reflector --protocol https --country TW,US --delay 1 --fastest 5 --save /etc/pacman.d/mirrorlist --verbose

# System Packages
RUN pacman -S bat bottom colordiff curlie clang cmake cmatrix dog dust exa fd figlet fzf git git-delta git-lfs github-cli gitui go httpie jq lolcat man-db man-pages neovim nyancat openssh pacman-contrib procs ripgrep rust-analyzer sd starship shfmt sudo tar tmux tokei trash-cli unzip zip zoxide zsh zsh-completions --noconfirm

# Create a user solely for installing yay and AUR packages
ARG user=makepkg
RUN useradd --system --create-home $user \
  && echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/$user
USER $user
WORKDIR /home/$user

RUN git clone https://aur.archlinux.org/yay.git \
  && cd yay \
  && makepkg -sri --needed --noconfirm \
  && cd .. \
  && rm -rf .cache yay

RUN yay -S stylua-bin glow --noconfirm

USER root
WORKDIR /root
RUN userdel -r $user
RUN rm /etc/sudoers.d/$user

# Create a sudo user account
RUN useradd --create-home --groups wheel --shell /bin/zsh dev
RUN echo "dev:box" | chpasswd
RUN echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

USER dev
WORKDIR /home/dev

COPY --chown=dev home/ ./

# Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"\
    "" --unattended
RUN mv .zshrc.pre-oh-my-zsh .zshrc

# Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh
RUN sh rustup.sh --verbose -y --no-modify-path
RUN rm rustup.sh
RUN $HOME/.cargo/bin/rustup component add rust-src

# Golang
# modified from https://github.com/udhos/update-golang
RUN version=$(curl --silent https://golang.org/dl/\?mode=json | jq -r '.[].files[].version' | sort \
    | uniq | grep -v -E 'go[0-9\.]+(beta|rc)' | sed -e 's/go//' | sort -V | tail -1) \
    && curl https://storage.googleapis.com/golang/go$version.linux-amd64.tar.gz --output go.tar.gz
RUN tar -xzf go.tar.gz && mv go .go
RUN rm go.tar.gz

# Node JS
RUN git clone https://github.com/nvm-sh/nvm.git .nvm
RUN cd .nvm && git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" \
    $(git rev-list --tags --max-count=1)`

# Yarn Packages
RUN source .nvm/nvm.sh && nvm install --lts && npm install --global yarn
RUN source .nvm/nvm.sh && yarn global add bash-language-server neovim prettier prettier-plugin-solidity pyright typescript typescript-language-server 

# Python
RUN curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh > conda.sh
RUN bash conda.sh -b -p $HOME/.miniconda3 -s
RUN rm conda.sh

# Conda Packages
RUN ./.miniconda3/bin/conda install -n base ipython ipdb black --yes
RUN ./.miniconda3/bin/ipython locate
RUN mv ipython_config.py .ipython/profile_default/
RUN ./.miniconda3/bin/conda create -n neovim --yes pynvim

# Solidity
RUN curl -L https://github.com/web3j/svm/raw/master/install.sh > svm.sh
RUN bash svm.sh
RUN rm svm.sh

# NeoVim
RUN git clone --depth 1 https://github.com/wbthomason/packer.nvim \
    .local/share/nvim/site/pack/packer/start/packer.nvim
RUN nvim --headless -u .config/nvim/packer_install.lua > /dev/null 2>&1
RUN rm .config/nvim/packer_install.lua

CMD ["/usr/bin/zsh"]
