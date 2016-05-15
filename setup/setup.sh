#!/bin/bash
###################################################################################
#  file: post-installation.sh
# autor: frep
#  desc: Setup the raspberry pi 3 based on the raspbian distribution
###################################################################################
# paths and variables
###################################################################################

setupdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


###################################################################################
# functions
###################################################################################

function assertLaunchStartxScriptExists {
	if [ ! -f ~/launchAtStartx.sh ]; then
    		# script does not exist yet. Create it!
    		cp ${setupdir}/system/launchAtStartx.sh ~/
  	fi
  	if [ ! -f ~/.config/autostart/launchAtStartx.desktop ]; then
		if [ ! -d ~/.config/autostart ]; then
			mkdir ~/.config/autostart
		fi
    		# launchAtStartx.desktop does not exist yet. Create it!
    		cp -f ${setupdir}/system/launchAtStartx.desktop ~/.config/autostart/
  	fi
}

function installConky {
	sudo apt-get install conky -y
	cd
	if [ ! -d .conky ]; then
		mkdir .conky
	fi
	cp ${setupdir}/conky/.conkyrc .conky/
	cp ${setupdir}/conky/conkyTemp.py .conky/
}

function startConkyAtStartx {
	assertLaunchStartxScriptExists
	cat ~/launchAtStartx.sh | sed '/^exit 0/d' > tmpFile
	echo "# CONKY" >> tmpFile
	echo "killall conky" >> tmpFile
	echo "sleep 5" >> tmpFile
	echo "conky --config=.conky/.conkyrc -d &" >> tmpFile
	echo "" >> tmpFile
	echo "exit 0" >> tmpFile
	sudo mv tmpFile ~/launchAtStartx.sh
	sudo chmod +x ~/launchAtStartx.sh
}

function installVncServer {
	sudo apt-get install x11vnc -y
	x11vnc -storepasswd
	#assertLaunchStartxScriptExists
        cp -f ${setupdir}/vnc/x11vnc.desktop ~/.config/autostart/
}

function finderScreenSharing {
	sudo apt-get install netatalk -y
	sudo cp -f ${setupdir}/vnc/rfb.service /etc/avahi/services/
}

function installChromium {
	# todo
}

###################################################################################
# program
###################################################################################

#installConky
#startConkyAtStartx
#installVncServer
#finderScreenSharing
installChromium
#sudo apt-get autoremove -y
#sudo reboot
