# DMC Access Server Procedures

## Hardware Overview

The Qotom hardware used has 4 network interfaces and 4 USB interfaces, an
Intel Celeron J1900 Quad Core 2.0GHz CPU, 8 GB RAM and 128 GB of SSD
flash storage. The power consumption is 10W.

The interfaces are assigned as follows:

* NIC 1 - WAN interface connection to the modem or internet
* NIC 2 - Management Port
* NIC 3 - LAN interface bridged with NIC 4 connected to hdHost or to DMC
* NIC 4 - LAN interface bridged with NIC 3 connected to hdHost or to DMC

To do initial install connect a USB keyboard, USB mouse and a VGA monitor.

## BIOS Changes

Boot the Qotom into the BIOS by pressing the DEL key while the AMI BIOS banner
is displayed.

In the BIOS navigate to Advanced->ACPI Settings. Set the folling values:

Restore AC Power Loss = Last State
Enable Hibernation = Disabled
ACPI Sleep State = Suspend Disabled

Save and exit BIOS.

## OS Install on Qotom

This applies to both server and gateway machines.

Equipment needed:
1. Ubuntu 20.04 [USB installation media](https://ubuntu.com/tutorials/create-a-usb-stick-on-ubuntu#1-overview)
2. USB mouse, USB Keyboard and VGA monitor.
3. Network connection.

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
    sudo apt -y upgrade -y
    sudo apt install -y git openssh-server snmpd snmp libsnmp-dev

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
first gateway configuration will be created.

    Welcome to this Dali DMC Access Server installer!
    The network interfaces will be reconfigured first to use netplan and networkd
    This appears to be a Qotom network applicance
        interface 1 should be connected to the Internet/Modem
        interfaces 3 and 4 should be connected to the DMC
    Using WAN interface enp1s0
    Using DMC interface(s) enp3s0 enp4s0
    Activating WAN Interface before proceeding with configuration

    This server is behind NAT. What is the public IPv4 address or hostname?
    Public IPv4 address / hostname [23.16.15.59]: 

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
    Name [ateway]: gateway1

    Enter a user name for SNMPv3 monitoring:
    SNMP user name [dali]: 
    Using SNMP user name "dali" (on both server and gateways for both authentication and privacy)

    Enter a password for SNMPv3 monitoring:
    SNMP password [dali1234]: 
    Using SNMP password "dali1234" (on both server and gateways for both authentication and privacy)

    DMC Access Server installation is ready to begin.
    Press any key to continue...

### Access Server Notes

If the Access Server is running in a VM, the host OS must place the physical NIC associated
with the guest virtual interface toward the DMC into a promiscuous mode. The Access Server is
running a bridge device on this interface and requires that all packets received by the
network interface are delivered to the bridge for switching.

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

      /home/sysadmin/DmcAccessServer/state/gateways/install_gateway-8.shar

    Copy this file to the gateway and install it by running the command:

        chmod a+x install_gateway-8.shar
        sudo ./install_gateway-8.shar

This file needs to be copied to the gateway either by USB flash drive or by
a network connection.

## Installing A Remote Gateway

Now copy the gateway installer file created by the DMC access server
to the gateway and run it. (If a USB flash drive was used, the file may need to be
made executable again).

    sudo ./install_gateway1.shar

### Gateway Installion Notes

1. If the installer does not recognise the gateway hardware, it will not attempt
to install. The `-f` option to the installer will force an install attempt, but likely
the network configuration will not be correct afterwards.

2. If the installer detects that the gateway is already installed, it will not attempt
to install. The -d option can be use to perform an uninstalltion of the gateway. After
the gateway is uninstalled, the installation should succeed.

## Use of a Management Port

A management port is optional when the WAN port is set to use DHCP. When the WAN port
uses a static configuration, the management port is mandatory. This ensures there is
always the ability to connect to the VPN server unit.

Connection via a management port is achieved with a laptop running the Windows
[TFTPD](https://pjo2.github.io/tftpd64/) daemon to provide an IP address via DHCP.
Open TFTPD, direct connect a CAT6 cable between laptop and Qotom management port,
then use Putty to SSH into the IP address assigned.

## Creating a Standby Access Server

A cold standby DMC access server is supported. The configuration of the active DMC
access server is manually copied to the standby DMC access server and applied using
the steps described in this section.

Both servers must be reachable at the same public IP address. The switching of the
address mapping between the public IP and the DMC access IP address is outside the
scope of the DMC access server solution, this solution just assumes it will be
correctly handled.

Use the following procedures to establish a secondary standby DMC access server:

1. Create a primary and a secondary DMC access server using the process described in
the section __Initial Installation of the DMC Access Server__ in this document. All
questions in the setup wizard should be answered identically except for
__Which IPv4 address should be used?__, this can be different.

2. After each configuration change on the primary unit (adding or revoking a gateway),
run the following command:

    sudo ./dmc-access-mgr -s <IP ADDR OF STANDBY>

The command will package the state into a tarball and copy it to the standby. It then
prints the command to be run on the standby to restore the state.

3. Login to the standby DMC access server and run the command indicated in step 2, it
will be something like this:

    sudo ./dmc-access-mgr -r ~/state-2021-08-25T00-20-07-00.tar.gz

### Standby Access Server Notes

If the standby server is not accessible by IP, The state can be transfered by file,
modify the command to create the state archive to specify a file name instead.

    sudo ./dmc-access-mgr -s <TARFILENAME>

The tarfile can now be transferred using a USB drive or similar method. The procedure
to import the file on the standby side is the same.

## What Does The DMC Access Server Do?

The Dali DAS system uses an auto configured IPv6 link local network on the southbound
side of the DMC. In some cases, the DMC is deployed to a NOC remote from the antennae.
If the transport network between the NOC and the antenna site it not a contiguous IPv6
enabled local area network, then the antennae and the controller will not be able to
communicate.

The DMC Access Server and the Remote Gateway provide a mechanism to tunnel the IPv6
local area network across an intervening IPv6 or an IPv4 only network, including the
Internet if necessary.  The result is the ability to join non-contiguous networks into
a contiguous IPv6 LAN.

All communications are encrypted, all authentication is certificate based, requiring no
passwords. If an enabled gateway device is lost or compromised, it's associated
certificate can be revoked to disable the gateway permanently.

Data between the access server and the gateway is compressed to help performance across
low bandwidth links.

## How Does the DMC Access Server Work?

The DMC Access Server consists of two parts:

1. The Access Server that is usually located in a NOC, this is connected to the DMC.
2. The Remote Gateway, that is connected to the remote antenna system.

The Access Server consists of an OpenVPN server that creates an OpenVPN tunnel and a
GRETAP tunnel per configured gateway, The GRETAP tunnel is added as a member
of the bridge that incorporates the physical interface that is connected to the DMC.
THe management script in this repo is used to create an OVPN configuration file and a
NETPLAN configuration for a remote gateway. This is bundled into a self extracting
executable installer script. The management script also adds the associated GRETAP
tunnel into the Access Server bridge connected to the DMC.

The installer script is copied to the gateway device and executed. This creates an
automatic OpenVPN connection service and attaches the end of the GRETAP tunnel to
the OpenVPN assigned IP address. The GRETAP tunnel is then added to a bridge device
that incorporates the physical interfaces connected to the antenna system.

When the gateway is installed and powered on, it will automatically create a VPN
connection to the Access Server in the NOC. Once the connection is made, and the
remote IP address becomes available, the GRETAP tunnel will be established over the
VPN connection.

The bridges on the Access Server toward the DMC and on the Gateway toward the antenna
only support IPv6 addresses with scope `link`. Any IPv6 traffic received on either
bridge will be sent via the GRETAP tunnel to the other bridge. From the DMC or antenna
point of view, it looks to all practical intents and purposes that they are directly
connected. The gateway and the Access Server are essentially transparent.
