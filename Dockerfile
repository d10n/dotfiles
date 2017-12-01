FROM ubuntu:latest

ENV TERM xterm-256color

#RUN apt-get-update && \
#    apt-get install -y \

RUN apt-get update && \
    apt-get install -y \
    locales \
    lsb-release \
    software-properties-common

ENV LANG en_US.UTF-8
RUN localedef -i en_US -f UTF-8 en_US.UTF-8 && \
/usr/sbin/update-locale LANG=$LANG

RUN apt-get update && \
    apt-get install -y \
    sudo \
    build-essential \
    curl \
    git \
    man \
    python \
    tmux \
    vim \
    wget \
    zsh

RUN chsh -s /bin/zsh

RUN useradd -m -s /bin/zsh tester && \
    echo 'tester  ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    bash -c 'rm -f /{root,home/tester}/{.bashrc,.profile}'

COPY . /home/tester/.config/dotfiles
RUN chown -R tester:tester ~tester && \
    sh -c 'rm -f /home/tester/.config/dotfiles/.*.skip'

RUN sudo -u tester -i sh -c 'cd ~/.config/dotfiles; cp ./examples/* .' && \
    sudo -u tester -i sh -c 'yes | /home/tester/.config/dotfiles/install' && \
    sh -c 'yes | /home/tester/.config/dotfiles/install'

CMD sudo -u tester -i
