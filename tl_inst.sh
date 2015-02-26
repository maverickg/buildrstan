#!/bin/bash 

wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
tar zxvf install-tl-unx.tar.gz
cd install-tl-20*
./install-tl --profile=tl_inst_profile.txt
cd ..
export PATH=$SEMAPHORE_CACHE_DIR/texlive/2014/bin/x86_64-linux:$PATH
tlmgr update --self
tlmgr install inconsolata upquote courier courier-scaled helvetic \
                   verbatimbox readarray ifnextok multirow fancyvrb url \
                   titlesec booktabs tex4ht  ec times
