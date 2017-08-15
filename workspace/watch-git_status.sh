#!/bin/bash

# Displays the status of the CWD with color.
#
# Helpful when tabbing around.
watch -n 0.5 --color git -c color.status=always status
