FROM ubuntu:14.04

# common packages
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    ca-certificates curl file \
    build-essential \
    autoconf automake autotools-dev libtool xutils-dev libpq-dev pkg-config openssl libssl-dev && \
    rm -rf /var/lib/apt/lists/*

RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- --default-toolchain stable -y

ENV PATH=/root/.cargo/bin:$PATH

RUN cargo install diesel_cli --no-default-features --features postgres
RUN cargo install wasm-bindgen-cli --version 0.2.40
RUN rustup target add wasm32-unknown-unknown

ENV RUSTFLAGS="-Aproc-macro-derive-resolution-fallback"

WORKDIR /projects

# The following instructions set the right
# permissions and scripts to allow the container
# to be run by an arbitrary user (i.e. a user
# that doesn't already exist in /etc/passwd)
# Adding user to the 'root' is a workaround for https://issues.jboss.org/browse/CDK-305
RUN useradd -u 1000 -G users,root -d /home/user --shell /bin/bash -m user && \
    usermod -p "*" user

USER user

ENV HOME /home/user
RUN bash -c 'for f in "/home/user" "/etc/passwd" "/etc/group" "/projects"; do\
           sudo chgrp -R 0 ${f} && \
           sudo chmod -R g+rwX ${f}; \
        done && \
        # Generate passwd.template \
        cat /etc/passwd | \
        sed s#user:x.*#user:x:\${USER_ID}:\${GROUP_ID}::\${HOME}:/bin/bash#g \
        > /home/user/passwd.template && \
        # Generate group.template \
        cat /etc/group | \
        sed s#root:x:0:#root:x:0:0,\${USER_ID}:#g \
        > /home/user/group.template'

COPY ["entrypoint.sh","/home/user/entrypoint.sh"]
ENTRYPOINT ["/home/user/entrypoint.sh"]
CMD tail -f /dev/null
