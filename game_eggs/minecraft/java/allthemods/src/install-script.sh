#!/bin/bash
# Forge Installation Script
#
# Server Files: /mnt/server
apt update
apt install -y curl jq

if [[ ! -d /mnt/server ]]; then
  mkdir /mnt/server
fi

cd /mnt/server || exit 1

echo "$(cat <<-END
# import: startserver.sh
END
)" > "startserver.sh"
chmod +x "startserver.sh"
echo "$(cat <<-END
# import: server-setup-config.yaml
END
)" > "server-setup-config.temp.yaml"