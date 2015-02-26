#!/bin/bash 

mkdir -p ~/rlib
export  R_LIBS="~/rlib"

STAN_REPO_BRANCH=`git rev-parse --abbrev-ref HEAD`
STAN_REPO_BRANCH=develop
RSTAN_REPO_BRANCH=feature/travis_trial_n_error
RSTAN_REPO_BRANCH=debug/test_grad_crash

grepstanbranch=`git ls-remote --heads https://github.com/stan-dev/stan.git | grep "/${STAN_REPO_BRANCH}"`
if [ -z "$grepstanbranch" ]; then
    STAN_REPO_BRANCH=master
fi

greprstanbranch=`git ls-remote --heads https://github.com/stan-dev/rstan.git | grep "/${RSTAN_REPO_BRANCH}"`
if [ -z "$greprstanbranch" ]; then
    RSTAN_REPO_BRANCH=develop
fi

dd if=/dev/zero of=~/.swapfile bs=2048 count=1M
mkswap ~/.swapfile
sudo swapon ~/.swapfile


git config -f .gitmodules submodule.rstan.branch ${RSTAN_REPO_BRANCH}
git submodule update --init --remote
git submodule status

cd rstan
git config -f .gitmodules submodule.stan.branch ${STAN_REPO_BRANCH}
git submodule update --init --remote --recursive
git submodule status
sudo apt-get -qq update
sudo apt-get -qq -y install r-base-core qpdf texlive-latex-base texlive-base  xzdec texinfo ccache

mkdir -p ~/.R/
echo "CXX = ccache `R CMD config CXX`" > ~/.R/Makevars
more ~/.R/Makevars
echo "_R_CHECK_FORCE_SUGGESTS_=FALSE" > ~/.R/check.Renviron

sudo tlmgr init-usertree
sudo tlmgr update --self 
sudo tlmgr install inconsolata upquote courier courier-scaled helvetic \
                   verbatimbox readarray ifnextok multirow fancyvrb url \
                   titlesec booktabs tex4ht
# font 
sudo tlmgr install ec times

R CMD build StanHeaders/

stanheadtargz=`find StanHeaders*.tar.gz`

lookforverfile=`tar tf ${stanheadtargz} | grep stan/version.hpp`

if [ -z "$lookforverfile" ]; then
    echo "stan/version.hpp is not found in StanHeaders pkg"
    exit 2
fi

R CMD INSTALL ${stanheadtargz}

R -q -e "options(repos=structure(c(CRAN = 'http://cran.rstudio.com'))); for (pkg in c('inline', 'Rcpp', 'RcppEigen', 'RUnit', 'BH', 'RInside')) if (!require(pkg, character.only = TRUE))  install.packages(pkg, dep = TRUE); sessionInfo()"


cd rstan
echo "CXX = `R CMD config CXX`" >> R_Makevars # ccache is set in ~/.R/Makevars
more R_Makevars
bash ~/buildrstan/wait4.sh "make check"
bash ~/buildrstan/wait4.sh "make test-cpp"
