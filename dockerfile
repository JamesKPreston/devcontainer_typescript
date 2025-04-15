FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    curl \
    file \
    git \
    locales \
    perl \
    python3 \
    sudo \
    unzip \
    zsh \
    stow \
    procps && \
    locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    USER=devuser

# Create user
RUN useradd -ms /bin/zsh $USER && echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER $USER
WORKDIR /home/$USER

# Install Linuxbrew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zprofile && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc && \
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/home/devuser/.nodenv/bin:/home/devuser/.pub-cache/bin:$PATH"

# Clone dotfiles and stow
RUN git clone https://github.com/JamesKPreston/dotfiles.git ~/dotfiles && \
    cd ~/dotfiles && \
    find . -maxdepth 2 -type f -exec bash -c 'target="$HOME/$(basename {})"; [ -e "$target" ] && rm -f "$target"' \; && \
    for dir in */; do [ -d "$dir" ] && stow "$dir"; done

# Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Starship
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y && \
    echo 'eval "$(starship init zsh)"' >> ~/.zshrc

# nodenv
RUN git clone https://github.com/nodenv/nodenv.git ~/.nodenv && \
    echo 'export PATH="$HOME/.nodenv/bin:$PATH"' >> ~/.zshrc && \
    echo 'eval "$(nodenv init -)"' >> ~/.zshrc && \
    git clone https://github.com/nodenv/node-build.git ~/.nodenv/plugins/node-build && \
    ~/.nodenv/bin/nodenv install 20.11.1 && \
    ~/.nodenv/bin/nodenv global 20.11.1

# fvm

# Install Dart & FVM
RUN sudo apt-get update && \
    sudo apt-get install -y apt-transport-https && \
    curl -s https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/dart-archive-keyring.gpg] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main" | sudo tee /etc/apt/sources.list.d/dart_stable.list && \
    sudo apt-get update && \
    sudo apt-get install -y dart && \
    echo 'export PATH="$HOME/.pub-cache/bin:$PATH"' >> ~/.zshrc && \
    export PATH="$HOME/.pub-cache/bin:$PATH" && \
    dart pub global activate fvm && \
    fvm install 3.19.0 && \
    fvm global 3.19.0 && \
    ln -s ~/.fvm/versions/3.19.0/bin/flutter ~/.pub-cache/bin/flutter && \
    echo 'alias flutter="fvm flutter"' >> ~/.zshrc && \
    echo 'export PATH="$HOME/.fvm/versions/3.19.0/bin:$PATH"' >> ~/.zshrc

# Install lazygit
RUN LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') && \
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" && \
    tar xf lazygit.tar.gz lazygit && \
    sudo install lazygit /usr/local/bin && \
    rm lazygit.tar.gz

CMD ["zsh"]
