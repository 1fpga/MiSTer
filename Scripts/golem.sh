#!/bin/bash

if [ ! -f "/media/fat/MiSTer" ];
then
  echo "This script must be run"
  echo "on a MiSTer system."
  exit 1
fi

# Make sure the root filesystem is writable. We need to add libraries
# to /usr/lib.
mount | grep "on / .*[(,]ro[,$]" -q && RO_ROOT="true"
[ "$RO_ROOT" == "true" ] && mount / -o remount,rw

# Check the latest version of GoLEm being released.
LATEST_RELEASE=$(curl --insecure -Ls https://api.github.com/repos/golem-fpga/golem/releases/latest)
LATEST_VERSION=$(echo "$LATEST_RELEASE" | jq -r .tag_name)
echo Latest version of GoLEm: "$LATEST_VERSION"

# Check the version of GoLEm installed on the system.
INSTALLED_VERSION=$(cat /media/fat/golem/version.txt || echo "0.0.0")
echo Installed version of GoLEm: "$INSTALLED_VERSION"

if [ "$LATEST_VERSION" != "$INSTALLED_VERSION" ];
then
  echo "GoLEm is old, let's upgrade it."
  # Download the latest version of GoLEm.
  RELEASE_URL=$(echo "$LATEST_RELEASE" | jq -r '.assets[] | select(.name=="release.zip") | .browser_download_url')

  # Download the release.
  curl --insecure -L "$RELEASE_URL" -o /tmp/release.zip

  # Extract the release.
  mkdir -p /media/fat/golem
  unzip -o /tmp/release.zip -d /media/fat/golem
  mv -n /media/fat/golem/lib/* /usr/lib/
  rm -rf /media/fat/golem/lib

  # Update the version file.
  echo "$LATEST_VERSION" > /media/fat/golem/version.txt
fi

[ "$RO_ROOT" == "true" ] && mount / -o remount,ro

echo "GoLEm is up to date."
echo "Starting GoLEm"

# Start GoLEm.
killall -9 MiSTer
/media/fat/golem/GoLEm_firmware

# Once this is done, reboot back into MiSTer.
reboot
