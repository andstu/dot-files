#!/bin/zsh

for i in $(ls -d */); do stow ${i%%/}; done

