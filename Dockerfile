FROM ubuntu:focal

ENV DEBIAN_FRONTEND="noninteractive"
ENV TZ="Europe/London"
ENV PATH="/root/.cargo/bin:${PATH}"

RUN  apt update &&\
  apt install -y cmake pkg-config libssl-dev git build-essential clang libclang-dev curl libz-dev

RUN (curl https://sh.rustup.rs -sSf | sh -s -- -y)

RUN rustup default stable && \
  rustup update &&\
  rustup update nightly &&\
  rustup target add wasm32-unknown-unknown --toolchain nightly

RUN git clone https://github.com/paritytech/polkadot.git &&\
	cd polkadot &&\
	git checkout bf2d87a &&\
	cargo build --release --features=real-overseer

RUN git clone  https://github.com/substrate-developer-hub/substrate-parachain-template &&\
  cd substrate-parachain-template && \
  cargo build -v

RUN apt-get update && apt-get install -y nodejs npm

RUN mkdir /test

WORKDIR /test

COPY package.json .

RUN npm install

COPY registerPara.js test-docker-old.sh ./

RUN echo 1234 && ./test-docker-old.sh
