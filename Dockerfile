FROM golang:alpine

ENV TERRAFORM_VERSION=0.11.7
ENV ANSIBLE_VERSION=2.6

RUN apk add --update \
    bash \
    curl \
    g++ \
    gcc \
    git \
    libffi-dev \
    make \
    openssh \
    openssh-client \
    openssl-dev \
    python-dev \
    py-boto \
    py-dateutil \
    py-httplib2 \
    py-jinja2 \
    py-paramiko \
    py-pip \
    py-setuptools \
    py-yaml \
    tar && \
  pip install --upgrade pip && \
  pip install --upgrade python-keyczar pycrypto cryptography ansible && \
  rm -rf /var/cache/apk/*

## Install config transpiler for CoreOS

RUN wget https://github.com/coreos/container-linux-config-transpiler/releases/download/v0.9.0/ct-v0.9.0-x86_64-unknown-linux-gnu && \
    mv ct-v0.9.0-x86_64-unknown-linux-gnu /usr/local/bin/ct && \
    chmod 755 /usr/local/bin/ct

## Ansible install

RUN mkdir /etc/ansible/ /ansible
RUN echo "[local]" >> /etc/ansible/hosts && \
    echo "localhost" >> /etc/ansible/hosts

WORKDIR /ansible
RUN git clone --recursive https://github.com/ansible/ansible.git ./ && \
    git checkout stable-${ANSIBLE_VERSION} && \
    source /ansible/hacking/env-setup

RUN mkdir -p /ansible/playbooks && \
    mkdir -p /root/.ansible/cp
WORKDIR /ansible/playbooks

ENV ANSIBLE_GATHERING smart
ENV ANSIBLE_HOST_KEY_CHECKING false
ENV ANSIBLE_RETRY_FILES_ENABLED false
ENV ANSIBLE_ROLES_PATH /ansible/playbooks/roles
ENV ANSIBLE_SSH_PIPELINING True
ENV PATH /ansible/bin:$PATH
ENV PYTHONPATH /ansible/lib

## Terraform install

ENV TF_DEV=true
ENV TF_RELEASE=true

WORKDIR $GOPATH/src/github.com/hashicorp/terraform
RUN git clone https://github.com/hashicorp/terraform.git ./ && \
    git checkout v${TERRAFORM_VERSION} && \
    /bin/bash scripts/build.sh

WORKDIR $GOPATH
ENTRYPOINT ["terraform"]