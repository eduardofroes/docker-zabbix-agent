#!/bin/sh
set -e

if [ -z "$ZBX_SERVER_HOST" ]; then
    SERVERHOST="0.0.0.0\/0"
    echo "Server Host environment variable is empty, using generated server host "
else
    echo "Server Host=$ZBX_SERVER_HOST"
    SERVERHOST="${ZBX_SERVER_HOST////\\/}"
fi

if [ -z "$ZBX_HOSTNAME" ]; then
    MACHINEID=$(cat /etc/machine-id)
    HOST="$METADATA-$MACHINEID"
    echo "Agent Host name environment variable is empty, using generated value $HOST"
else
    HOST="$ZBX_HOSTNAME"
    echo "Agent Host Name=$ZBX_HOSTNAME"
fi

if [ -z "$ZBX_ACTIVESERVERS" ]; then
    ACTIVESERVERS=$ZBX_SERVER_HOST+":10051"
    echo "Active Servers environment variable is empty, using generated value $ACTIVESERVERS"
else
    ACTIVESERVERS="$ZBX_ACTIVESERVERS"
    echo "Active Servers=$ZBX_ACTIVESERVERS"
fi

if [ -z "$ZBX_ACTIVE_ALLOW" ]; then
    ALLOWROOT="true"
    echo "Allow Root environment variable is empty, using generated value $ALLOWROOT"
else
    ALLOWROOT=$ZBX_ACTIVE_ALLOW
    echo "Allow Root=$ACTIVEALLOW"
fi

if [ -z "$ZBX_STARTAGENTS" ]; then
    STARTAGENTS="3"
    echo "Allow Root environment variable is empty, using generated value $STARTAGENTS"
else
    STARTAGENTS="$ZBX_STARTAGENTS"
    echo "Start Agents=$STARTAGENTS"
fi

if [ -z "$ZBX_DEBUGLEVEL" ]; then
    DEBUGLEVEL="4"
    echo "Debug Level environment variable is empty, using generated value $DEBUGLEVEL"
else
    DEBUGLEVEL="$ZBX_DEBUGLEVEL"
    echo "Debug Level=$DEBUGLEVEL"
fi

if [ -z "$ZBX_ENABLEREMOTECOMMANDS" ]; then
    ENABLEREMOTECOMMANDS="1"
    echo "Enable Remote Commands environment variable is empty, using generated value $ENABLEREMOTECOMMANDS"
else
    ENABLEREMOTECOMMANDS="$ZBX_ENABLEREMOTECOMMANDS"
    echo "Enable Remote Commands=$ENABLEREMOTECOMMANDS"
fi

if [ -z "$ZBX_LOGREMOTECOMMANDS" ]; then
    LOGREMOTECOMMANDS="1"
    echo "Log Remote Commands environment variable is empty, using generated value $ZBX_LOGREMOTECOMMANDS"
else
    LOGREMOTECOMMANDS="$ZBX_LOGREMOTECOMMANDS"
    echo "Log Remote Commands=$LOGREMOTECOMMANDS"
fi

echo "StartAgents=$STARTAGENTS" >> /etc/zabbix/zabbix_agentd.conf
echo "DebugLevel=$DEBUGLEVEL" >> /etc/zabbix/zabbix_agentd.conf
echo "EnableRemoteCommands=$ENABLEREMOTECOMMANDS" >> /etc/zabbix/zabbix_agentd.conf
echo "LogRemoteCommands=$LOGREMOTECOMMANDS" >> /etc/zabbix/zabbix_agentd.conf
sed -i "s/^Server\=127.0.0.1/Server\=0.0.0.0\/0/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/^ServerActive\=127.0.0.1/ServerActive\=$ACTIVESERVERS/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/^LogFile\=.*/LogFile=\/proc\/self\/fd\/1/" /etc/zabbix/zabbix_agentd.conf
echo "Hostname=$HOST" >> /etc/zabbix/zabbix_agentd.conf
echo "HostMetadata=$METADATA" >> /etc/zabbix/zabbix_agentd.conf
echo "AllowRoot=$ALLOWROOT" >> /etc/zabbix/zabbix_agentd.conf


if [ ! -z "$PSKKey" ]; then
    # Check key validity (if it's not valid zabbix_agentd exits abnormally without a decent error output)
    if [[ ! "$PSKKey" =~ ^[a-f0-9]+$ ]]; then
        echo "PSKKey value $PSKKey contains invalid characters (must be a hexadecimal string)"
        exit 1
    fi
    if [ ${#PSKKey} -lt 32 -o ${#PSKKey} -gt 512 ]; then
        echo "PSKKey value $PSKKey is invalid length, must be between 32 and 512 characters"
        exit 1
    fi

    mkdir -p /etc/zabbix/tls
    echo "$PSKKey" > /etc/zabbix/tls/zabbix.psk
    chmod 600 /etc/zabbix/tls/zabbix.psk
    echo "TLSPSKFile=/etc/zabbix/tls/zabbix.psk" >> /etc/zabbix/zabbix_agentd.conf

    if [ -z "$PSKIdentity" ]; then
        echo "PSKIdentity environment variable is empty even though PSKKey environment variable is set"
        exit 1
    fi

    echo "TLSPSKIdentity=$PSKIdentity" >> /etc/zabbix/zabbix_agentd.conf
    echo "TLSAccept=psk" >> /etc/zabbix/zabbix_agentd.conf
    echo "TLSConnect=psk" >> /etc/zabbix/zabbix_agentd.conf
fi

zabbix_agentd -f
