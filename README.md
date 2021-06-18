# DMC Access Server Procedures

## Initial Installation of the DMC Access Server

The DMC access server requires a minimum of two interfaces. One interface will be
used to host the VPN server and faces the public network, the other interface will
face the DMC.

To start installation checkout this repo to the VPN Access Server device
and start the DMC access manager configuration process.

    git clone https://github.com/Cogosense/DmcAccessServer
    cd DmcAccessServer
    sudo ./dmc-access-mgr

The first time the `dmc-access-mgr` tool is run the server will be setup and the
first gateway configuration be created.

    Welcome to this Dali DMC Access Server installer!
    Which interface is connected to the DMC?
    1) ens32
    2) ens33
    #?2

    Using interface ens33
    Is this correct? [yN]y

    Which IPv4 address should be used?
         1) 10.10.251.25
    IPv4 address [1]:

    This server is behind NAT. What is the public IPv4 address or hostname?
    Public IPv4 address / hostname [206.191.105.211]:

    Which protocol should DMC Access Server use?
       1) UDP (recommended)
       2) TCP
    Protocol [1]:

    What port should DMC Access Server listen to?
    Port [1194]:

    Select a DNS server for the gateways:
       1) Current system resolvers
       2) Google
       3) 1.1.1.1
       4) OpenDNS
       5) Quad9
       6) AdGuard
    DNS server [1]:

    Enter a name for the first gateway:
    Name [gateway]: gateway-1

    DMC Access Server installation is ready to begin.
    Press any key to continue...

## Gateway Installer Generation

A Gateway installation script for the first gateway is generated after the
initial server install.

On subsequent invocations the following actions can be performed:

    DMC Access Server is already installed.

    Select an option:
       1) Add a new remote gateway
       2) Revoke an existing remote gateway
       3) Remove DMC Access Server
       4) Exit
    Option:

Option 1 can be used to add more gateways.

After the gateway installation script is generated, the following message
if displayed.

    The install script for the remote gateway "gateway-8" is at:

      /home/sysadmin/DmcAccessServer/gateways/install_gateway-8.shar

    Copy this file to the gateway and install it by running the command:

        chmod a+x install_gateway-8.shar
        sudo ./install_gateway-8.shar

This file needs to be copied to the gateway either by USB flash drive or by
a network connection.

## Installing A Remote Gateway

Equipment needed:
1. Qotom Q1904GN computer.
2. Ubuntu 20.04 USB installation media
3. USB mouse, USB Keyboard and VGA monitor.
4. Network connection.

The Qotom Q1904GN comes with no OS installed and only an AMI BIOS.  Plug in a
VGA monitor, a USB keyboard and USB mouse. Plug in the Ubuntu USB installation
media and the network cable to network port 1.

Plug in the power and turn on the unit by pressing the recessed power button.  Hit
the F2 key while the AMI bios is starting. Then select Ubuntu from the boot menu.

In the Ubuntu installation, select the option to erase and reformat the internal SSD
and then select the minimal install option and set a user name.

When the install is complete reboot the machine and remove the USB installation
media.

Reboot and login, start a terminal and do a software update:

    sudo apt update
    sudo apt -y upgrade

Now copy the gateway installer file created by the DMC access server
to the gateway and run it. (If a USB flash drive was used, the file may need to be
made executable again).

    sudo ./install_gateway-8.shar

### Gateway Installion Notes

1. If the installation does not recognise the gateway hardware, it will not attempt
to install. The `-f` option to the installer will force an install attempt, but likely
the network configuration will not be correct afterwards.

2. If the installer detects that the gateway is already installed, it will not attempt
to install. The -d option can be use to perform an uninstalltion of the gateway. After
the gateway is uninstalled, the installation should succeed.


