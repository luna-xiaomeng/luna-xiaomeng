#!/bin/bash
crontab -l 2>/dev/null | sed 's|0 \*/6 \* \* \*|0 8 * * *|' | crontab -
crontab -l
