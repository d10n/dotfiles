FROM docker.io/library/alpine:latest

ENV TERM xterm-256color

RUN apk add --no-cache \
    shadow \
    sudo \
    bash \
    curl \
    git \
    git-perl \
    less \
    man-pages \
    man-db \
    ncurses \
    perl \
    python3 \
    tmux \
    vim \
    wget \
    zsh \
    zsh-doc \
    zsh-vcs \
    && \
    ln -sf python3 /usr/bin/python && \
    usermod -s /bin/zsh root && \
    useradd -m -s /bin/zsh tester && \
    echo 'tester  ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# COPY --chown is too new and chown -R hangs on mac,
# so use a temporary folder and cp instead
COPY . /opt/dotfiles
RUN sudo -u tester -i mkdir -p ~tester/.config && \
    sudo -u tester -i cp -R /opt/dotfiles ~tester/.config/dotfiles && \
    rm -rf /opt/dotfiles && \
    sudo -u tester -i sh -c 'rm -f /home/tester/.config/dotfiles/.*.skip' && \
    sudo -u tester -i sh -c 'cd ~/.config/dotfiles; cp ./examples/* .' && \
    sudo -u tester -i sh -c 'yes | ~tester/.config/dotfiles/install' && \
    sh -c 'yes | ~tester/.config/dotfiles/install'

CMD ["/usr/bin/sudo", "-u", "tester", "-i"]
