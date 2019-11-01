#!/bin/dash

# Fetch sai.sh variables
cdrive=$(cat temp | grep /dev)
bs=$(cat temp | grep EFI)
auto=$(cat temp | sed -n '3')

### FUNCTIONS ###

error() { printf "Something went wrong, maybe it was the script, maybe it was you, who knows."; exit; }

nxt() { echo "Next" | slmenu -p "Continue?"; }

xit() {
xon=$(echo "Continue\\nExit" | slmenu -i -p "$xprompt")
	if [ "$xom" = "continue" ]; then
		echo "epic"
	elif [ "$xom" = "exit" ]; then
		while [ "$xom" = "$xom" ]; do
			error
		done

	fi
}

locale() {
	rgs=$(ls /usr/share/zoneinfo)
	clear
	echo "Please choose a region from this list"
	rg=$(echo "$rgs" | slmenu -l 10 -p "Choose a region")
	cts=$(ls /usr/share/zoneinfo/"$rg")
	clear
	echo "Please choose a city that has the same time zone as yours."
	ct=$(echo "$cts" | slmenu -l 10 -p "Choose a city")
	ln -sf /usr/share/zoneinfo/"$rg"/"$ct" /etc/localtime
	hwclock --sync

	clear
	echo "Please uncoomment 'en_US.UTF-8 UTF-8' and other locals you may need"
	nxt
	nvim /etc/locale.gen
	locale-gen
}

bootmanager() {
	if [ "$auto" = "Configue partitions" ]; then
		clear
		echo "SAI automatically installs GRUB as it's boot manager, would you like to continue with this or skip?"
		grb=$(echo "Install Grub\nSkip" | slmenu -p "Install or Skip")
		if [ "$grb" = "Install Grub" ]; then
			clear
			if [ "$bs" = "non EFI" ]; then
				grub-install "$cdrive"
			elif [ "$bs" = "EFI" ]; then
				grub-install --target=x86_64-efi --bootloader-id=grub-uefi --recheck
			fi
			mkinitcpio -p grub
			grub-mkconfig -o /boot/grub/grub.cfg
		fi
	elif [ "$auto" = "Nuke and auto reinstall" ]; then
		clear
		echo "SAI automatically installs GRUB as it's boot manager, if you would not like to install grub, "
		echo "but install a different boot manager outside of LPI, select Exit, if not, continue."
		grb=$(echo "Install Grub\nSkip" | slmenu -p "Install or Skip")
		if [ "$grb" = "Install Grub" ]; then
			if [ "$bs" = "non EFI" ]; then
				grub-install "$cdrive"
			elif [ "$bs" = "EFI" ]; then
				grub-install --target=x86_64-efi --bootloader-id=grub-uefi --recheck
			fi
			mkinitcpio -p grub
			grub-mkconfig -o /boot/grub/grub.cfg
		fi
	fi
}

getadduserroot() {
	clear
	echo "Would you like to create a user?"
	cu=$(echo "Create User\nSkip" | slmenu -p "Create User?")
	if [ "$cu" = "Create User" ]; then
		clear
		name=$(echo "" | slmenu -p "Please enter the name of your new user")
		while ! echo "$name" | grep "^[a-z_][a-z0-9_-]*$" >/dev/null 2>&1; do
			clear
			echo "Username not valid. Give a username beginning with a letter, with only lowercase letters, - or _."
			name=$(echo "" | slmenu -p "Please type a valid username")
		done
		clear
		echo "Please enter a password for the user"
		passwd "name"
	fi
	clear
	echo "Would you like to set a root password"
	srp=$(echo "Set Root Password\nSkip" | slmenu -p "Set Root Password?")
	if [ "$srp" = "Set Root Password" ]; then
		clear
		passwd root
	fi

}

sudoers() {
	clear
	echo "Would you like to edit /etc/sudoers file? If so, your new user is in group wheel"
	es=$(echo "Yes\\nNo" | slmenu -p "Edit /etc/sudoers?")
	if [ "$es" = "Yes" ]; then
		nvim /etc/sudoers
	fi
}

wificonfig() {
	clear
	echo "Would you like to enable NetworkManager?"
	en=$(echo "Yes\\nNo" | slmenu -p "Enable NetworkManger?")
	if [ "$en" = "Yes" ]; then
		pacman --noconfirm -Syu networkmanager wireless_tools wpa_supplicant
		systemctl enable NetworkManager.service
	fi
}

xorgpackages() {
	clear
	echo "Would you like to install the needed packages for a desktop enviroment / window manager? | Xorg packages"
	xpack=$(echo "Install\nSkip" | slmenu -p "Would you like to install?")
	if [ "$xpack" = "Install" ]; then
		pacman --noconfirm -Sy xorg-server xorg-xinit xorg-xbacklight xwallpaper compton
	fi
}

### THE ACTUAL SCRIPT ###

# Generate the locale and get local time configured
locale || error "User Exited."

# Ask if grub should be installed or if they want to install something else
bootmanager

# Get username and password for the new user, get the root password, set the root passwor, and make the new account
getuserandpass || error "User Exited."
adduserandpass || error "User Exited."

# Ask if they would like to edit /etc/sudoers file
sudoers || error "User Exited."

# Ask if they would like to enable networkmanager
wificonfig || error "User Exited."

# Ask if they would like to download xorg packages
xorgpackages || error"User Exited."
