#!/bin/bash
#
#  Filename: _helper.sh
#  Author: peihua@miniasp.com
#  Date: 2020/7/30
#
#  Usage: Define how output are displayed
#

# -------------- Helper Functions -------------- #

NC='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;36m'

ERROR_PREFIX="[${RED}ERROR${NC}]"
INFO_PREFIX="[INFO]"
OK_PREFIX="[${GREEN}OK${NC}]"

CURRENT_SECTION=init

function start_section() { 
  echo -e "$INFO_PREFIX ${1}: Started" 
  CURRENT_SECTION="$1"
}

function end_section() {
  echo -e "$INFO_PREFIX ${1}: Completed"
  sleep 1
  CURRENT_SECTION=""
}

function err() {
  echo -e "$ERROR_PREFIX ${CURRENT_SECTION}: $1" >&2
  exit 1
}

function ok() {
  echo -e "$GOOD_PREFIX ${1}" 
}
