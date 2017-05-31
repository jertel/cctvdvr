FROM alpine:latest
LABEL Vendor="Codesim, LLC"
LABEL License=GPLv2
LABEL Description="FFMPEG-based CCTV DVR using RTSP. Includes snapshots with remote upload for additional redundancy. Requires the following mount points: 1) /cctvdvr/cctvdvr.conf - The config file, see cctvdvr.sh comments for more sample variables, 2) /cctvdvr/media - The media directory for storing recordings and snapshots, and (if using remote snapshot backups) 3) /cctvdvr/.ssh - The SSH directory containing private keys and known_hosts files."

# Set the locale
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apk update 
RUN apk add openssh ffmpeg bash

RUN mkdir -p /cctvdvr
COPY ./cctvdvr.sh /cctvdvr/
RUN chmod +x /cctvdvr/cctvdvr.sh

RUN adduser -h /cctvdvr -u 3001 -D cctvdvr

USER cctvdvr

ENTRYPOINT /cctvdvr/cctvdvr.sh