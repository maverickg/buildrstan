#!/bin/bash 

cd ~/buildrstan/rstan/rstan/tests
if [ -d "../rstan.Rcheck" ]; then
  R -q -f runRunitTests.R --args ../rstan.Rcheck
fi 

