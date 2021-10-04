# Run ./dmc-access-server -C to create a new
# configuration file.

# WANIF
# the interface name of the WAN interface

WANIF=

# LANIFS
# a list of comma delimited interface names on the LAN side
# All these interfaces will be joined into a bridge and can
# be used to connect to individual DMC's or multiple links
# to a single DMC

LANIFS=

#
# PROTO
# Set static for statically configured WAN interface
# Set dhcp for dynamically configured WAN interface
#
PROTO=

#
# * ADDRESS - static IPv4 address of the WAN interface
# * NETMASK - netmask of the network connected to the WAN interface
# * GATEWAY - IP address of default gateway on the WAN interface
# * NAMESERVERS - IP address of the DNS servers, a comma seperated list
#
# If PROTO is static the following parameters are required:
# If PROTO is dynamic and the above parameters are set, the automatic
# detection features of this script are disabled and the manually
# configured values are used.

ADDRESS=
NETMASK=
GATEWAY=
NAMESERVERS=

#
# ACTIVATE_WANIF
# Activate the WAN interface prior to proceeding with
# configuration. This is required if the WAN is required
# to connect to the internet. (If using port 2 to connect
# this option should be set to no.)

ACTIVATE_WANIF=$activate_wanif

#
# PUBLIC_ADDRESS
# The public IP address can be automatically determined if the server
# is connected to the network and the Internet is accessible. Otherwise
# the public IP address can be configured. Configuring a public IP
# address disables the automatic detection.

PUBLIC_ADDRESS=

#
# PROTOCOL
# The VPN transport protocol, either tcp or udp

PROTOCOL=

#
# PORT
# The VPN server port number

PORT=

#
# DNS
# The gateway DNS option
#    1) Current system resolvers
#    2) Google
#    3) 1.1.1.1
#    4) OpenDNS
#    5) Quad9
#    6) AdGuard

DNS=$dns

#
# CLIENT
# The name of the first client gateway to be created

CLIENT=

#
# SNMP_USER
# The user name to use for SNMPv3 authentication

SNMP_USER=

#
# SNMP_PASSWORD
# The user password to use for SNMPv3 authentication

SNMP_PASSWORD=
