#!/bin/sh
# Sets up the STAF environment variables and starts STAFProc 
# in the background, logging STAFProc output to nohup.out
. /usr/local/staf/STAFEnv.sh
/usr/local/staf/bin/STAFProc
