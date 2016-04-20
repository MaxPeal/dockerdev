# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2:
FROM ubuntu:xenial

ENV PREFIX /usr/local

# Set up PPAs
RUN apt-get update \
 && apt-get install -y python-software-properties \
                    software-properties-common \
 && add-apt-repository ppa:git-core/ppa -y

 # Install base packages
RUN apt-get update \
 # && apt-get upgrade \
 && apt-get install -y \
      ack-grep \
      apt-transport-https \
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
      python-software-properties \
      libffi-dev

# Set up ssh server
EXPOSE 22
RUN apt-get install -y \
            openssh-server \

 # Delete the host keys it just generated. At runtime, we'll regenerate those
 && rm -f /etc/ssh/ssh_host_* \
 && mkdir -pv /var/run/sshd /root/.ssh \
 && chmod 0700 /root/.ssh

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
 && rm /tmp/go.tgz

RUN echo "export GOROOT=$GOROOT" >> /root/.profile \
 && echo "export GOPATH=$GOPATH" >> /root/.profile \
 && echo "export PATH=$GOPATH/bin:$GOROOT/bin:\$PATH" >> /root/.profile \
 && mkdir -p $GOPATH

# Install VIM
RUN set -x \
 && version='7.4.1752' \
 && apt-get install -y \
      libacl1 \
      libc6 \
      libgpm2 \
      libncurses5-dev \
      libselinux1 \
      libssl-dev \
      libtcl8.6 \
      libtinfo5 \
      python-dev \

 && git clone -b "v${version}" https://github.com/vim/vim.git /opt/vim \
 && cd /opt/vim \
 && ./configure --with-features=huge --with-compiledby='dockerdev' \
 && make \
 && make install

# Install tmux
RUN set -x \
 && version='2.2' \
 && apt-get update \
 && apt-get install -y \
      automake \
      libevent-dev \
      pkg-config \
 && git clone -b "${version}" https://github.com/tmux/tmux.git /opt/tmux \
 && cd /opt/tmux \
 && ./autogen.sh \
 && ./configure \
 && make \
 && make install \
 && curl -L -o /etc/bash_completion.d/tmux "https://raw.githubusercontent.com/przepompownia/tmux-bash-completion/master/completions/tmux"

# Install docker-engine
RUN set -x \
 && apt-key adv --keyserver 'hkp://p80.pool.sks-keyservers.net:80' --recv-keys '58118E89F3A912897C070ADBF76221572C52609D' \
 && echo 'deb https://apt.dockerproject.org/repo debian-jessie main' > /etc/apt/sources.list.d/docker.list \
 && apt-get update \
 && apt-cache policy docker-engine \
 && apt-get install -y docker-engine

# Install docker-compose
RUN set -x \
 && version='1.7.0' \
 && curl -L -o /tmp/docker-compose "https://github.com/docker/compose/releases/download/${version}/docker-compose-$(uname -s)-$(uname -m)" \
 && install -v /tmp/docker-compose "$PREFIX/bin/docker-compose-${version}" \
 && rm -vrf /tmp/* \
 && ln -s "$PREFIX/bin/docker-compose-${version}" "$PREFIX/bin/docker-compose"

# Install direnv
RUN set -x \
 && version='v2.7.0' \
 && git clone -b "${version}" 'http://github.com/direnv/direnv' "$GOPATH/src/github.com/direnv/direnv" \
 && cd "$GOPATH/src/github.com/direnv/direnv" \
 && make install

# install jq
RUN set -x \
 && version='1.5' \
 && curl -m 10 -L -o /tmp/jq "https://github.com/stedolan/jq/releases/download/jq-${version}/jq-linux64" \
 && install -v /tmp/jq "$PREFIX/bin/jq" \
 && rm -vfv /tmp/*

# install AWS CLI
RUN set -x \
 && apt-get install -y python-pip python-setuptools \
 && pip install awscli \
 && rm -vrf /tmp/*

# install goodguide-git-hooks
RUN set -x \
 && version='0.0.8' \
 && cd /tmp \
 && curl -L -o goodguide-git-hooks.tgz "https://github.com/GoodGuide/goodguide-git-hooks/releases/download/v${version}/goodguide-git-hooks_${version}_linux_amd64.tar.gz" \
 && tar -xvzf goodguide-git-hooks.tgz \
 && install -v goodguide-git-hooks "$PREFIX/bin/" \
 && rm -vrf /tmp/*

# install forego
RUN go get -u -v github.com/ddollar/forego

# install hub
RUN set -x \
 && version='2.2.2' sha256='da2d780f6bca22d35fdf71c8ba1d11cfd61078d5802ceece8d1a2c590e21548d' \
 && cd /tmp \
 && curl -L -o hub.tgz "https://github.com/github/hub/releases/download/v${version}/hub-linux-amd64-${version}.tgz" \
 && shasum -a 256 hub.tgz | grep -q "${sha256}" \
 && tar -xvzf hub.tgz \
 && cd hub-linux-amd64-${version}/ \
 && ./install \
 && rm -vrf /tmp/*

# install slackline to update Slack #status channel with /me messages
RUN go get -v github.com/davidhampgonsalves/slackline

# install rbenv and ruby-build
RUN set -x \
  && git clone https://github.com/sstephenson/rbenv.git ~/.rbenv \
  && echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc \
  && echo 'eval "$(rbenv init -)"' >> ~/.bashrc \
  && git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build

# Set up some environment for SSH clients (ENV statements have no affect on ssh clients)
RUN echo "export DOCKER_HOST='unix:///var/run/docker.sock'" >> /root/.profile
RUN echo "export DEBIAN_FRONTEND=noninteractive" >> /root/.profile

COPY etc/ssh/* /etc/ssh/
COPY etc/pam.d/* /etc/pam.d/

# use a volume for the SSH host keys, to allow a persistent host ID across container restarts
VOLUME ["/etc/ssh/ssh_host_keys"]

COPY docker/runtime/entrypoint /opt/docker/runtime/entrypoint
ENTRYPOINT ["/opt/docker/runtime/entrypoint"]

# these volumes allow creating a new container with these directories persisted, using --volumes-from
VOLUME ["/code", "/root"]

WORKDIR /root
