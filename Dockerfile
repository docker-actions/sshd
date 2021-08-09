FROM ubuntu:focal as build

ARG REQUIRED_PACKAGES="openssh-server liblzma5 liblz4-1 libgcrypt20 libattr1"

ENV ROOTFS /build/rootfs
ENV BUILD_DEBS /build/debs
ENV DEBIAN_FRONTEND=noninteractive
ENV GOPATH ${ROOTFS}/usr

# Build pre-requisites
RUN bash -c 'mkdir -p ${BUILD_DEBS} ${ROOTFS}/{bin,sbin,usr/share,usr/bin,usr/sbin,usr/lib,/usr/local/bin,etc,container_user_home}'

# Fix permissions
RUN chown -Rv 100:root $BUILD_DEBS

# Install pre-requisites
RUN apt-get update \
        && apt-get -y install apt-utils locales

# Build environment
RUN apt-get install -y ca-certificates \
      && update-ca-certificates

# Unpack required packges to rootfs
RUN cd ${BUILD_DEBS} \
  && for pkg in $REQUIRED_PACKAGES; do \
       apt-get download $pkg \
         && apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances --no-pre-depends -i $pkg | grep '^[a-zA-Z0-9]' | xargs apt-get download ; \
     done
RUN if [ "x$(ls ${BUILD_DEBS}/)" = "x" ]; then \
      echo No required packages specified; \
    else \
      for pkg in ${BUILD_DEBS}/*.deb; do \
        echo Unpacking $pkg; \
        dpkg -x $pkg ${ROOTFS}; \
      done; \
    fi

# Fake user
RUN echo "root:x:0:0:root:/container_user_home:/bin/bash\nsshd:x:22:22:sshd privilege separation:/var/empty:/sbin/nologin" > ${ROOTFS}/etc/passwd2 \
    && echo "root:x:0:\nsshd:x:22:" > ${ROOTFS}/etc/group2

# Move /sbin out of the way
RUN mv ${ROOTFS}/sbin ${ROOTFS}/sbin.orig \
      && mkdir -p ${ROOTFS}/sbin \
      && for b in ${ROOTFS}/sbin.orig/*; do \
           echo 'cmd=$(basename ${BASH_SOURCE[0]}); exec /sbin.orig/$cmd "$@"' > ${ROOTFS}/sbin/$(basename $b); \
           chmod +x ${ROOTFS}/sbin/$(basename $b); \
         done

RUN mkdir -p ${ROOTFS}/run/sshd ${ROOTFS}/var/log ${ROOTFS}/var/empty && touch ${ROOTFS}/var/log/lastlog
COPY sshd_config ${ROOTFS}/etc/ssh/sshd_config2
COPY entrypoint.sh ${ROOTFS}/usr/local/bin/entrypoint.sh
RUN chmod +x ${ROOTFS}/usr/local/bin/entrypoint.sh

FROM actions/bash:5.0-2
LABEL maintainer = "ilja+docker@bobkevic.com"

ARG ROOTFS=/build/rootfs

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

COPY --from=build ${ROOTFS} /

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]