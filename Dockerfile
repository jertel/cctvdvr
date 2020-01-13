FROM debian:latest
LABEL Vendor="Codesim, LLC"
LABEL License=GPLv2
LABEL Description="FFMPEG-based CCTV DVR using RTSP. Includes snapshots with remote upload for additional redundancy. Requires the following mount points: 1) /cctvdvr/cctvdvr.conf - The config file, see cctvdvr.sh comments for more sample variables, 2) /cctvdvr/media - The media directory for storing recordings and snapshots, and (if using remote snapshot backups) 3) /cctvdvr/.ssh - The SSH directory containing private keys and known_hosts files."

RUN apt update
RUN apt -y install openssh-client ffmpeg bash procps

RUN mkdir -p /cctvdvr
COPY ./cctvdvr.sh /cctvdvr/
RUN chmod +x /cctvdvr/cctvdvr.sh

RUN adduser -q --system --home /cctvdvr -uid 3001 --no-create-home --disabled-password cctvdvr

USER cctvdvr

ENTRYPOINT /cctvdvr/cctvdvr.sh
