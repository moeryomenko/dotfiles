#!/usr/bin/bash

grim -g "$(slurp)" -t jpeg -q 100 ~/pictures/screenshots/$(date +'%Y-%m-%d-%H%M%S_grim.jpeg')
