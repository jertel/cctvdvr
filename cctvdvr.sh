#!/bin/bash
# This CCTV DVR script requires an input configuration file specifying the required
# parameters for useful operation. See the below commented sample configuration file 
# to help get started quickly.
#
# -------------------------------------------------

#
## Storage directory where recordings and snapshots will be created.
#mediaDir=/media
#
## Camera username and password
# Specify host and name for each camera as follows.
#cameraHostToName["192.168.1.101"]=frontdoor
#cameraHostToName["192.168.1.102"]=driveway
#cameraRtspPort=554
#cameraUsername=admin
#cameraPassword=password
#
## Optional remote SCP location to store snapshots. Requires certificate-based 
## authentication.
#remoteDir=/snapshots
#remoteHost=
#remoteUser=cctvdvr
#remotePort=22
#remoteBandwidthMaxKb=1000
#
## Will prune recordings older than X days
#recordPruneAgeDays=45
#
## RTSP stream identification for each use-case. Typically 0 is high quality and 1 is lower quality.
#recordStream=0
#
## Snapshot JPG compression quality, higher number is worse, but smaller file size; 30 is fairly low quality but very small for low-bandwidth
#snapshotEnabled=0
#snapshotQuality=30
#snapshotIntervalSecs=4000
#snapshotStream=1

# Check input arguments
if [ $# -ne 1 ]; then
  configPath=$(dirname $0)/cctvdvr.conf
fi

# Read the input argument as a file to load the required paramters.
declare -A cameraHostToName
source $configPath

if [ -z "$mediaDir" ]; then 
  echo "Media directory must be specified; check path to configuration file."
  exit 3
fi

if [ ! -d "$mediaDir" ]; then 
  echo "Invalid media directory: $mediaDir"
  exit 2
fi

echo "Starting cctvdvr; mediaDir=${mediaDir}"

function prune() {
  pruneDir=$1
  [[ ! -d $pruneDir ]] && return
  #echo "Pruning; pruneDir=$pruneDir; recordPruneAgeDays=$recordPruneAgeDays"
  find $pruneDir -type f -mtime +${recordPruneAgeDays} -delete
}

function isSnapshotting() {
  ps -ef | grep -v grep | grep ffmpeg | grep $1 | grep jpg > /dev/null 2>&1 && echo "1"
}

function snapshot() {
  camHost=$1
  camName=$2
  camIndex=$3
  outputDir=$4

  [[ "${snapshotEnabled}" == "0" || "$(isSnapshotting $camHost)" == "1" ]] && return
  tmpdir="${outputDir}/snapshot"
  rtsp="rtsp://${camHost}:${cameraRtspPort}/user=${cameraUsername}&password=${cameraPassword}&channel=0&stream=${snapshotStream}.sdp?real_stream--rtp-caching=100"
  echo "Beginning to snapshot camera; host=${camHost}; name=${camName}; outputDir=${outputDir}"
  mkdir -p $tmpdir
  timeout -t 3630 -s KILL ffmpeg -v $verbosity \
    -rtsp_transport tcp \
    -t 01:00:00 \
    -i "${rtsp}" \
    -metadata title="${camName}" \
    -vf fps=1/${snapshotIntervalSecs} -q:v ${snapshotQuality} \
    -y -strftime 1 "${tmpdir}/${camIndex}_%Y%m%d_%H%M%S.jpg" &
}

function uploadSnapshots() {
  dir=$1

  [[ ! -d ${dir}/snapshot ]]  && return
  remote="${remoteUser}@${remoteHost}:${remoteDir}"

  cd "${dir}"/snapshot
  files=$(ls -A)
  if [ "$files" ]; then
    scp -l ${remoteBandwidthMaxKb} -B -o ConnectTimeout=3 -P ${remotePort} ${files} $remote
    rm -f $files
  fi
}

function isRecording() {
  ps -ef | grep -v grep | grep ffmpeg | grep $1 | grep avi > /dev/null 2>&1 && echo "1"
}

function recordCamera() {
  camHost=$1
  camName=$2
  outputDir=$3

  [[ "$(isRecording $camHost)" == "1" ]] && return
  tmpdir="${outputDir}/${camName}"
  rtsp="rtsp://${camHost}:${cameraRtspPort}/user=${cameraUsername}&password=${cameraPassword}&channel=0&stream=${recordStream}.sdp?real_stream--rtp-caching=100"
  mkdir -p $tmpdir
  echo "Beginning to record camera; host=${camHost}; name=${camName}; outputDir=${outputDir}"
  start=`date +%Y%m%d%H%M`
  timeout -t 3630 -s KILL ffmpeg -v $verbosity \
    -rtsp_transport tcp \
    -t 01:00:00 \
    -i "${rtsp}" \
    -metadata title="${camName}" \
    -y "${tmpdir}/${camName}_${start}.avi" &
}

function recordAll() {
  dir=$1

  idx=1
  for host in "${!cameraHostToName[@]}"; do
    name=${cameraHostToName[$host]}

    if [ ! -z "$host" ]; then
      recordCamera "$host" "$name" "$dir"
      snapshot "$host" "$name" "$idx" "$dir"
      let idx=idx+1
    fi
  done
}

counter=0
while [ true ]; do
  let counter=counter+1
  if [ $counter -eq 86400 ]; then
    prune $mediaDir
    counter=0
  fi
  recordAll $mediaDir
  uploadSnapshots $mediaDir
  sleep 1
done
