#!/bin/bash 

dd if=/dev/zero of=.swapfile bs=2048 count=1M
mkswap .swapfile
sudo swapon .swapfile

cd rstan
git submodule update --init --remote --recursive
sudo apt-get -qq update
sudo apt-get -qq -y install r-base-core \
  devscripts gfortran-multilib gfortran-doc gfortran-4.8-multilib \
  gfortran-4.8-doc libgfortran3-dbg libdigest-hmac-perl libgssapi-perl \
  libdata-dump-perl libcrypt-ssleay-perl ncurses-doc libauthen-ntlm-perl \
  python-rsvg python-cairo ess r-doc-info r-doc-pdf r-mathlib r-base-html \
  texlive-base texlive-latex-base texlive-generic-recommended \
  texlive-fonts-recommended texlive-fonts-extra texlive-extra-utils \
  texlive-latex-recommended texlive-latex-extra texinfo texi2html \
  build-essential \
  tcl-tclreadline \
  ccache

R CMD build StanHeaders/

stanheadtargz=`find StanHeaders*.tar.gz`

lookforverfile=`tar tf ${stanheadtargz} | grep stan/version.hpp`

if [ -z "$lookforverfile" ]; then
    echo "stan/version.hpp is not found in StanHeaders pkg"
    exit 2
fi

R CMD INSTALL ${stanheadtargz}

mkdir -p ~/rlib
cp Rprofile ~/.Rprofile
R -q -e "options(repos=structure(c(CRAN = 'http://cran.rstudio.com'))); for (pkg in c('inline', 'Rcpp', 'RcppEigen', 'RUnit', 'BH', 'RInside')) if (!require(pkg, character.only = TRUE))  install.packages(pkg, dep = TRUE); sessionInfo()"

mkdir -p ~/.R/
echo "CXX = ccache `R CMD config CXX`" > ~/.R/Makevars
more ~/.R/Makevars

cd rstan
make check

cd tests
R -q -f runRunitTests.R --args ../rstan.Rcheck

