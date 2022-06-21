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
    sudo apt install -y git openssh-server snmpd snmp libsnmp-dev wondershaper

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

## Restoring an Access Server

In the event an access server fails, a spare can be restored with the state of the
failed unit provided you have a recent state backup of the failed unit.

A state backup is performed with the command:

    sudo ./dmc-access-mgr -s state-server1.tar.gz

This should be done after initial install and each time a new gateway is added. The
resultant state archive should be stored off device somewhere safe as it contains
the cryptographic keys required to create gateways and encrypt sessions.

On the spare unit install Ubuntu as described in the section
[OS Install on Qotom](#os-install-on-qotom).

AFter installed the OS, updating the software packages and installing the necessary
additional packages, copy the saved state archive to the spare unit (IP addresses will
vary):

    scp state-server1.tar.gz dali@192.168.86.114:

Clone the DmcAccessServer repo.

    git clone https://github.com/Cogosense/DmcAccessServer
    cd DmcAccessServer

Extract the state archive and restore it:

    tar xf ../state-server1.tar.gz
    sudo ./dmc-access-mgr -R

This results in the  following outputs:

    Created symlink /etc/systemd/system/multi-user.target.wants/openvpn-iptables.service → /etc/systemd/system/openvpn-iptables.service.
    Created symlink /etc/systemd/system/multi-user.target.wants/openvpn-server@server.service → /lib/systemd/system/openvpn-server@.service.
    info: reboot server to complete recovery, note management IP may change

The server should now be rebooted to apply the changes. The reboot is manual to ensure
the recovery command completes without losing network connectivity. After rebooting,
the management IP may change and you may need to switch the network connection from
port 1 to port 2.

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

## Operations and Maintenance Procedures

### Remote Access

### SNMPv3

All gateways and servers have SNMPv3 enabled with standard IETF MIB descriptions. The
default credentials for connecting are:

- Username: dali
- Password: dali1234

But these can be overridden when the VPN server is setup using the __dmc-access-mgr__
script. The same server SNMP authentication credentials are used for every gateway
configuration that is created on the server.

### SSH Credentials

The command line can be accessed via SSH.  All servers and gateways use the same
credentials:

- Username: dali
- Password: dali1234

### SSH Command line Access To VPN Server from DMC

The VPN server can be accessed from the DMC at the IPv6 address of port 1 on the
Qotom unit.

    ssh dali@<port1_ipv6_addr>%lanbr0

### SSH Command line Access To VPN Server from Any VPN gateway

The server has a fixed IPv4 VPN address of 10.8.0.1. From any gateway, provided the VPN
is connected, it is possible to connect via SSH to the VPN server with the command:

    ssh dali@10.8.0.1

### SSH Command line Access To VPN gateway from VPN Server

First login to the VPN server using SSH.

Each gateway is allocated an IP address in the 10.8.0..0/24 network, starting with
10.8.0.2 as the first gateway. If the gateways have been numbered sequentially, then
the fourth octet of the IP address will be the gateway number+1. i.e. to connect to
_gateway1_, the command is:

    ssh dali@10.8.0.2

If the gateway numbering and IP address assignment have become non consecutive for
any reason, a gateway name can be mapped to an IP by referring to the file
_/etc/openvpn/ccd/{gateway_name}_.

    dali@vpnserver:~$ cat /etc/openvpn/ccd/gateway1
    ifconfig-push 10.8.0.2 255.255.255.0

### SSH Access via Port 2

Both VPN server and VPN gateway units support direct SSH access via port 2. The
IPv6 address of port 2 is required to access the command line in this manner.

Directly connect the LAN port of a laptop or other machine to port 2 of the
Qotom unit. Then using putty or a SSH command line to connect to the Qotom.

    ssh dali@{ipv6_addr_port_2}%ifname|ifindex

Where __ifname__ is the name of the connected interface or __ifindex__ is the
index of the connected interface. For example:

    ssh dali@fe80::2e0:4cff:fe83:ed0%eth0
    ssh dali@fe80::2e0:4cff:fe83:ed0%15

WHere __fe80::2e0:4cff:fe83:ed0__ is the ipv6 link local address of the port 2
interface.

### Listing all IPv6 Link Local Addresses

The IPv6 link local addresses should be recorded for deployed units to facilitate
ease of future management.

    dali@vpnserver:~$ ip addr show dev enp1s0
    2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
        link/ether 00:e0:4c:83:0e:ce brd ff:ff:ff:ff:ff:ff
        inet 10.11.7.85/24 brd 10.11.7.255 scope global enp1s0
           valid_lft forever preferred_lft forever
        inet6 fe80::2e0:4cff:fe83:ece/64 scope link
           valid_lft forever preferred_lft forever

The device names for ports 1,2,3 and 4 are enp1s0, enp2s0, enp3s0 and enp4s0 respectively.

### Check Connectivity of Server To Gateway.

Generally this cannot be done. The gateway is usually behind a firewall and a NAT device. On
the server check connectivity to an intermediate device such as the default gateway using the
ping command.

Incoming connections can be monitored by watching the log file _/var/log/openvpn/openvpn.log_

    dali@vpnserver:~$ sudo tail -f /var/log/openvpn/openvpn.log
    [sudo] password for dali:
    gateway2/10.35.1.2:40411 peer info: IV_PROTO=2
    gateway2/10.35.1.2:40411 peer info: IV_LZ4=1
    gateway2/10.35.1.2:40411 peer info: IV_LZ4v2=1
    gateway2/10.35.1.2:40411 peer info: IV_LZO=1
    gateway2/10.35.1.2:40411 peer info: IV_COMP_STUB=1
    gateway2/10.35.1.2:40411 peer info: IV_COMP_STUBv2=1
    gateway2/10.35.1.2:40411 peer info: IV_TCPNL=1
    gateway2/10.35.1.2:40411 Outgoing Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
    gateway2/10.35.1.2:40411 Incoming Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
    gateway2/10.35.1.2:40411 Control Channel: TLSv1.3, cipher TLSv1.3 TLS_AES_256_GCM_SHA384, 2048 bit RSA

The current status of the VPN service can be checked using the _systemctl status_ command:

    dali@vpnserver:~$ systemctl status openvpn-server@server.service
    ● openvpn-server@server.service - OpenVPN service for server
         Loaded: loaded (/lib/systemd/system/openvpn-server@.service; enabled; vendor preset: enabled)
         Active: active (running) since Fri 2022-04-29 17:11:31 PDT; 1 months 22 days ago
           Docs: man:openvpn(8)
                 https://community.openvpn.net/openvpn/wiki/Openvpn24ManPage
                 https://community.openvpn.net/openvpn/wiki/HOWTO
       Main PID: 1005 (openvpn)
         Status: "Initialization Sequence Completed"
          Tasks: 1 (limit: 9257)
         Memory: 4.3M
         CGroup: /system.slice/system-openvpn\x2dserver.slice/openvpn-server@server.service
                 └─1005 /usr/sbin/openvpn --status /run/openvpn-server/status-server.log --status-version 2 --suppress-timestamps --config se>

    Apr 29 17:11:31 vpnserver systemd[1]: Starting OpenVPN service for server...
    Apr 29 17:11:31 vpnserver systemd[1]: Started OpenVPN service for server.

### Soft Restart of VPN server

Via the SSH command line a VPN restart can be initiated using the _systemctl restart_ command. This will drop all
VPN connections, the gateways will attempt to reestablish the connection every 5 minutes after the connection drops.

    dali@vpnserver:~$ sudo systemctl restart openvpn-server@server.service

### Status of Gateway Connections on the Server

The openvpn server can dump status to the system log file by sending the openvpn process a SIGUSR2 signal. Use
the __pkill__ ,__cat__, and __perl__ commands to view the current VPN connection status:

    sudo pkill -SIGUSR2 openvpn
    sudo cat /var/log/openvpn/openvpn.log | perl -pne '/^TITLE..^END/'

The output will look similar to the following:

    TITLE>,OpenVPN 2.4.7 x86_64-pc-linux-gnu [SSL (OpenSSL)] [LZO] [LZ4] [EPOLL] [PKCS11] [MH/PKTINFO] [AEAD] built on Jul 19 2021
    TIME,Tue Jun 21 11:37:52 2022,1655836672
    HEADER,CLIENT_LIST,Common Name,Real Address,Virtual Address,Virtual IPv6 Address,Bytes Received,Bytes Sent,Connected Since,Connected Since (time_t),Username,Client ID,Peer ID
    CLIENT_LIST,gateway2,10.35.1.2:45831,10.8.0.3,,22114083,6293839,Tue Jun 21 11:20:05 2022,1655835605,UNDEF,0,0
    HEADER,ROUTING_TABLE,Virtual Address,Common Name,Real Address,Last Ref,Last Ref (time_t)
    ROUTING_TABLE,10.8.0.3,gateway2,10.35.1.2:45831,Tue Jun 21 11:37:52 2022,1655836672
    GLOBAL_STATS,Max bcast/mcast queue length,1
    END

The status output starts with the word __TITLE__ and ends with the word __END__. The __CLIENT_LIST__ line will show the connected gateways.

### Check Connectivity of Gateway To Server.

Log into the VPN gateway.

Check connectivity to VPN server:

First try the VPN server tunnel endpoint address:

    dali@vpngateway2:~$ ping 10.8.0.1
    PING 10.8.0.1 (10.8.0.1) 56(84) bytes of data.
    64 bytes from 10.8.0.1: icmp_seq=1 ttl=64 time=1.17 ms
    64 bytes from 10.8.0.1: icmp_seq=2 ttl=64 time=1.07 ms
    64 bytes from 10.8.0.1: icmp_seq=3 ttl=64 time=1.24 ms

A response means the VPN connection is up and functioning correctly. If there is no response
the connectivity to the VPN server must be checked.

First stop the VPN gateway, the service name is _openvpn@{gateway_name}.service_, so for the
gateway named __gateway2__, the command would be::

    sudo systemctl stop openvpn@gateway2.service

Find the VPN server address:

    dali@vpngateway2:~$ grep '^remote ' /etc/openvpn/gateway2.conf
    remote 10.35.1.221 1194

Ping the server:

    ping 10.35.1.221

No response from the server indicates an intervening network issue that should be rectified.

After checking the server connectivity, restart the VPN service:

    sudo systemctl start openvpn@gateway2.service

Outgoing connection attempts can be monitored by watching the system logs:

    dali@vpngateway2:~$ tail -f /var/log/syslog | grep ovpn
    Jun 14 03:17:03 vpngateway2 ovpn-gateway2[731]: Incoming Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
    Jun 14 03:17:03 vpngateway2 ovpn-gateway2[731]: Control Channel: TLSv1.3, cipher TLSv1.3 TLS_AES_256_GCM_SHA384, 2048 bit RSA
    Jun 14 04:17:02 vpngateway2 ovpn-gateway2[731]: TLS: tls_process: killed expiring key
    Jun 14 04:17:02 vpngateway2 ovpn-gateway2[731]: VERIFY OK: depth=1, CN=ChangeMe

or by using _systemctl status_

    dali@vpngateway2:~$ systemctl status openvpn@gateway2.service
    ● openvpn@gateway2.service - OpenVPN connection to gateway2
         Loaded: loaded (/lib/systemd/system/openvpn@.service; enabled-runtime; vendor preset: enabled)
         Active: active (running) since Thu 2022-06-16 10:07:25 PDT; 5 days ago
           Docs: man:openvpn(8)
                 https://community.openvpn.net/openvpn/wiki/Openvpn24ManPage
                 https://community.openvpn.net/openvpn/wiki/HOWTO
       Main PID: 728 (openvpn)
         Status: "Initialization Sequence Completed"
          Tasks: 1 (limit: 9276)
         Memory: 2.6M
         CGroup: /system.slice/system-openvpn.slice/openvpn@gateway2.service
                 └─728 /usr/sbin/openvpn --daemon ovpn-gateway2 --status /run/openvpn/gateway2.status 10 --cd /etc/openvpn --script-security >

    Jun 21 09:24:18 vpngateway2 ovpn-gateway2[728]: Control Channel: TLSv1.3, cipher TLSv1.3 TLS_AES_256_GCM_SHA384, 2048 bit RSA
    Jun 21 10:24:17 vpngateway2 ovpn-gateway2[728]: VERIFY OK: depth=1, CN=ChangeMe
    Jun 21 10:24:17 vpngateway2 ovpn-gateway2[728]: VERIFY KU OK
    Jun 21 10:24:17 vpngateway2 ovpn-gateway2[728]: Validating certificate extended key usage
    Jun 21 10:24:17 vpngateway2 ovpn-gateway2[728]: ++ Certificate has EKU (str) TLS Web Server Authentication, expects TLS Web Server Authen>
    Jun 21 10:24:17 vpngateway2 ovpn-gateway2[728]: VERIFY EKU OK
    Jun 21 10:24:17 vpngateway2 ovpn-gateway2[728]: VERIFY OK: depth=0, CN=server
    Jun 21 10:24:17 vpngateway2 ovpn-gateway2[728]: Outgoing Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
    Jun 21 10:24:17 vpngateway2 ovpn-gateway2[728]: Incoming Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
    Jun 21 10:24:17 vpngateway2 ovpn-gateway2[728]: Control Channel: TLSv1.3, cipher TLSv1.3 TLS_AES_256_GCM_SHA384, 2048 bit RSA

### Soft Restart of VPN gateway

Via the SSH command line a VPN restart can be initiated using the _systemctl restart_ command. This will drop the
VPN connection, the gateway will attempt to reestablish the connection immediately and then every 5 minutes after the connection drops.

    dali@vpngateway2:~$ sudo systemctl restart openvpn@gateway2.service

The gateway can safely be restarted using this command when logged in over the VPN connection from the VPN server via port 1.
The current connection should be preserved.

### Hard reboot of VPN gateway

Via an SSH connection reboot the gateway:

    sudo reboot

This will drop the connection. A connection can be reestablished to the gateway within 3-5 minutes.

## Simulating Slow Links on Fast Networks

The main use case for the DMC Access Server usually involves creating a transport
tunnel across a slower legacy network. The __wondershaper__ tool can be used to
shape the traffic characteristics on the WAN interfaces of the gateway for traffic
limiting on bandwidth constrained networks, or for testing slow network connections
over full speed ethernet networks.

For example to emulate an EDGE network:

    sudo wondershaper enp1s0 236 118

This will limit bandwidth on a gateway to 236kb/s download and 118kb/s upload,
apprx. the bandwidth in a 4 channel EDGE network.  To clear traffic shaping limits:

    sudo wondershaper clear enp1s0

If traffic shaping is required in production, a systemd service script would need
to be created on the gateway to apply the bandwidth limits at boot time. For example:

    cat < __EOF > /etc/systemd/system/dmc-gateway-traffic-shaping.service
    [Unit]
    Before=network.target
    [Service]
    Type=oneshot
    ExecStart=wondershaper enp1s0 236 118
    ExecStop=wondershaper clear enp1s0
    RemainAfterExit=yes
    WantedBy=multi-user.target
    __EOF
    systemctl enable --now dmc-gateway-traffic-shaping.service

This is not currently part of the gateway setup as the use of traffic shaping beyond
lab testing is currently not known.
