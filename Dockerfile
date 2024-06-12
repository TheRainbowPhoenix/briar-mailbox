# syntax=docker/dockerfile:1

ARG JAVA_VERSION=17
ARG ALPINE_VERSION=3.20
ARG UBUNTU_VERSION=jammy
ARG DEBIAN_VERSION=bullseye

FROM eclipse-temurin:${JAVA_VERSION}-jdk-ubi9-minimal AS build
WORKDIR /mailbox
COPY . /mailbox
ARG TARGETARCH
RUN if [ "$TARGETARCH" = "arm64" ]; then \
    ./gradlew aarch64LinuxJar ; \
    mv mailbox-cli/build/libs/mailbox-cli-linux-aarch64.jar mailbox-cli/build/libs/mailbox-cli-linux.jar ; \
    elif [ "$TARGETARCH" = "amd64" ]; then \
    ./gradlew x86LinuxJar ; \
    mv mailbox-cli/build/libs/mailbox-cli-linux-x86_64.jar mailbox-cli/build/libs/mailbox-cli-linux.jar ; \
    else \
    echo 'The target architecture is not supported. Exiting.' ; \
    exit 1 ; \
    fi;

FROM ghcr.io/linuxserver/baseimage-alpine:${ALPINE_VERSION} AS linuxserver-alpine

ARG JAVA_VERSION JAVA_VERSION

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="smhrambo"

RUN \
  echo "**** install dependencies ****" && \
  apk upgrade && \
  apk add --no-cache \
    openjdk${JAVA_VERSION}-jre-headless && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/*

# add bin files
COPY --from=build /mailbox/mailbox-cli/build/libs/mailbox-cli-linux.jar /app/mailbox-cli-linux.jar

# add local files
COPY root/ /

FROM ghcr.io/linuxserver/baseimage-ubuntu:${UBUNTU_VERSION} AS linuxserver-ubuntu

ARG JAVA_VERSION JAVA_VERSION

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="smhrambo"

RUN \
  echo "**** install dependencies ****" && \
  apt update && \
  apt upgrade && \
  apt install --no-cache \
    openjdk-${JAVA_VERSION}-jre-headless && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/*

# add bin files
COPY --from=build /mailbox/mailbox-cli/build/libs/mailbox-cli-linux.jar /app/mailbox-cli-linux.jar

# add local files
COPY root/ /

RUN bash -c 'mkdir -p /config/.local/share/briar-mailbox/tor'

WORKDIR /app

FROM ghcr.io/linuxserver/baseimage-debian:${DEBIAN_VERSION} AS linuxserver-debian

ARG JAVA_VERSION JAVA_VERSION

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="smhrambo"

RUN \
  echo "**** install dependencies ****" && \
  apt update && \
  apt upgrade && \
  apt install --no-cache \
    openjdk-${JAVA_VERSION}-jre-headless && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/*

# add bin files
COPY --from=build /mailbox/mailbox-cli/build/libs/mailbox-cli-linux.jar /app/mailbox-cli-linux.jar

# add local files
COPY root/ /

RUN bash -c 'mkdir -p /config/.local/share/briar-mailbox/tor'

WORKDIR /app
