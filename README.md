# Flatexporter

Simple shell script for exporting flatex depot contents as CSV. Flatex doesn't provide a proper public API at this time, so this uses the same authentication flow as their web interface.

Usage: ./flatexporter.sh username password

Requires curl and jq.
