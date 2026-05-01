#!/bin/bash
STATE="${1:-completed}"

if [ -n "$ZELLIJ" ]; then
  zellij pipe --name "zellij-attention::${STATE}::${ZELLIJ_PANE_ID}"
fi
