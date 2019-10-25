#! /bin/bash

# sudo apt-get install -y openssh-server
# chmod +x ./Xpi.sh

clear

## Global parameters
v_HEIGHT=35
v_WIDTH=75
v_INIFILE="Xpi.ini"
v_RCPASSWORD=pi\!2019
v_LOGFILE="./$0.log"
v_LOGLEVEL=2
v_VERBOSE=0
v_VERSION=$(date -r $0 +"%Y.%m.%d.%H")
v_BACKTITLE="XPi ver. $v_VERSION"

# Avoid multiple starts, so force close
[[ "$(pgrep -c -f $(basename $0))" -gt 1 ]] && exit

# Check dependencies for executing and working this script
function f_checkDependencies(){
    # Whiptail installed
    if ! [ -x "$(command -v whiptail)" ]; then
        sudo apt-get install -y whiptail >> ${v_LOGFILE}
    fi

    # Wget installed
    if ! [ -x "$(command -v wget)" ]; then
        sudo apt-get install -y wget >> ${v_LOGFILE}
    fi
}

# Execute function
function execute(){
    f_checkDependencies
    f_iniFile

    . $v_INIFILE &>/dev/null

    f_welcome
    f_menuMain
}

# Welcome text
function f_welcome(){
    whiptail \
        --backtitle "XPi ver. $v_VERSION" \
        --title "Welcome" \
        --msgbox "Welcome to the installation programm\nHave a nice day!" \
        $v_HEIGHT $v_WIDTH
}

# Main menu
function f_menuMain(){
    local lv_MenuSelect=$(whiptail \
                            --backtitle "XPi ver. $v_VERSION" \
                            --title "Main" \
                            --cancel-button "Exit" \
                            --menu "" \
                            $v_HEIGHT $v_WIDTH $(( $v_HEIGHT - 8 )) \
                            "0" "Exit" \
                            "1" "Setup" \
                            "2" "Optional" \
                            3>&1 1>&2 2>&3)
    
    local lv_exitstatus=$?

    if [[ $lv_exitstatus = 0 ]]; then
        case $lv_MenuSelect in
            1)
                f_menuSetup
            ;;
            2)
                f_menuOptional
            ;;
            0)
                clear
                echo "Thank you and goodbye!"
            ;;
        esac
    else
        clear
        echo "Thank you and goodbye!"
    fi
}

# Setup menu
function f_menuSetup(){
    local lv_MenuSelect=$(whiptail \
                            --backtitle "XPi ver. $v_VERSION" \
                            --title "Setup" \
                            --nocancel \
                            --menu "" \
                            $v_HEIGHT $v_WIDTH $(( $v_HEIGHT - 8 )) \
                            "0" "<- Back to Main" \
                            "1" "Sudo                          $v_SUDO" \
                            "2" "Update & Upgrade" \
                            "3" "Programs" \
                            "4" "Folders                       $v_FOLDERS" \
                            "5" "Language packs - en/sl        $v_LANGPACKS" \
                            "6" "Autostart folder              $v_AUTOSTARTF" \
                            "R" "RetroPie                      $v_RETROPIE" \
                            "V" "Video drivers" \
                            "O" "Own all folders to User: $USER" \
                            3>&1 1>&2 2>&3)
    
    case $lv_MenuSelect in
        1)
            log 2 "f_menuSetup -> f_menuSudo"
            f_menuSudo
        ;;
        2)
            log 2 "Call f_updateAndUpgrade"
            f_updateAndUpgrade
            f_menuSetup
        ;;
        3)
            log 2 "f_menuSetup -> f_menuProgs"
            f_menuProgs
        ;;
        4)
            log 2 "Folders"
            if ! [ -d "$HOME/Dokumenti" ]; then
                log 2 "Folders $v_FOLDERS - Create"
                mkdir -p "$HOME/Dokumenti" "$HOME/Glasba" "$HOME/Javno" "$HOME/Slike" "$HOME/Video" "$HOME/Namizje" "$HOME/Predloge" "$HOME/Prejemi" >> ${v_LOGFILE}
                f_
                v_FOLDERS="(Present)"

            else
                log 2 "Folders $v_FOLDERS - Delete"
                sudo rm -rf Dokumenti Glasba Javno Slike Video Namizje Predloge Prejemi >> ${v_LOGFILE}
                v_FOLDERS="(Not present)"
            fi
            f_changeState ${!v_FOLDERS@} $v_FOLDERS

            f_menuSetup
        ;;
        5)
            log 2 "Language packs"
            log 2 "Language packs - Install - English"
            sudo apt-get -y install language-pack-en language-pack-gnome-en hunspell-en thunderbird-locale-en libreoffice-l10n-en >> ${v_LOGFILE}
            log 2 "Language packs - Install - Slovenian"
            sudo apt-get -y install language-pack-sl language-pack-gnome-sl hunspell-sl thunderbird-locale-sl libreoffice-l10n-sl >> ${v_LOGFILE}
            v_LANGPACKS="(Installed)"
            f_changeState ${!v_LANGPACKS@} $v_LANGPACKS

            f_menuSetup
        ;;
        6)
            log 2 "Autostart"
            log 2 "Autostart - Folder check"
            if [ ! -d "$HOME/.config/autostart" ]; then
                log 2 "Create Autostart folder"
                mkdir -p "$HOME/.config/autostart" >> ${v_LOGFILE}
                sudo chown -R $USER:$USER "$HOME/.config/autostart" >> ${v_LOGFILE}
                v_AUTOSTARTF="(Present)"
                f_changeState ${!v_AUTOSTARTF@} $v_AUTOSTARTF
            fi

            f_menuSetup
        ;;
        R)
            log 2 "RetroPie"
            log 2 "RetroPie - Check dependencies"
            if [ -x "$(command -v git)" ] & [ -x "$(command -v dialog)" ] & [ -x "$(command -v unzip)" ] & [ -x "$(command -v xmlstarlet)" ]; then
                log 2 "RetroPie - Check installation"
                if [ ! -x "$(command -v emulationstation)" ]; then
                    log 2 "Call f_RetroPie -install"
                    f_RetroPie -install
                    v_RETROPIE="(Installed)"
                    f_changeState ${!v_RETROPIE@} $v_RETROPIE
                else
                	log 2 "Call f_RetroPie -remove"
                	f_RetroPie -remove
                fi

                f_menuSetup
            else
                f_menuProgs
            fi
        ;;
        V)
            log 2 "f_menuSetup -> f_menuVideo"
            f_menuVideo
        ;;
        O)
            sudo chown -R $USER:$USER "$HOME/.config/autostart"
            sudo chown -R $USER:$USER /etc/emulationstation
            sudo chown -R $USER:$USER /etc/samba

            f_menuSetup
        ;;
        0)
            f_menuMain
        ;;
    esac
}

# Video menu
function f_menuVideo(){
    local lv_MenuSelect=$(whiptail \
                            --backtitle "XPi ver. $v_VERSION" \
                            --title "Video" \
                            --nocancel \
                            --menu "" \
                            $v_HEIGHT $v_WIDTH $(( $v_HEIGHT - 8 )) \
                            "0" "<- Back to Setup" \
                            "1" "Common" \
                            "2" "ION" \
                            "3" "Vulcan " \
                            3>&1 1>&2 2>&3)

    case $lv_MenuSelect in
        1)
            sudo apt-get -y install ubuntu-drivers-common
            sudo ubuntu-drivers autoinstall

            f_menuVideo
        ;;
        2)
            cd $HOME
            smbget --user=$SMBUSER -n -u "$SMBSERVERSETUP/NVIDIA-Linux-x86_64-340.107.run"
            sudo dpkg --add-architecture i386
            sudo apt-get update
            sudo apt-get -y install build-essential libc6:i386
            sudo bash -c "echo blacklist nouveau > /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
            sudo bash -c "echo options nouveau modeset=0 >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
            sudo cat /etc/modprobe.d/blacklist-nvidia-nouveau.conf
            smbget --user=$SMBUSER -n -u "$SMBSERVERSETUP/.nvidia-settings-rc"
            sleep 3

            sudo update-initramfs -u

            if (whiptail \
                --title "Instructions after reboot" \
                --nocancel \
                --msgbox "1. CTRL + ALT + F2 -> Go to terminal\n2. Login\n3. sudo telinit 3\n4. sudo bash NVIDIA-Linux-x86_64-390.77.run\n   -> Accept\n   -> Continue installation\n   -> No (DKMS)\n   -> Ignore CC version check\n   -> Yes (32-bit)\n   -> Yes (nvidia-xconfig)\n   -> OK\n5. rm NVIDIA-Linux-x86_64-390.77.run\n6. sudo reboot" \
                $v_HEIGHT $v_WIDTH $(( $v_HEIGHT - 8 ))); then
                sudo reboot
            fi

            f_menuVideo
        ;;
        3)
            sudo apt-get -y install mesa-vulkan-drivers

            f_menuVideo
        ;;
        0)
            f_menuSetup
        ;;
    esac
}

# Sudo menu
function f_menuSudo(){
    local lv_MenuSelect=$(whiptail \
                            --backtitle "XPi ver. $v_VERSION" \
                            --title "Sudo $v_SUDO" \
                            --nocancel \
                            --menu "" \
                            $v_HEIGHT $v_WIDTH $(( $v_HEIGHT - 8 )) \
                            "0" "<- Back to Setup" \
                            "1" "Sudo $v_SUDO" \
                            "2" "View /etc/sudoers" \
                            3>&1 1>&2 2>&3)

    case $lv_MenuSelect in
        1)
            sudo cat "/etc/sudoers" > sudoers
            if grep -q "$USER ALL=(ALL) NOPASSWD:ALL" sudoers  
            then
                f_Sudo -disable
                v_SUDO="(Disabled)"
            else
                f_Sudo -enable
                v_SUDO="(Enabled)"
            fi
            f_changeState ${!v_SUDO@} $v_SUDO
            f_menuSudo
        ;;
        2)
            f_Sudo -show
            f_menuSudo
        ;;
        0)
            f_menuSetup
        ;;
    esac
}

# Programs menu
function f_menuProgs(){
    local lv_MenuSelect=$(whiptail \
                            --backtitle "XPi ver. $v_VERSION" \
                            --title "Programs" \
                            --nocancel \
                            --menu "*:RetroPie Dependencie" \
                            $v_HEIGHT $v_WIDTH $(( $v_HEIGHT - 8 )) \
                            "0" "<- Back to Setup" \
                            "A" "Install all" \
                            "U" "Uninstall all" \
                            "B" "Extra programs                $v_PROG_extra" \
                            "1" "*git                          $v_PROG_git" \
                            "2" "*dialog                       $v_PROG_dialog" \
                            "3" "*unzip                        $v_PROG_unzip" \
                            "4" "*xmlstarlet                   $v_PROG_xmlstarlet" \
                            "5" "htop                          $v_PROG_htop" \
                            "6" "mpv                           $v_PROG_mpv" \
                            "7" "psensor                       $v_PROG_psensor" \
                            "8" "curl                          $v_PROG_curl" \
                            "9" "nfs-common                    $v_PROG_nfscommon" \
                            "10" "cifs-utils                    $v_PROG_cifsutils" \
                            "11" "dos2unix                      $v_PROG_dos2unix" \
                            "12" "lm-sensors                    $v_PROG_lmsensors" \
                            "13" "hddtemp                       $v_PROG_hddtemp" \
                            "14" "p7zip                         $v_PROG_p7zip" \
                            "15" "anydesk                       $v_PROG_anydesk" \
                            3>&1 1>&2 2>&3)
    
    case $lv_MenuSelect in
        A)
            f_InstallAllPrograms
            f_menuProgs
        ;;
        B)
            f_ExtraPrograms
            f_menuProgs
        ;;
        1)
            if [ -x "$(command -v git)" ]; then
                f_Program -remove git
                v_PROG_git="(Not installed)"
            else
                f_Program -install git
                v_PROG_git="(Installed)"
            fi
            f_changeState ${!v_PROG_git@} $v_PROG_git
            f_menuProgs
        ;;
        2)
            if [ -x "$(command -v dialog)" ]; then
                f_Program -remove dialog
                v_PROG_dialog="(Not installed)"
            else
                f_Program -install dialog
                v_PROG_dialog="(Installed)"
            fi
            f_changeState ${!v_PROG_dialog@} $v_PROG_dialog
            f_menuProgs
        ;;
        3)
            if [ -x "$(command -v unzip)" ]; then
                f_Program -remove unzip
                v_PROG_unzip="(Not installed)"
            else
                f_Program -install unzip
                v_PROG_unzip="(Installed)"
            fi
            f_changeState ${!v_PROG_unzip@} $v_PROG_unzip
            f_menuProgs
        ;;
        4)
            if [ -x "$(command -v xmlstarlet)" ]; then
                f_Program -remove xmlstarlet
                v_PROG_xmlstarlet="(Not installed)"
            else
                f_Program -install xmlstarlet
                v_PROG_xmlstarlet="(Installed)"
            fi
            f_changeState ${!v_PROG_xmlstarlet@} $v_PROG_xmlstarlet
            f_menuProgs
        ;;
        5)
            if [ -x "$(command -v htop)" ]; then
                f_Program -remove htop
                v_PROG_htop="(Not installed)"
            else
                f_Program -install htop
                v_PROG_htop="(Installed)"
            fi
            f_changeState ${!v_PROG_htop@} $v_PROG_htop
            f_menuProgs
        ;;
        6)
            if [ -x "$(command -v mpv)" ]; then
                f_Program -remove mpv
                v_PROG_mpv="(Not installed)"
            else
                f_Program -install mpv
                v_PROG_mpv="(Installed)"
            fi
            f_changeState ${!v_PROG_mpv@} $v_PROG_mpv
            f_menuProgs
        ;;
        7)
            if [ -x "$(command -v psensor)" ]; then
                f_Program -remove psensor
                v_PROG_psensor="(Not installed)"
            else
                f_Program -install psensor
                v_PROG_psensor="(Installed)"
            fi
            f_changeState ${!v_PROG_psensor@} $v_PROG_psensor
            f_menuProgs
        ;;
        8)
            if [ -x "$(command -v curl)" ]; then
                f_Program -remove curl
                v_PROG_curl="(Not installed)"
            else
                f_Program -install curl
                v_PROG_curl="(Installed)"
            fi
            f_changeState ${!v_PROG_curl@} $v_PROG_curl
            f_menuProgs
        ;;
        9)
            dpkg -s lm-sensors &> /dev/null
            if [ $? -eq 0 ]; then
                sudo apt-get -y purge nfs-common
                sudo apt-get -y clean
                sudo apt-get -y autoremove
                v_PROG_nfscommon="(Not Installed)"
            else
                sudo apt-get -y install nfs-common
                v_PROG_nfscommon="(Installed)"
            fi
            f_changeState ${!v_PROG_nfscommon@} $v_PROG_nfscommon
            f_menuProgs
        ;;
        10)
            dpkg -s lm-sensors &> /dev/null
            if [ $? -eq 0 ]; then
                sudo apt-get -y purge cifs-utils
                sudo apt-get -y clean
                sudo apt-get -y autoremove
                v_PROG_cifsutils="(Not Installed)"
            else
                sudo apt-get -y install cifs-utils
                v_PROG_cifsutils="(Installed)"
            fi
            f_changeState ${!v_PROG_cifsutils@} $v_PROG_cifsutils
            f_menuProgs
        ;;
        11)
            if [ -x "$(command -v dos2unix)" ]; then
                f_Program -remove dos2unix
                v_PROG_dos2unix="(Not installed)"
            else
                f_Program -install dos2unix
                v_PROG_dos2unix="(Installed)"
            fi
            f_changeState ${!v_PROG_dos2unix@} $v_PROG_dos2unix
            f_menuProgs
        ;;
        12)
            dpkg -s lm-sensors &> /dev/null
            if [ $? -eq 0 ]; then
                sudo apt-get -y purge lm-sensors
                sudo apt-get -y clean
                sudo apt-get -y autoremove
                v_PROG_lmsensors="(Not Installed)"
            else
                sudo apt-get -y install lm-sensors
                v_PROG_lmsensors="(Installed)"
            fi
            f_changeState ${!v_PROG_lmsensors@} $v_PROG_lmsensors
            f_menuProgs
        ;;
        13)
            if [ -x "$(command -v hddtemp)" ]; then
                f_Program -remove hddtemp
                v_PROG_hddtemp="(Not installed)"
            else
                f_Program -install hddtemp
                v_PROG_hddtemp="(Installed)"
            fi
            f_changeState ${!v_PROG_hddtemp@} $v_PROG_hddtemp
            f_menuProgs
        ;;
        14)
            if [ -x "$(command -v p7zip)" ]; then
                f_Program -remove p7zip
                v_PROG_p7zip="(Not installed)"
            else
                f_Program -install p7zip
                v_PROG_p7zip="(Installed)"
            fi
            f_changeState ${!v_PROG_p7zip@} $v_PROG_p7zip
            f_menuProgs
        ;;
        15)
            if [ -x "$(command -v anydesk)" ]; then
                f_AnyDesk -remove
                v_PROG_anydesk="(Not installed)"
            else
                f_AnyDesk -install
                v_PROG_anydesk="(Installed)"
            fi
            f_changeState ${!v_PROG_anydesk@} $v_PROG_anydesk
            f_menuProgs
        ;;
        U)
            if (whiptail --title "Uninstall all" --yesno "Do you want to uninstall all programs?" $v_HEIGHT $v_WIDTH); then
                f_UninstallAllPrograms
                f_menuProgs
            else
                f_menuProgs
            fi
        ;;
        0)
            f_menuSetup
        ;;
    esac
}



# **** FUNCTIONS ****

# Disable Sudo
function f_Sudo() {
    clear
    echo ""
    echo "---------------------------------------------------------------------------"
    echo " Sudo$1"
    echo "---------------------------------------------------------------------------"
    echo ""

    if [ "$#" -gt 0 ]; then
        case "$1" in
            -enable)
                echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
            ;;
            -disable)
                sudo sed -i "/ALL=(ALL) NOPASSWD:ALL/d" /etc/sudoers
            ;;
            -show)
                sudo cat "/etc/sudoers" > sudoers
                whiptail --textbox --scrolltext sudoers $v_HEIGHT $v_WIDTH
                sudo rm sudoers
            ;;
            *)
                echo "$1 - not a valid parameter...EXITing..."
            ;;
        esac
    else
        echo "No parameter...EXITing..."
    fi

    echo "DONE"
}

function f_updateAndUpgrade() {
    clear
    echo ""
    echo "---------------------------------------------------------------------------"
    echo " Update & Upgrade"
    echo "---------------------------------------------------------------------------"
    echo ""

    sudo apt-get update && sudo apt-get -y upgrade
}

function f_Program() {
    clear
    echo ""
    echo "---------------------------------------------------------------------------"
    echo " $2$1"
    echo "---------------------------------------------------------------------------"
    echo ""

    if [ "$#" -gt 0 ]; then
        case "$1" in
            -install)
                sudo apt-get -y install $2 2>&1 | tee -a ${v_LOGFILE}
            ;;
            -remove)
                sudo apt-get -y purge $2
                sudo apt-get -y clean
                sudo apt-get -y autoremove
            ;;
            *)
                echo "$1 - not a valid parameter...EXITing..."
            ;;
        esac
    else
        echo "No parameter...EXITing..."
    fi

    echo "DONE"
}

function f_RetroPie() {
    if [ "$#" -gt 0 ]; then
        case "$1" in
            -install)
                declare -a a_commands
                a_commands[0]="cd $HOME"
                a_commands[1]="git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git"
                a_commands[2]="sudo $HOME/RetroPie-Setup/retropie_packages.sh retroarch"
                a_commands[3]="sudo $HOME/RetroPie-Setup/retropie_packages.sh emulationstation-dev"
                a_commands[4]="sudo $HOME/RetroPie-Setup/retropie_packages.sh retropiemenu"
                a_commands[5]="sudo $HOME/RetroPie-Setup/retropie_packages.sh runcommand"
                a_commands[6]="sudo $HOME/RetroPie-Setup/retropie_packages.sh xpad"
                a_commands[7]="sudo $HOME/RetroPie-Setup/retropie_packages.sh samba"
                a_commands[8]="sudo $HOME/RetroPie-Setup/retropie_packages.sh samba install_shares"
                a_commands[9]="sudo apt-get -y install smbclient"
                a_commands[10]="sudo chown -R $USER:$USER /etc/emulationstation"
                a_commands[11]="sudo chown -R $USER:$USER /etc/samba"

                if (whiptail \
                	--title "RetroPie -install" \
                	--yesno "Are you sure to install RetroPie? It will take a while..." \
                	$(( $v_HEIGHT/2 )) $v_WIDTH)
			    then
			        log 2 "$0 -install"
	                f_getAvailableConnection
	                if [[ f_getAvailableConnection -eq 0 ]]; then
	                    if [[  v_VERBOSE -eq 0 ]]; then
	                        log 2 "${FUNCNAME[0]} -install - GUI"
	                        {
	                            for (( i = 0; i < ${#a_commands[@]}; i++ )); do
	                                echo "XXX"
	                                echo "$(( (100*$(( i+1 )))/${#a_commands[@]} ))"
	                                echo "${a_commands[$(( i+1 ))]}"
	                                eval "${a_commands[$i]} >> ${v_LOGFILE} 2>&1"
	                                echo "XXX"
	                                sleep 2
	                            done
	                            echo "XXX"
                                echo "100"
                                echo "All done."
                                echo "XXX"
	                            sleep 2
	                        } | whiptail \
	                        		--title "RetroPie -install" \
	                        		--gauge "Please wait while installing" \
	                        		$(( $v_HEIGHT/4 )) $v_WIDTH 0
	                    else
	                        log 2 "${FUNCNAME[0]} -install - Verbose"
	                        clear
						    echo ""
						    echo "---------------------------------------------------------------------------"
						    echo " ${FUNCNAME[0]} -install - Verbose"
						    echo "---------------------------------------------------------------------------"
						    echo ""
	                        for (( i = 0; i < ${#a_commands[@]}; i++ )); do
	                            eval "${a_commands[$i]} 2>&1 | tee -a ${v_LOGFILE}"
	                        done
	                        echo "DONE"
	                        sleep 5
	                    fi
	                    return 0
	                else
	                    log 1 "${FUNCNAME[0]} -install - No internet connection" ${LINENO}
	                    return 1
	                fi
			    else
			        log 2 "${FUNCNAME[0]} -install - Break"
			        return 1
				fi
            ;;
            -remove)
                log 2 "${FUNCNAME[0]} -remove"
                sudo apt-get -y clean >> ${v_LOGFILE}
                sudo apt-get -y autoremove >> ${v_LOGFILE}
                return 0
            ;;
            *)
                log 1 "${FUNCNAME[0]} -false parameter: $1" ${LINENO}
                return 1
            ;;
        esac
    else
        log 1 "${FUNCNAME[0]} -no parameter" ${LINENO}
        return 1
    fi
}                   

function f_AnyDesk() {
    clear
    echo ""
    echo "---------------------------------------------------------------------------"
    echo " AnyDesk$1"
    echo "---------------------------------------------------------------------------"
    echo ""
    if [ "$#" -gt 0 ]; then
        case "$1" in
            -install)
                wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo apt-key add -
                echo "deb http://deb.anydesk.com/ all main" | sudo tee -a /etc/apt/sources.list.d/anydesk-stable.list
                sudo apt-get update
                sudo apt-get install -y anydesk
                sudo echo "$RCPASSWORD" | sudo anydesk --set-password

                # Disable Anydesk service
                sudo systemctl disable anydesk

                # Copy icon
                cd "$HOME/RetroPie/retropiemenu/icons"
                ## TODO wget 
                smbget --user=$SMBUSER -n -u "$SMBSERVERSETUP/anydesk.png"

                # create script for retropie menu
                cat << EOF > "$HOME/RetroPie/retropiemenu/anydesk.sh"
#!/bin/bash
anydesk
killall -9 anydesk
EOF
                chmod +x "$HOME/RetroPie/retropiemenu/anydesk.sh"

                #Insert into gamelist
                if [[ $(xmlstarlet sel -t -v "count(/gameList/game[path='./anydesk.sh'])" $HOME/.emulationstation/gamelists/retropie/gamelist.xml) -eq 0 ]]
                then  
                    xmlstarlet ed \
                        --inplace \
                        --subnode "/gameList" --type elem -n game -v ""  \
                        --subnode "/gameList/game[last()]" --type elem -n path -v "./anydesk.sh" \
                        --subnode "/gameList/game[last()]" --type elem -n name -v "Anydesk Remote Desktop" \
                        --subnode "/gameList/game[last()]" --type elem -n desc -v "AnyDesk ensures secure and reliable remote desktop connections for IT professionals and on-the-go individuals alike. (https://anydesk.com)" \
                        --subnode "/gameList/game[last()]" --type elem -n image -v "./icons/anydesk.png" \
                        $HOME/.emulationstation/gamelists/retropie/gamelist.xml
                fi
            ;;
            -remove)
                sudo apt-get -y purge anydesk
                sudo apt-get -y clean
                sudo apt-get -y autoremove

                sudo rm -rf "$HOME/RetroPie/retropiemenu/icons/anydesk.png"
                sudo rm -rf "$HOME/RetroPie/retropiemenu/anydesk.sh"

                if [[ $(xmlstarlet sel -t -v "count(/gameList/game[path='./anydesk.sh'])" $HOME/.emulationstation/gamelists/retropie/gamelist.xml) -ne 0 ]]
                then  
                    xmlstarlet ed \
                        --inplace \
                        --delete "//game[path='./anydesk.sh']" \
                        $HOME/.emulationstation/gamelists/retropie/gamelist.xml
                fi
            ;;
            *)
                echo "$1 - not a valid parameter...EXITing..."
            ;;
        esac
    else
        echo "No parameter...EXITing..."
    fi

    echo "DONE"
}

function f_changeState() {
    if [[ "$#" -gt 0 ]]; then
        sudo sed -i "/$1/d" $v_INIFILE
        echo "$1=\"$2\"" | sudo tee -a $v_INIFILE
    fi
}

function f_InstallAllPrograms() {
    clear
    echo ""
    echo "---------------------------------------------------------------------------"
    echo " Installing all programs"
    echo "---------------------------------------------------------------------------"
    echo ""

    f_InstallProgram git
    v_PROG_git="(Installed)"
    f_InstallProgram dialog
    v_PROG_dialog="(Installed)"
    f_InstallProgram unzip
    v_PROG_unzip="(Installed)"
    f_InstallProgram xmlstarlet
    v_PROG_xmlstarlet="(Installed)"
    f_InstallProgram htop
    v_PROG_htop="(Installed)"
    f_InstallProgram mpv
    v_PROG_mpv="(Installed)"
    f_InstallProgram psensor
    v_PROG_psensor="(Installed)"
    f_InstallProgram curl
    v_PROG_curl="(Installed)"

    sudo apt-get -y install nfs-common
    sudo sed -i "/v_PROG_nfscommon/d" $v_INIFILE
    echo "v_PROG_nfscommon=\"(Installed)\"" | sudo tee -a $v_INIFILE

    sudo apt-get -y install cifs-utils
    sudo sed -i "/v_PROG_cifsutils/d" $v_INIFILE
    echo "v_PROG_cifsutils=\"(Installed)\"" | sudo tee -a $v_INIFILE

    f_InstallProgram dos2unix
    v_PROG_dos2unix="(Installed)"

    sudo apt-get -y install lm-sensors
    sudo sed -i "/v_PROG_lmsensors/d" $v_INIFILE
    echo "v_PROG_lmsensors=\"(Installed)\"" | sudo tee -a $v_INIFILE

    f_InstallProgram hddtemp
    v_PROG_hddtemp="(Installed)"
    f_InstallProgram p7zip
    v_PROG_p7zip="(Installed)"

    echo "ALL DONE"
}

# Uninstall all programs
function f_UninstallAllPrograms() {
    clear
    echo ""
    echo "---------------------------------------------------------------------------"
    echo " Uninstalling all programs"
    echo "---------------------------------------------------------------------------"
    echo ""
    f_UninstallProgram git
    v_PROG_git="(Not Installed)"
    f_UninstallProgram dialog
    v_PROG_dialog="(Not Installed)"
    f_UninstallProgram unzip
    v_PROG_unzip="(Not Installed)"
    f_UninstallProgram xmlstarlet
    v_PROG_xmlstarlet="(Not Installed)"
    f_UninstallProgram htop
    v_PROG_htop="(Not Installed)"
    f_UninstallProgram mpv
    v_PROG_mpv="(Not Installed)"
    f_UninstallProgram psensor
    v_PROG_psensor="(Not Installed)"
    f_UninstallProgram curl
    v_PROG_curl="(Not Installed)"

    sudo apt-get -y purge nfs-common
    sudo sed -i "/v_PROG_nfscommon/d" $v_INIFILE
    echo "v_PROG_nfscommon=\"(Not Installed)\"" | sudo tee -a $v_INIFILE

    sudo apt-get -y purge cifs-utils
    sudo sed -i "/v_PROG_cifsutils/d" $v_INIFILE
    echo "v_PROG_cifsutils=\"(Not Installed)\"" | sudo tee -a $v_INIFILE

    f_UninstallProgram dos2unix
    v_PROG_dos2unix="(Not Installed)"

    sudo apt-get -y purge lm-sensors
    sudo sed -i "/v_PROG_lmsensors/d" $v_INIFILE
    echo "v_PROG_lmsensors=\"(Not Installed)\"" | sudo tee -a $v_INIFILE

    f_UninstallProgram hddtemp
    v_PROG_hddtemp="(Not Installed)"
    f_UninstallProgram p7zip
    v_PROG_p7zip="(Not Installed)"

    echo "ALL DONE"
}

# Install/Uninstall extra programs
function f_ExtraPrograms() {
    clear
    if [[ $v_PROG_extra = "(Installed)" ]]; then
        echo ""
        echo "---------------------------------------------------------------------------"
        echo " Uninstall extra programs"
        echo "---------------------------------------------------------------------------"
        echo ""
        f_UninstallProgram samba
        f_UninstallProgram firefox
        f_UninstallProgram simple-scan
        f_UninstallProgram xfburn
        f_UninstallProgram parole
        f_UninstallProgram blueman
        f_UninstallProgram gnome-mines
        f_UninstallProgram gnome-sudoku
        f_UninstallProgram sgt-puzzles
        f_UninstallProgram light-locker
        f_UninstallProgram system-config-printer-common
        v_PROG_extra="(Not Installed)"
    else
        echo ""
        echo "---------------------------------------------------------------------------"
        echo " Install extra programs"
        echo "---------------------------------------------------------------------------"
        echo ""
        f_InstallProgram samba
        f_InstallProgram firefox
        f_InstallProgram simple-scan
        f_InstallProgram xfburn
        f_InstallProgram parole
        f_InstallProgram blueman
        f_InstallProgram gnome-mines
        f_InstallProgram gnome-sudoku
        f_InstallProgram sgt-puzzles
        f_InstallProgram light-locker
        f_InstallProgram system-config-printer-common
        v_PROG_extra="(Installed)"
    fi

    echo "ALL DONE"
}

## @fn f_INIFile()
## @brief Creates an INI file for parameters
function f_INIFile() {
    if [[ ! -f $v_INIFILE ]]; then

        echo 'v_FTPSERVER="ftp://ftp.steiner.si"' >> $v_INIFILE
        echo 'v_FTPPORT="21"' >> $v_INIFILE

        sudo cat "/etc/sudoers" > tempfile_sudoers
        if grep -q "$USER ALL=(ALL) NOPASSWD:ALL" tempfile_sudoers  
        then
            echo 'v_SUDO="(Enabled)"' >> $v_INIFILE
        else
            echo 'v_SUDO="(Disabled)"' >> $v_INIFILE
        fi
        sudo rm -f tempfile_sudoers

        if [ -x "$(command -v git)" ]; then
            echo 'v_PROG_git="(Installed)"' >> $v_INIFILE
        else
            echo 'v_PROG_git="(Not installed)"' >> $v_INIFILE
        fi

        if [ -x "$(command -v dialog)" ]; then
            echo 'v_PROG_dialog="(Installed)"' >> $v_INIFILE
        else
            echo 'v_PROG_dialog="(Not installed)"' >> $v_INIFILE
        fi

        if [ -x "$(command -v unzip)" ]; then
            echo 'v_PROG_unzip="(Installed)"' >> $v_INIFILE
        else
            echo 'v_PROG_unzip="(Not installed)"' >> $v_INIFILE
        fi

        if [ -x "$(command -v xmlstarlet)" ]; then
            echo 'v_PROG_xmlstarlet="(Installed)"' >> $v_INIFILE
        else
            echo 'v_PROG_xmlstarlet="(Not installed)"' >> $v_INIFILE
        fi

        if [ -x "$(command -v htop)" ]; then
            echo 'v_PROG_htop="(Installed)"' >> $v_INIFILE
        else
            echo 'v_PROG_htop="(Not installed)"' >> $v_INIFILE
        fi

        if [ -x "$(command -v mpv)" ]; then
            echo 'v_PROG_mpv="(Installed)"' >> $v_INIFILE
        else
            echo 'v_PROG_mpv="(Not installed)"' >> $v_INIFILE
        fi

        if [ -x "$(command -v psensor)" ]; then
            echo 'v_PROG_psensor="(Installed)"' >> $v_INIFILE
        else
            echo 'v_PROG_psensor="(Not installed)"' >> $v_INIFILE
        fi

        if [ -x "$(command -v curl)" ]; then
            echo 'v_PROG_curl="(Installed)"' >> $v_INIFILE
        else
            echo 'v_PROG_curl="(Not installed)"' >> $v_INIFILE
        fi

        dpkg -s nfs-common &> /dev/null
        if [ $? -eq 0 ]; then
            echo 'v_PROG_nfscommon="(Installed)"' >> $v_INIFILE
        else
            echo 'v_PROG_nfscommon="(Not installed)"' >> $v_INIFILE
        fi

        dpkg -s cifs-utils &> /dev/null
        if [ $? -eq 0 ]; then
            echo 'v_PROG_cifsutils="(Installed)"' >> $v_INIFILE
        else
            echo 'v_PROG_cifsutils="(Not installed)"' >> $v_INIFILE
        fi

        if [ -x "$(command -v dos2unix)" ]; then
            echo 'v_PROG_dos2unix="(Installed)"' >> $v_INIFILE
        else
            echo 'v_PROG_dos2unix="(Not installed)"' >> $v_INIFILE
        fi

        dpkg -s lm-sensors &> /dev/null
        if [ $? -eq 0 ]; then
            echo 'v_PROG_lmsensors="(Installed)"' >> $v_INIFILE
        else
            echo 'v_PROG_lmsensors="(Not installed)"' >> $v_INIFILE
        fi

        if [ -x "$(command -v hddtemp)" ]; then
            echo 'v_PROG_hddtemp="(Installed)"' >> $v_INIFILE
        else
            echo 'v_PROG_hddtemp="(Not installed)"' >> $v_INIFILE
        fi

        if [ -x "$(command -v p7zip)" ]; then
            echo 'v_PROG_p7zip="(Installed)"' >> $v_INIFILE
        else
            echo 'v_PROG_p7zip="(Not installed)"' >> $v_INIFILE
        fi

        if [ -x "$(command -v gnome-mines)" ]; then
            echo 'v_PROG_extra="(Installed)"' >> $v_INIFILE
        else
            echo 'v_PROG_extra="(Not installed)"' >> $v_INIFILE
        fi

        if [ -d "$HOME/Dokumenti" ]; then
            echo 'v_FOLDERS="(Present)"' >> $v_INIFILE
        else
            echo 'v_FOLDERS="(Not present)"' >> $v_INIFILE
        fi

        if [ -d "$HOME/.config/autostart" ]; then
            echo 'v_AUTOSTARTF="(Present)"' >> $v_INIFILE
        else
            echo 'v_AUTOSTARTF="(Not present)"' >> $v_INIFILE
        fi

        echo 'v_LANGPACKS="(Not installed)"' >> $v_INIFILE

        if [ -x "$(command -v emulationstation)" ]; then
            echo 'v_RETROPIE="(Installed)"' >> $v_INIFILE
        else
            echo 'v_RETROPIE="(Not installed)"' >> $v_INIFILE
        fi

        if [ -x "$(command -v anydesk)" ]; then
            echo 'v_PROG_anydesk="(Installed)"' >> $v_INIFILE
        else
            echo 'v_PROG_anydesk="(Not installed)"' >> $v_INIFILE
        fi
    fi
}

## @fn log()
## @param 1 Severity (0: Error; 1: Warning; 2: Info; 3: Debug)
## @param 2 Message
## @param 3 Line number
## @brief Prints messages of different severeties to a file
function log() {
	# Prints messages of different severeties to a v_LOGFILE
	# Each message will look something like this:
	# <TIMESTAMP>   <SEVERITY>  <CALLING_FUNCTION>:<LINENUMBER>  <MESSAGE>
	# needs a set variable $v_LOGLEVEL
	#   -1 > No logging at all
	#   0 > prints ERRORS only
	#   1 > prints ERRORS and WARNINGS
	#   2 > prints ERRORS, WARNINGS and INFO
	#   3 > prints ERRORS, WARNINGS, INFO and DEBUGGING
	# needs a set variable $log pointing to a file
	# Usage
	# log 0 "This is an ERROR Message"
	# log 1 "This is a WARNING"
	# log 2 "This is just an INFO"
	# log 3 "This is a DEBUG message"
    local lv_Severity=$1
    local lv_Message=$2
    local lv_Line=":${3}"

    if (( ${lv_Severity} <= ${v_LOGLEVEL} ))
    then
        case ${lv_Severity} in
            0) lv_Level="ERROR"  ;;
            1) lv_Level="WARNING"  ;;
            2) lv_Level="INFO"  ;;
            3) lv_Level="DEBUG"  ;;
        esac
        
        printf "$(date +'%d.%m.%Y %H:%M:%S'):\t${lv_Level}\t${0##*/}\t${FUNCNAME[1]}${lv_Line}\t${lv_Message}\n" >> ${v_LOGFILE} 
    fi
}

## @fn f_getAvailableConnection()
## @brief checks if the device is connected to a LAN / WLAN and the Internet
## @retval 0 device seems to be connected to the Internet
## @retval 1 device seems to be connected to a LAN / WLAN without internet access
## @retval 2 device doesn't seem to be connected at all
function f_getAvailableConnection() {
    local lv_GatewayIP=$(ip r | grep default | cut -d " " -f 3)  
    if [ "${lv_GatewayIP}" == "" ]
    then 
        log 2 "Gateway could not be detected"
        return 2
    else
        log 2 "Gateway IP: ${lv_GatewayIP}"
    fi
    
    ping -q -w 1 -c 1 ${lv_GatewayIP} > /dev/null
    if [[ $? -eq 0 ]]
    then
        log 2 "Gateway PING successful"
    else
        log 2 "Gateway could not be PINGed"
        return 2
    fi
    
    ping -q -w 1 -c 1 "8.8.8.8" > /dev/null
    if [[ $? -eq 0 ]]
    then
        log 2 "8.8.8.8 PING successful"
        return 0
    else
        log 2 "8.8.8.8 could not be PINGed"
        return 1
    fi
}

## @fn f_rmDirExists()
## @param dir directory to remove
## @brief Removes a directory and all contents if it exists.
function f_rmDirExists() {
    if [[ -d "$1" ]]; then
        sudo rm -rf "$1" >> ${v_LOGFILE}
    fi
}

## @fn f_mkUserDir()
## @param dir directory to create
## @brief Creates a directory owned by the current user.
function f_mkUserDir() {
    mkdir -p "$1" >> ${v_LOGFILE}
    chown $user:$user "$1" >> ${v_LOGFILE}
}

execute