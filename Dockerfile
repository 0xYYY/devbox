FROM archlinux:base-devel

# Update databases
RUN pacman -Syyu --noconfirm

# Rank mirrors
RUN pacman -S reflector --noconfirm
RUN cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
RUN reflector --country CA,CH,DE,FR,GB,IN,JP,KR,SG,TW,US --protocol https --delay 1 --fastest 5 --save /etc/pacman.d/mirrorlist --verbose

# Insall packages
RUN pacman -S bat bottom choose colordiff curlie clang cmake cmatrix dog dust exa fd figlet fzf \
    git git-delta git-lfs github-cli gitui glow httpie jq lolcat man-db man-pages neovim nyancat \
    openssh pacman-contrib procs ripgrep rust-analyzer sd starship shfmt sudo tar tmux tokei \
    trash-cli unzip xsv zip zoxide zsh zsh-completions \
    --noconfirm

# Create a user solely for installing yay and AUR packages
# Create user "aur"
ARG user=aur
RUN useradd --system --create-home $user \
  && echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/$user
USER $user
WORKDIR /home/$user

# Yay
RUN git clone https://aur.archlinux.org/yay.git \
  && cd yay \
  && makepkg -sri --needed --noconfirm \
  && cd .. \
  && rm -rf .cache yay

RUN yay -S fnm-bin --noconfirm

# Delete AUR user and change back to root
USER root
WORKDIR /root
RUN userdel -r $user
RUN rm /etc/sudoers.d/$user

# Create a sudo user "dev"
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
RUN $HOME/.cargo/bin/rustup toolchain install nightly

# Golang
# modified from https://github.com/udhos/update-golang
RUN version=$(curl --silent https://go.dev/dl/\?mode=json | jq -r '.[].files[].version' | sort \
    | uniq | grep -v -E 'go[0-9\.]+(beta|rc)' | sed -e 's/go//' | sort -V | tail -1) \
    && curl https://storage.googleapis.com/golang/go$version.linux-amd64.tar.gz --output go.tar.gz
RUN tar -xzf go.tar.gz && mv go .go
RUN rm go.tar.gz

# NodeJS
RUN fnm install --lts && version=$(ls $HOME/.local/share/fnm/node-versions/) \
    && fnm exec --using $version npm install --global yarn \
    && fnm exec --using $version yarn global add bash-language-server neovim prettier \
        prettier-plugin-solidity pyright typescript typescript-language-server 

# Python
RUN curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh > conda.sh
RUN bash conda.sh -b -p $HOME/.miniconda3 -s
RUN rm conda.sh
RUN ./.miniconda3/bin/conda install -n base ipython ipdb black pynvim --yes
RUN ./.miniconda3/bin/ipython locate
RUN mv ipython_config.py .ipython/profile_default/

# Solidity
RUN ./.miniconda3/bin/pip install solc-select
RUN ./.miniconda3/bin/solc-select install $(./.miniconda3/bin/solc-select install | tail -1)
RUN curl -L https://foundry.paradigm.xyz | bash
RUN $HOME/.foundry/bin/foundryup

# NeoVim
RUN git clone --depth 1 https://github.com/wbthomason/packer.nvim \
    .local/share/nvim/site/pack/packer/start/packer.nvim
RUN nvim --headless -u .config/nvim/packer_install.lua > /dev/null 2>&1
RUN rm .config/nvim/packer_install.lua

# Tmux
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
RUN ~/.tmux/plugins/tpm/scripts/install_plugins.sh --tmux-echo >/dev/null 2>&1

CMD ["/usr/bin/zsh"]
