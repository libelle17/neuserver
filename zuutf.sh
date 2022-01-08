#!/bin/bash
find /DATA/Patientendokumente -maxdepth 1 -type f -print0|while IFS= read -r -d '' file; do mv "$file" "$(echo $file|sed 'y/\xb4\xfc\xc3/\x20ü./')" 2>/dev/null; done;
