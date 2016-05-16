#!/bin/bash
###################################################################################
#  file: post-installation.sh
# autor: frep
#  desc: Sets up a raspberry pi 3 based on the raspbian distribution
#        Important: dont run script as superuser, just "./setup.sh"
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
	cd ~/.config/
	if [ ! -d autostart ]; then
		mkdir autostart
	fi
        cp -f ${setupdir}/vnc/x11vnc.desktop ~/.config/autostart/
}

function finderScreenSharing {
	sudo apt-get install netatalk -y
	sudo cp -f ${setupdir}/vnc/rfb.service /etc/avahi/services/
	sudo cp -f ${setupdir}/vnc/afpd.service /etc/avahi/services/
}

function installChromium {
	wget -qO - http://bintray.com/user/downloadSubjectPublicKey?username=bintray | sudo apt-key add -
	echo "deb http://dl.bintray.com/kusti8/chromium-rpi jessie main" | sudo tee -a /etc/apt/sources.list
	sudo apt-get update
	sudo apt-get install chromium-browser rpi-youtube -y
}

function installROS {
	# setup ROS repositories
	sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu jessie main" > /etc/apt/sources.list.d/ros-latest.list'
	wget https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -O - | sudo apt-key add -
	sudo apt-get update
	sudo apt-get upgrade -y
	# install bootstrap dependencies
	sudo apt-get install python-pip python-setuptools python-yaml python-distribute python-docutils python-dateutil python-six -y
	sudo pip install rosdep rosinstall_generator wstool rosinstall
	# initializing rosdep
	sudo rosdep init
	rosdep update
	# installation
	mkdir ~/ros_catkin_ws
	cd ~/ros_catkin_ws
	rosinstall_generator ros_comm --rosdistro indigo --deps --wet-only --exclude roslisp --tar > indigo-ros_comm-wet.rosinstall
	wstool init src indigo-ros_comm-wet.rosinstall
	# resolving dependencies
	cd ~/ros_catkin_ws
	rosdep install --from-paths src --ignore-src --rosdistro indigo -y -r --os=debian:jessie
	# building workspace
	cd ~/ros_catkin_ws
	sudo ./src/catkin/bin/catkin_make_isolated --install -DCMAKE_BUILD_TYPE=Release --install-space /opt/ros/indigo
	# source setup.bash
	echo "" >> ~/.bashrc
	echo "source /opt/ros/indigo/setup.bash" >> ~/.bashrc
}

function addReleasedROSPackage {
	cd ~/ros_catkin_ws
	rosinstall_generator $1 --rosdistro indigo --deps --wet-only --exclude roslisp --tar > indigo-custom_ros.rosinstall
	wstool merge -t src indigo-custom_ros.rosinstall
	wstool update -t src
	rosdep install --from-paths src --ignore-src --rosdistro indigo -y -r --os=debian:jessie
	sudo ./src/catkin/bin/catkin_make_isolated --install -DCMAKE_BUILD_TYPE=Release --install-space /opt/ros/indigo
}

function installArduino {
	cd
	git clone https://github.com/NicoHood/Arduino-IDE-for-Raspberry.git
	cd Arduino-IDE-for-Raspberry
	tar xvfJ arduino-1.6.8-rc1-arm.tar.xz
	cd arduino-1.6.8
	./install.sh
}

###################################################################################
# program
###################################################################################

#installVncServer
#finderScreenSharing
#installChromium
#installROS
#addReleasedROSPackage ros_tutorials
#addReleasedROSPackage ps3joy
installArduino
#sudo apt-get autoremove -y
#sudo reboot

# unverified:
# ===========
#installConky
#startConkyAtStartx


###################################################################################
# unscripted modifications:
###################################################################################

# /boot/config.txt:
# =================
# hdmi_force_hotplug=1
# hdmi_group=2
# hdmi_mode=73

# /etc/dphys-swapfile:
# ====================
# CONF_SWAPSIZE=1024
