#!/bin/bash
sudo apt-get update
sudo apt-get install ruby-full ruby1.9.1-full

sudo update-alternatives --remove-all gem
sudo update-alternatives --remove-all ruby

(cd /tmp && et http://jruby.org.s3.amazonaws.com/downloads/1.5.1/jruby-bin-1.5.1.tar.gz)

#sudo (cd /usr/local && tar xvzf /tmp/jruby-bin-1.5.1.tar.gz)

#sudo update-alternatives --install /usr/local/bin/jruby jruby /usr/local/jruby-1.5.1/bin/jruby 100 --slave /usr/local/bin/jgem jgem /usr/local/jruby-1.5.1/bin/jgem --slave /usr/local/bin/jirb jirb /usr/local/jruby-1.5.1/bin/jirb --slave /usr/local/bin/jrubyc jrubyc /usr/local/jruby-1.5.1/bin/jrubyc

sudo update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby1.8 100 --slave /usr/bin/irb irb /usr/bin/irb1.8 --slave /usr/bin/gem gem /usr/bin/gem1.8 --slave /usr/bin/ri ri /usr/bin/ri1.8

sudo update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby1.9.1 50 --slave /usr/bin/irb irb /usr/bin/irb1.9.1 --slave /usr/bin/gem gem /usr/bin/gem1.9.1 --slave /usr/bin/ri ri /usr/bin/ri1.9.1

sudo update-alternatives --install /usr/bin/ruby ruby /usr/local/bin/jruby 40 --slave /usr/bin/irb irb /usr/local/bin/jirb --slave /usr/bin/gem gem /usr/local/bin/jgem

