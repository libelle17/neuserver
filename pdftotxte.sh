#/bin/bash
for A in *.pdf; do pdftotext "$A"; touch -r "$A" "${A//pdf/txt}"; done
