#!/bin/bash 
## post building, not important
cd ~/buildrstan
git submodule deinit --force .
sudo swapoff ~/.swapfile
exit 0

