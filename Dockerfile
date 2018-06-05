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


## Ansible install

RUN mkdir /etc/ansible/ /ansible
RUN echo "[local]" >> /etc/ansible/hosts && \
    echo "localhost" >> /etc/ansible/hosts

WORKDIR /ansible
RUN git clone --recursive https://github.com/ansible/ansible.git ./ && \
    git checkout stable-${ANSIBLE_VERSION} && \
    source /ansible/hacking/env-setup

#RUN \
#  curl -fsSL https://releases.ansible.com/ansible/ansible-2.2.2.0.tar.gz -o ansible.tar.gz && \
#  tar -xzf ansible.tar.gz -C ansible --strip-components 1 && \
#  rm -fr ansible.tar.gz /ansible/docs /ansible/examples /ansible/packaging

RUN mkdir -p /ansible/playbooks
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