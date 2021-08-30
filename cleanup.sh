#!/bin/bash
set -euo pipefail

for mount in $(mount | grep Stream | cut -d ' ' -f 3); do sudo umount "$mount"; done
for loc in $(find /tmp -name .discinfo 2>/dev/null); do sudo rm -rf "$(dirname "$loc")"; done
