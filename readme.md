Simple CCTV DVR
===============

Simple FFMPEG-based DVR for capturing CCTV recordings over RTSP. Supports remote backup of snapshots.

Requirements
============

1. Cameras must support RTSP. Most of the economy grade cameras available from China support this protocol.
2. For remote snapshot backups, SSH certificate-based login must be working (known_hosts must be populated.)
3. A relatively large media directory for holding the recordings must be available. 
4. Configuration file based on the variables defined in the comment section of the cctvdvr.sh must be provided.

