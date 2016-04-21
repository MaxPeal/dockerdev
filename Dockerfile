# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2:
FROM ubuntu:xenial

# Tell Apt never to prompt
ENV DEBIAN_FRONTEND noninteractive

# Use a volume for non package manager software to persist across container restarts
ENV PREFIX /usr/local
RUN cp -a /usr/local /usr/local.original
VOLUME ["/usr/local"]
RUN ls -al /usr/local


RUN set -x \
 # Set up UTF support
 && locale-gen en_US en_US.UTF-8 \
 && dpkg-reconfigure locales \
 && update-locale LANG=en_US.UTF-8 \

 # Set apt mirror
 && sed 's:archive.ubuntu.com/ubuntu/:mirrors.rit.edu/ubuntu-archive/:' -i /etc/apt/sources.list \

 # never install recommends automatically
 && echo 'Apt::Install-Recommends "false";' > /etc/apt/apt.conf.d/docker-no-recommends \
 && echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/docker-assume-yes \
 && echo 'APT::Get::AutomaticRemove "true";' > /etc/apt/apt.conf.d/docker-auto-remove \

 # Enable backports and others that are disabled by default
 && sed 's/^#\s*deb/deb/' -i /etc/apt/sources.list \

 # Enable automatic preference to use backport
 && echo 'Package: *'                        >> /etc/apt/preferences \
 && echo 'Pin: release a=xenial-backports'   >> /etc/apt/preferences \
 && echo 'Pin-Priority: 500'                 >> /etc/apt/preferences \
 && echo "DONE *****************************************************"

# Set up PPAs
RUN apt-get update \
 && apt-get install \
      software-properties-common \
      apt-transport-https \
 && add-apt-repository ppa:git-core/ppa \
 && echo "DONE *****************************************************"

 RUN apt-get update \
 && apt-get upgrade \
 && apt-get install \
      aptitude \
      bash \
      coreutils \
      git \
      gnupg \
      gzip \
      iputils-ping \
      ack-grep \
      ca-certificates \
      build-essential \
      bzr \
      curl \
      exuberant-ctags \
      file \
      git \
      htop \
      less \
      man-db \
      manpages \
      mercurial \
      mosh \
      net-tools \
      psmisc \
      ssh-client \
      subversion \
      rsync \
      wget \

      # Ruby dependencies
      zlib1g-dev \
      libssl-dev \
      libreadline-dev \
      libyaml-dev \
      libsqlite3-dev \
      sqlite3 \
      libxml2-dev \
      libxslt1-dev \
      libcurl4-openssl-dev \
      libffi-dev \

      # Vim dependencies
      libacl1 \
      libc6 \
      libgpm2 \
      libncurses5-dev \
      libselinux1 \
      libssl-dev \
      libtcl8.6 \
      libtinfo5 \
      python-dev \

      # Tmux depndencies
      automake \
      libevent-dev \
      pkg-config \
 && echo "DONE *****************************************************"


# Install docker-engine
RUN apt-key adv --keyserver 'hkp://p80.pool.sks-keyservers.net:80' \
                --recv-keys '58118E89F3A912897C070ADBF76221572C52609D' \
 # This should be changed to ubuntu-xenial when it is released
 # && echo 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' > /etc/apt/sources.list.d/docker.list
 && echo 'deb https://apt.dockerproject.org/repo ubuntu-wily main' > /etc/apt/sources.list.d/docker.list \
 && apt-get update \
 && apt-get install \
      openssh-server \
      linux-image-extra-virtual-lts-xenial \
      docker-engine \
 && echo "DONE *****************************************************"


# Set up ssh server
EXPOSE 22
RUN apt-get install \
      openssh-server \

 # Delete the host keys it just generated. At runtime, we'll regenerate those
 && rm -f /etc/ssh/ssh_host_* \
 && mkdir -pv /var/run/sshd /root/.ssh \
 && chmod 0700 /root/.ssh \
 && echo "DONE *****************************************************"


# Install docker-compose
RUN set -x \
 && version='1.7.0' \
 && curl -L -o /tmp/docker-compose "https://github.com/docker/compose/releases/download/${version}/docker-compose-$(uname -s)-$(uname -m)" \
 && install -v /tmp/docker-compose "$PREFIX/bin/docker-compose-${version}" \
 && rm -vrf /tmp/* \
 && ln -s "$PREFIX/bin/docker-compose-${version}" "$PREFIX/bin/docker-compose" \
 && echo "DONE *****************************************************"


# Install Golang
ENV GOROOT=$PREFIX/go GOPATH=/opt/gopath
ENV PATH $GOROOT/bin:$PATH
RUN set -x \
 && version='1.5.2' sha1='cae87ed095e8d94a81871281d35da7829bd1234e' \
 && cd /tmp \
 && curl -L -o go.tgz "https://storage.googleapis.com/golang/go${version}.linux-amd64.tar.gz" \
 && shasum -a 1 go.tgz | grep -q "$sha1" \
 && mkdir -vp "$GOROOT" \
 && tar -xz -C "$GOROOT" --strip-components=1 -f go.tgz \
 && rm /tmp/go.tgz \
 && echo "DONE *****************************************************"


RUN echo "export GOROOT=$GOROOT" >> /root/.bashrc \
 && echo "export GOPATH=$GOPATH" >> /root/.bashrc \
 && echo "export PATH=$GOPATH/bin:$GOROOT/bin:\$PATH" >> /root/.bashrc \
 && mkdir -p $GOPATH \
 && echo "DONE *****************************************************"


# Install VIM
RUN set -x \
 && version='7.4.1752' \
 && git clone -b "v${version}" https://github.com/vim/vim.git /opt/vim \
 && cd /opt/vim \
 && ./configure --with-features=huge --with-compiledby='dockerdev' \
 && make \
 && make install \
 && echo "DONE *****************************************************"


# Install tmux
RUN set -x \
 && version='2.2' \
 && git clone -b "${version}" https://github.com/tmux/tmux.git /opt/tmux \
 && cd /opt/tmux \
 && ./autogen.sh \
 && ./configure \
 && make \
 && make install \
 && curl -L -o /etc/bash_completion.d/tmux "https://raw.githubusercontent.com/przepompownia/tmux-bash-completion/master/completions/tmux" \
 && echo "DONE *****************************************************"


# Install direnv
RUN set -x \
 && version='v2.7.0' \
 && git clone -b "${version}" 'http://github.com/direnv/direnv' "$GOPATH/src/github.com/direnv/direnv" \
 && cd "$GOPATH/src/github.com/direnv/direnv" \
 && make install \
 && echo "DONE *****************************************************"


# Install jq
RUN set -x \
 && version='1.5' \
 && curl -m 10 -L -o /tmp/jq "https://github.com/stedolan/jq/releases/download/jq-${version}/jq-linux64" \
 && install -v /tmp/jq "$PREFIX/bin/jq" \
 && rm -vfv /tmp/* \
 && echo "DONE *****************************************************"


# Install AWS CLI
RUN set -x \
 && apt-get install python-pip python-setuptools \
 && pip install awscli \
 && rm -vrf /tmp/* \
 && echo "DONE *****************************************************"


# Install goodguide-git-hooks
RUN set -x \
 && version='0.0.8' \
 && cd /tmp \
 && curl -L -o goodguide-git-hooks.tgz "https://github.com/GoodGuide/goodguide-git-hooks/releases/download/v${version}/goodguide-git-hooks_${version}_linux_amd64.tar.gz" \
 && tar -xvzf goodguide-git-hooks.tgz \
 && install -v goodguide-git-hooks "$PREFIX/bin/" \
 && rm -vrf /tmp/* \
 && echo "DONE *****************************************************"


# Install forego
RUN go get -u -v github.com/ddollar/forego \
 && echo "DONE *****************************************************"


# Install hub
RUN set -x \
 && version='2.2.2' sha256='da2d780f6bca22d35fdf71c8ba1d11cfd61078d5802ceece8d1a2c590e21548d' \
 && cd /tmp \
 && curl -L -o hub.tgz "https://github.com/github/hub/releases/download/v${version}/hub-linux-amd64-${version}.tgz" \
 && shasum -a 256 hub.tgz | grep -q "${sha256}" \
 && tar -xvzf hub.tgz \
 && cd hub-linux-amd64-${version}/ \
 && ./install \
 && rm -vrf /tmp/* \
 && echo "DONE *****************************************************"

# Install rbenv, ruby-build, rbenv-gem-rehash and finally Ruby
RUN set -x \
 && git clone https://github.com/sstephenson/rbenv.git ~/.rbenv \
 && echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc \
 &&       export PATH="$HOME/.rbenv/bin:$PATH" \
 && echo 'eval "$(rbenv init -)"' >> ~/.bashrc \
 &&       eval "$(rbenv init -)" \
 && git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build \
 && echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc \
 &&       export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH" \
 && git clone https://github.com/sstephenson/rbenv-gem-rehash.git ~/.rbenv/plugins/rbenv-gem-rehash \
 && rbenv install 2.2.3 \
 && rbenv global 2.2.3 \
 && ruby -v \
 && echo "DONE *****************************************************"

# Set up some environment for SSH clients (ENV statements have no affect on ssh clients)
RUN echo "export DOCKER_HOST='unix:///var/run/docker.sock'" >> /root/.bashrc \
 && echo "export DEBIAN_FRONTEND=noninteractive" >> /root/.bashrc

# A place for personal scripts
RUN echo 'export PATH="/root/.bin:$PATH"' >> ~/.bashrc

RUN cp -a /etc/ssh/ /etc/ssh.original/
 && cp -a /etc/pam.d/ /etc/pam.d.original/
COPY docker/etc/ssh/* /etc/ssh/
COPY docker/etc/pam.d/* /etc/pam.d/

# use a volume for the SSH host keys, to allow a persistent host ID across container restarts
VOLUME ["/etc/ssh/ssh_host_keys"]

COPY docker/runtime/entrypoint /opt/docker/runtime/entrypoint
ENTRYPOINT ["/opt/docker/runtime/entrypoint"]

# these volumes allow creating a new container with these directories persisted, using --volumes-from
VOLUME ["/code", "/root"]

WORKDIR /root
