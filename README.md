Installing Remote Gateway

The Qotom Q1904GN comes with no OS installed and only an AMI BIOS.

Plug in VGA, and USB keyboard and mouse. Plug in the Ubuntu USB installation media.

Plug network port 1 into a LAN for the install and update phases.

Plug in the power. Hit the F2 key while the AMI bios is starting. Then select Ubuntu
from the boot menu.

In the Ubuntu installation, select the option to erase and reformat the internal SSD
and then select the minimal install option.

Set a user name.

On install completion reboot the machine and remove the USB media.

Reboot and login, start a terminal and do a software update:

    sudo apt -y upgrade

Clone this repo:

    git clone https://github.com/Cogosense/OpenvpnServer

Perform the initial setup of the OpenVPN server. You will need the network address of
the protected network (the network that connects the controller to the VPN server).



