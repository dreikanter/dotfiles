#!/usr/bin/env bash

brew install $(cat ./tools.txt | tr "\n" " ")
