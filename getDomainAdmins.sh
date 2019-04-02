#!/bin/bash

function usage {
    echo "Usage:    $0 -h domainIP [-u user & -p password] [-d]"
    echo ""
    echo "Options:"
    echo "  -h  Domain IP"
    echo "  -u  Domain user"
    echo "  -p  Domain Password"
    echo "  -d  Add description for each user found"
    exit 1
}

IP=""
USERNAME=""
PASSWORD=""
DESC=false

while getopts "h:u:p:d" option
do
    case $option in
        h)
            IP=$OPTARG
            ;;
        u)
            USERNAME=$OPTARG
            ;;
        p)
            PASSWORD=$OPTARG
            ;;
        d)
            DESC=true
            ;;
        *)
            usage
            ;;
    esac
done
if [ $OPTIND -eq 1 ] || [ -z $IP ] || [[ ! -z $USERNAME && -z $PASSWORD ]] || [[ -z $USERNAME && ! -z $PASSWORD ]];then usage;fi

creds="$USERNAME%$PASSWORD"

function getRidsFrom {
    local queryRid="0x200"
    local groups=()
    local rids=$(rpcclient -c "querygroupmem $queryRid" -U "$creds" $IP | grep -o rid.*\\s | grep -o [0-9]*x[0-9a-z]*)
    for rid in $rids;do
        local username=$(rpcclient -c "queryuser $rid" -U "$creds" $IP | grep "User Name" | awk '{print $4}')
        local description=$(rpcclient -c "queryuser $rid" -U "$creds" $IP | grep "Description" | awk '{$1="";$2="";print $0}' | sed 's/^ *//')
        if [ -z $username ];then
            groups+=$rid
        elif [ $DESC = true ];then
            echo "$username -> $description"
        else
            echo $username
        fi
    done
    if [ -z $groups ];then
        return 0
    else
        for group in $groups;do
            getRidsFrom $group
        done
    fi
}

users=()
#user=$(rpcclient -c "queryuser 0x1f4" -U "$creds" $IP)
getRidsFrom "0x200"
