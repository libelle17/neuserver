U=Vorlagen;Q=/opt/turbomed;ZV=$Q/$U;C=/root/pCloudDrive/$U;rm -rf "$C/*" > /dev/null;rm -rf "$C/*" > /dev/null;find "$ZV" -type d -exec sh -c 'BN="{}";BN=${BN##'$ZV'};mkdir -p '$C'/"$BN";' \;; find "$ZV" -type f -exec sh -c 'BN="{}";BN=${BN##'$ZV'}; gpg --batch --yes -e -r Gerald -o '$C'"$BN" '$ZV'"$BN"' \;