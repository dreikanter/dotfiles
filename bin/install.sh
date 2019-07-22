#!/usr/bin/env bash

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

find $SCRIPTPATH/install-*.sh -type f -exec bash {} \;
