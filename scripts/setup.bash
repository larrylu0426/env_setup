#!/bin/bash

# author: larrylu
# description: The script to deploy devlop-environment of terminal
function msg() {
    printf '%b\n' "$1" >&2
}

function success() {
    msg "\33[32m[✔]\33[0m ${1}${2}"
}

function error() {
    msg "\33[31m[✘]\33[0m ${1}${2}"
    exit 1
}

function setup() {
    msg 'Installation start'
    # install mirrors-repo
    if [ "$1" == 'Linux' ]; then
        if [ "$2" == 'Ubuntu' ]; then
            sudo cp assets/sources-ubuntu-16.04-tencent.list /etc/apt/sources.list
            sudo apt update
        fi
    fi

    # install base-dependency items
    if [ "$1" == 'Linux' ]; then
        if [ "$2" == 'Ubuntu' ]; then
            sudo apt install -y curl
            sudo apt install -y git
            sudo apt install -y exuberant-ctags
            sudo apt install -y silversearcher-ag
            sudo apt install -y zsh
        elif [ "$2" == 'tlinux' ]; then
            yum remove -y git
            yum install -y sudo
            yum install -y curl-devel
            yum install -y expat-devel
            wget https://github.com/git/git/archive/v2.28.0.tar.gz -O /tmp/git-src.tar.gz
            tar -zxvf /tmp/git-src.tar.gz -C /tmp
            cd /tmp/git*
            make prefix=/opt/git all
            make prefix=/opt/git install
            cd -
            cd /usr/local/bin && ln -s /opt/git/bin/git git && cd -
            yum install -y ctags-etags
            yum install -y the_silver_searcher
        fi
    elif [ "$1" == 'Darwin' ]; then
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        git -C "$(brew --repo)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
        git -C "$(brew --repo homebrew/core)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git
        echo export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles >> $HOME/.zshrc
        brew install ctags
        brew install the_silver_searcher
        brew install wget
        brew install gnu-sed
    fi

    # oh-my-zsh
    sudo chsh -s /bin/zsh $USER
    curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="bira"/g'  $HOME/.zshrc
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/plugins/zsh-syntax-highlighting
    echo source $HOME/.oh-my-zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh >> $HOME/.zshrc    

    # install python-related items
    if [ "$1" == 'Linux' ]; then
        if [ "$2" == 'Ubuntu' ]; then
            sudo apt install -y python-dev
            sudo apt install -y python-pip
        elif [ "$2" == 'tlinux' ]; then
            sudo yum install -y python-devel
            sudo yum install -y python-pip
        fi
    elif [ "$1" == 'Darwin' ]; then
        sudo easy_install pip
    fi
    if [ "$2" == 'tlinux' ]; then
        pip install pip -U  -i https://mirrors.tencent.com/pypi/simple
        pip install --upgrade setuptools
        pip config set global.index-url https://mirrors.tencent.com/pypi/simple
    else
        pip install pip -U  -i https://pypi.tuna.tsinghua.edu.cn/simple
        pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
    fi

    # powerline-status
    pip install powerline-status powerline-mem-segment psutil --user
    if [ "$1" == 'Linux' ]; then
        echo export PATH="$HOME/.local/bin:$PATH" >> $HOME/.zshrc
    elif [ "$1" == 'Darwin' ]; then
        echo export PATH="$HOME/Library/Python/2.7/bin:$PATH" >> $HOME/.zshrc
    fi

    # tmux
    tmux_file='.tmux.conf'
    touch $tmux_file
    echo 'run-shell "powerline-daemon --replace"' >> $tmux_file
    echo 'run-shell "powerline-daemon -q"' >> $tmux_file
    echo 'set-option -g default-shell /bin/zsh' >> $tmux_file
    echo 'set -g mouse on' >> $tmux_file
    if [ "$1" == 'Linux' ]; then
        sudo cp assets/tmux-themes-default.json $HOME/.local/lib/python2.7/site-packages/powerline/config_files/themes/tmux/default.json
        sudo cp assets/tmux-colorschemes-default.json $HOME/.local/lib/python2.7/site-packages/powerline/config_files/colorschemes/default.json
        echo source "$HOME/.local/lib/python2.7/site-packages/powerline/bindings/tmux/powerline.conf" >> $tmux_file
    elif [ "$1" == 'Darwin' ]; then
        sudo cp assets/tmux-themes-default.json $HOME/Library/Python/2.7/lib/python/site-packages/powerline/config_files/themes/tmux/default.json
        sudo cp assets/tmux-colorschemes-default.json $HOME/Library/Python/2.7/lib/python/site-packages/powerline/config_files/colorschemes/default.json
        echo source "$HOME/Library/Python/2.7/lib/python/site-packages/powerline/bindings/tmux/powerline.conf" >> $tmux_file
    fi
    mv $tmux_file $HOME/
    if [ "$1" == 'Linux' ]; then
        if [ "$2" == 'Ubuntu' ]; then
            sudo apt install -y tmux
        elif [ "$2" == 'tlinux' ]; then
            sudo yum install -y tmux
        fi
    elif [ "$1" == 'Darwin' ]; then
        brew install tmux
    fi

    # fzf
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install

    # lua
    if [ "$1" == 'Darwin' ]; then
        cd /tmp
        curl -R -O http://www.lua.org/ftp/lua-5.3.5.tar.gz
        tar -zxvf lua-5.3.5.tar.gz
        cd lua-5.3.5
        make macosx test
        sudo make install
    fi

    # vim
    git clone https://github.com/vim/vim.git /tmp/vim
    cd /tmp/vim/src
    if [ "$1" == 'Darwin' ]; then
        ./configure --with-features=huge --enable-cscope --enable-rubyinterp --enable-largefile --disable-netbeans --enable-pythoninterp --with-python-config-dir=/usr/lib/python2.7/config --enable-perlinterp --enable-luainterp --enable-fail-if-missing --with-lua-prefix=/usr/local
    fi
    if [ "$1" == 'Linux' ]; then
        if [ "$2" == 'Ubuntu' ]; then
            sudo apt-get remove -y vim vim-runtime  vim-tiny vim-common vim-gui-commonsudo apt-get purge vim vim-runtime  vim-tiny vim-common vim-gui-common
            sudo apt-get install -y luajit libluajit-5.1 libncurses5-dev libgnome2-dev libgnomeui-dev libgtk2.0-dev libatk1.0-dev libbonoboui2-dev libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev ruby-dev mercurial libperl-dev
        elif [ "$2" == 'tlinux' ]; then
            sudo yum remove -y vim-enhanced vim-common vim-filesystem vim-minimal
            yum install -y sudo
            sudo yum install -y luajit luajit-devel ncurses ncurses-devel ruby ruby-devel mercurial perl perl-devel lua-devel
        fi
        ./configure --with-features=huge --enable-cscope --enable-rubyinterp --enable-largefile --disable-netbeans --enable-pythoninterp --with-python-config-dir=/usr/lib/python2.7/config --enable-perlinterp --enable-luainterp --with-luajit --enable-fail-if-missing --with-lua-prefix=/usr --enable-gui=gnome2 --enable-cscope --prefix=/usr
    fi
    make
    sudo make install
    success "Installation done"
}

############# MAIN() #############

platform=`uname`
OS=$1

setup $platform $OS
