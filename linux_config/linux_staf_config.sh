#!/bin/bash

# Change Domain and DNS if NEEDED.

# Network Checker
function networkCheck() {
        wget -q --tries=10 --timeout=20 --spider http://www.google.com
        if [[ $? -eq 0 ]]; then
                echo "Network connection working fine..."
        else
                echo "Maybe, You need configurate proxy settings..."
                exit 2
        fi
}

# Restart this PC
# If there is no error occurred, this function will be invoked.
function restart() {
        sudo shutdown -r now
}

# Safe exit
function safeExit() {
        # umount the share folder
        sudo umount $mntFolder
        exit 1
}

# Trap user interrupt
trap '{ echo "You stop this intallation process"; safeExit; }' INT

# This function for software installation via apt-get
function installSoftwares() {
        sudo apt-get update
        sudo apt-get install -y nfs-common
        sudo apt-get install -y cifs-utils
        sudo apt-get upgrade -y
        installLangPkgs
        echo "Clean..."
        sudo apt-get autoremove -y
        sudo apt-get autoclean -y
}

# This function for language packages installation
function installLangPkgs() {
        sudo apt-get install -y `check-language-support -l fr`
        sudo apt-get install -y `check-language-support -l de`
        sudo apt-get install -y `check-language-support -l jp`
        sudo apt-get install -y `check-language-support -l ko`
        sudo apt-get install -y `check-language-support -l en`
        sudo apt-get install -y `check-language-support -l zh`
}

function enableAutoLogin() {
        echo "Enable auto login..."
        sudo cp -f $mntFolder/lightdm.conf /etc/lightdm/lightdm.conf
}

# This function for STAF installation.
function installSTAF() {
        # Copy the STAF installer
        if [ -d ~/tmp ]; then
                sudo rm -rf ~/tmp
        fi
        mkdir -p ~/tmp
        echo "Copy STAF installer..."
        cp -f $mntFolder/STAF3420-setup-linux.bin ~/tmp

        echo "Install STAF in silent mode..."
        sudo ~/tmp/STAF3420-setup-linux.bin -i silent -DACCEPT_LICENSE=1

        echo "Check STAF installation..."
        # Change ownership to current user and root for /usr/local/staf
        if [ -d /usr/local/staf ]; then
                sudo chown -R $USER:$USER /usr/local/staf
        else
                echo "STAF install failed..."
                safeExit
        fi
        echo "Update STAF.cfg..."
        if [ -e /usr/local/staf/bin/STAF.cfg ]; then
                sudo echo "trust machine *://* level 5" >> /usr/local/staf/bin/STAF.cfg
        else
                echo "STAF install failed..."
                safeExit
        fi
        # A little change for startSTAFProc.sh
        sudo cp -f $mntFolder/startSTAFProc.sh /usr/local/staf/startSTAFProc.sh
}

# Add STAF to startup application list.
function addSTAFToStartupList() {
        if [ -d ~/.config/autostart ]; then
                echo "Directory autostart exists..."
        else
                mkdir -p ~/.config/autostart
        fi
        echo "[Desktop Entry]" > ~/.config/autostart/startSTAFProc.sh.desktop
        echo "Type=Application" >> ~/.config/autostart/startSTAFProc.sh.desktop
        echo "Exec=xterm -e "/usr/local/staf/startSTAFProc.sh"" >> ~/.config/autostart/startSTAFProc.sh.desktop
        echo "Hidden=false" >> ~/.config/autostart/startSTAFProc.sh.desktop
        echo "NoDisplay=false" >> ~/.config/autostart/startSTAFProc.sh.desktop
        echo "X-GNOME-Autostart-enabled=true" >> ~/.config/autostart/startSTAFProc.sh.desktop
        echo "Name[en_US]=STAFProc" >> ~/.config/autostart/startSTAFProc.sh.desktop
        echo "Name=STAF" >> ~/.config/autostart/startSTAFProc.sh.desktop
        echo "Comment[en_US]=" >> ~/.config/autostart/startSTAFProc.sh.desktop
        echo "Comment=" >> ~/.config/autostart/startSTAFProc.sh.desktop
}

# Add Jenkins to startup application list.
function addJenkinsToStartupList() {
        echo "[Desktop Entry]" > ~/.config/autostart/jenkins.desktop
        echo "Type=Application" >> ~/.config/autostart/jenkins.desktop
        echo "Exec=xterm -e "/jenkins/runJenkins.sh"" >> ~/.config/autostart/jenkins.desktop
        echo "Hidden=false" >> ~/.config/autostart/jenkins.desktop
        echo "NoDisplay=false" >> ~/.config/autostart/jenkins.desktop
        echo "X-GNOME-Autostart-enabled=true" >> ~/.config/autostart/jenkins.desktop
        echo "Name[en_US]=Jenkins" >> ~/.config/autostart/jenkins.desktop
        echo "Name=Jenkins" >> ~/.config/autostart/jenkins.desktop
        echo "Comment[en_US]=" >> ~/.config/autostart/jenkins.desktop
        echo "Comment=" >> ~/.config/autostart/jenkins.desktop
        echo "Please add jenkins startup process in /jenkins/runJenkins.sh"
}

# Mount share folder
mkdir -p $mntFolder; sudo mount $shareFolder $mntFolder -o user=administrator,password=vmware
# Install STAF
echo "Install STAF..."
if hash staf 2>/dev/null; then
        echo "STAF has been installed already..."
else
        installSTAF
fi

echo "Add STAF to startup application list..."
addSTAFToStartupList

echo "Add Jenkins to startup appliaction list..."
addJenkinsToStartupList

echo "Install additional software..."
installSoftwares

# Restart this PC.
read -p "Restart? [Y/N]: " response
if [[ $response =~ ^([Yy][eE][sS]|[yY])$ ]]
then
        restart
else
        echo "Restart current desktop before testing..."
        safeExit
fi
