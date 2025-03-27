#!/bin/sh
if [ -f /donate.txt ]; then cat /donate.txt; fi

# Execute the main application
exec pwsh -File /Start.ps1 "$@"