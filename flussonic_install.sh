#!/bin/bash

cur_date=`date`
var1=`cat /etc/profile | grep -w HISTSIZE`
ret=`echo $?`
me=$(basename "$0")
current_dir=`pwd`

if [ "$ret" == 1 ]; then
        sudo bash -c "echo '# $cur_date' >> /etc/profile"
        echo -e "\n"
        sudo bash -c "echo 'HISTSIZE=2000' >> /etc/profile"
        sudo bash -c "echo 'HISTTIMEFORMAT='%F %T '' >> /etc/profile"
        echo -e " ... updated profile in etc on $cur_date  ... \n"
else
        echo -e " ... profile is already updated .... \n"
fi

#---------------------------------------------------
server_ip=`curl -s ipinfo.io/ip`
echo -e "\n************ Server IP: $server_ip **********\n"
echo -e "\nUpdating....\n"
sudo apt update
sudo apt install net-tools unzip wget -y

echo -e "\n updates are done...."

if [ ! -d /tmp/fsonicauto ]; then
        echo -e "\ncreating temp dir and downloading software files...\n"
        mkdir -p /tmp/fsonicauto
        
        # Download from GitHub raw URL
        echo -e "Downloading from GitHub...\n"
        sudo wget https://github.com/XtechGlobal-Server/flussonic/raw/main/23.02.zip -O /tmp/fsonicauto/23.02_new_file.zip
        
        # Check if download was successful
        if [ ! -f /tmp/fsonicauto/23.02_new_file.zip ]; then
            echo -e "ERROR: Download failed! Please check the GitHub URL.\n"
            exit 1
        fi
        
        echo -e "Unzipping downloaded file...\n"
        cd /tmp/fsonicauto; sudo unzip -o 23.02_new_file.zip
        
        echo -e "\nChecking contents of downloaded directory...\n"
        ls -la /tmp/fsonicauto/
        
        # Check if unzip created a specific directory
        if [ -d "/tmp/fsonicauto/23.02_new_file" ]; then
            cd /tmp/fsonicauto/23.02_new_file
            echo -e "\nContents of 23.02_new_file directory:\n"
            ls -la
        fi
        
        echo -e "\n checking software installation status ..\n"
        sudo dpkg -l | grep ^ii | grep flussonic > /dev/null
        ret=`echo $?`
        if [ "$ret" == 1 ]; then
                echo -e '\n... software unpacked. Installing software..';
                
                # Find and install all .deb files recursively
                echo -e "\nFinding and installing .deb packages...\n"
                find /tmp/fsonicauto -name "*.deb" -type f | while read deb_file; do
                    echo "Installing: $deb_file"
                    sudo dpkg -i "$deb_file" || true
                done
                
                # Fix dependencies
                sudo apt-get install -f -y

                echo -e "\n ... Installation done ...\n"
                echo -e "\n activating flussonic service \n"
                
                sudo systemctl enable flussonic
                sudo systemctl start flussonic
                
                lic="o4|000000000000000000000|NulledBySlaSerXDEV"
                password=$(tr -dc 'A-Za-z0-9!?%=' < /dev/urandom | head -c 10)
                echo -e "\n ... Please open ** http://$server_ip ** in browser and add following information.
                License Key: "$lic"
                Login: admin_noc
                Password: $password \n
                Click: Activate Media Server

                Once you are logged in to the server, navigate to config, scroll down to the end of the page, press Upload Config

                After uploading configuration using web URL, You need to login to server using the credentials mentioned in your backup configuration file.
                \n"

                sudo rm -f /etc/apt/sources.list.d/flussonic.list
                sudo rm -f /etc/apt/sources.list.d/erlyvideo.list

                echo -e "\n ... list files are removed to avoid updates ..."
        else
                echo -e "\n ... Flussonic is already installed ...";
        fi
        echo ""
        exit 0
else
        echo -e "\nTemp folder already exists\n"
        if [ -f /tmp/fsonicauto/23.02_new_file.zip ]; then
                echo -e "\nsoftware file exists. Cleaning up and restarting...\n"
                sudo rm -rf /tmp/fsonicauto
                exec sudo ./$0
        else
                echo -e "temp folder exists but no software .zip\n"
                sudo rm -rf /tmp/fsonicauto
                exec sudo ./$0
        fi
fi
