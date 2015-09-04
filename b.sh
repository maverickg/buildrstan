#!/bin/bash 

mkdir -p ~/rlib
export  R_LIBS="~/rlib"

STAN_REPO_BRANCH=`git rev-parse --abbrev-ref HEAD`
STAN_REPO_BRANCH=develop
STAN_REPO_BRANCH=`git rev-parse --abbrev-ref HEAD`
RSTAN_REPO_BRANCH=develop
STAN_MATH_REPO_BRANCH=develop

grepstanbranch=`git ls-remote --heads https://github.com/stan-dev/stan.git | grep "/${STAN_REPO_BRANCH}"`
if [ -z "$grepstanbranch" ]; then
    STAN_REPO_BRANCH=master
fi

greprstanbranch=`git ls-remote --heads https://github.com/stan-dev/rstan.git | grep "/${RSTAN_REPO_BRANCH}"`
if [ -z "$greprstanbranch" ]; then
    RSTAN_REPO_BRANCH=develop
fi

grepmathbranch=`git ls-remote --heads https://github.com/stan-dev/math.git | grep "/${STAN_MATH_REPO_BRANCH}"`
if [ -z "$grepmathbranch" ]; then
    STAN_MATH_REPO_BRANCH=develop
fi

dd if=/dev/zero of=~/.swapfile bs=2048 count=1M
mkswap ~/.swapfile
sudo swapon ~/.swapfile

git submodule --quiet update --init --recursive

git config -f .gitmodules submodule.rstan.branch ${RSTAN_REPO_BRANCH}
git submodule --quiet update --remote
git submodule status

cd rstan
git submodule --quiet update --init --recursive
git config -f .gitmodules submodule.stan.branch ${STAN_REPO_BRANCH}
git config -f .gitmodules submodule.StanHeaders/inst/include/mathlib.branch ${STAN_MATH_REPO_BRANCH}
git submodule --quiet update --remote
git submodule status
ls -alh StanHeaders/inst/include/mathlib
ls -alh StanHeaders/inst/include 

mkdir -p "${SEMAPHORE_CACHE_DIR}/.ccahe"
export CCACHE_DIR="${SEMAPHORE_CACHE_DIR}/.ccahe"

sudo add-apt-repository "deb http://cran.rstudio.com/bin/linux/ubuntu $(lsb_release -cs)/"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
sudo add-apt-repository -y "ppa:marutter/rrutter"
sudo add-apt-repository -y "ppa:marutter/c2d4u"

sudo apt-get -qq update
sudo apt-get -qq -y install r-base-core qpdf texlive-latex-base texlive-base  xzdec texinfo ccache tex4ht texlive-fonts-extra r-cran-rcurl
sudo tlmgr init-usertree
sudo tlmgr update --self 
sudo tlmgr install upquote courier courier-scaled helvetic \
                   verbatimbox readarray ifnextok multirow fancyvrb url \
                   titlesec booktabs

mkdir -p ~/.R/
echo "CXX = ccache `R CMD config CXX`" > ~/.R/Makevars
more ~/.R/Makevars
echo "_R_CHECK_FORCE_SUGGESTS_=FALSE" > ~/.R/check.Renviron

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

R -q -e "options(repos=structure(c(CRAN = 'http://cran.rstudio.com'))); for (pkg in c('inline', 'Rcpp', 'RcppEigen', 'ggplot2',  'gridExtra', 'RUnit', 'BH', 'RInside', 'coda')) if (!require(pkg, character.only = TRUE))  install.packages(pkg, dep = TRUE); sessionInfo()"

cd rstan
echo "CXX = `R CMD config CXX`" >> R_Makevars # ccache is set in ~/.R/Makevars
more R_Makevars
bash ~/buildrstan/wait4.sh "make install"
bash ~/buildrstan/wait4.sh "make check"

