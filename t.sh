#!/bin/bash 

export  R_LIBS="~/rlib"
cd ~/buildrstan/rstan/rstan/tests
if [ -d "../rstan.Rcheck" ]; then
  R -q -e "if (!require('rstan', character.only = TRUE)) stop('rstan pkg not found')" \
  && R -q -f runRunitTests.R --args ../rstan.Rcheck
else
  exit 2
fi 
exit $!

