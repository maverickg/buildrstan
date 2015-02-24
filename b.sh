#!/bin/bash 
git clone https://github.com/rstan.git 
cd rstan
git submodule update --init --remote
cd rstan
make check
