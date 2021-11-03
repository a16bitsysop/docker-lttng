FROM alpine:edge as build-base

ENV NME builder
ENV FULL "builder builder"
ENV EMAIL "build@build"

RUN apk add --no-cache -u alpine-sdk pax-utils atools git sudo gdb findutils

# setup build user
RUN adduser -D ${NME} && addgroup ${NME} abuild && addgroup ${NME} tty \
&& mkdir -p /var/cache/distfiles \
&& chgrp abuild /var/cache/distfiles \
&& chmod g+w /var/cache/distfiles

RUN echo "Defaults  lecture=\"never\"" > /etc/sudoers.d/${NME} \
&& echo "${NME} ALL=NOPASSWD : ALL" >> /etc/sudoers.d/${NME}

RUN  su ${NME} -c "abuild-keygen -a -i -n"
RUN echo "PACKAGER=\"${FULL} <${EMAIL}>\"" >> /etc/abuild.conf \
&& echo 'MAINTAINER="$PACKAGER"' >> /etc/abuild.conf \
&& sed "s/ERROR_CLEANUP.*/ERROR_CLEANUP=\"bldroot\"/" -i /etc/abuild.conf

FROM build-base as build-ust

ENV NME builder

COPY just-build.sh /usr/local/bin/

WORKDIR /tmp
COPY lttng-ust ./

RUN just-build.sh

FROM build-base as build-tools

ENV NME builder

COPY just-build.sh /usr/local/bin/
COPY --from=build-ust /tmp/packages/* /tmp/packages/
RUN ls -lah /tmp/packages

RUN echo /tmp/packages >> /etc/apk/repositories

WORKDIR /tmp
COPY lttng-tools ./

RUN just-build.sh
