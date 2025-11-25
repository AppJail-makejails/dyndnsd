#!/bin/sh

do_users=true

env | grep -Ee '^DYNDNSD_USERS=.+' | while IFS= read -r env; do
    users=`printf "%s" "${env}" | cut -s -d= -f2-`

    for user in ${users}; do
        if printf "%s" "${user}" | grep -qEe '^[^:]+:[^:]+$'; then
            password=`printf "%s" "${user}" | cut -s -d= -f2-`
            user=`printf "%s" "${user}" | cut -s -d= -f1`
        else
            password="${user}"
        fi

        if ! printf "%s" "${user}" | grep -qEe '^[a-zA-Z0-9][a-zA-Z0-9_]$'; then
            continue
        fi

        if ${do_users}; then
            printf "%s\n" "users:"

            do_users=false
        fi

        printf "\t%s:\n" "${user}"
        printf "\t\tpassword: \"%s\"\n" "${password}"

        do_hosts=true

        env | grep -Ee "^DYNDNSD_HOSTS_${user}=.+" | while IFS= read -r env; do
            hosts=`printf "%s" "${env}" | cut -s -d= -f2-`

            for host in ${hosts}; do
                if ! printf "%s" "${host}" | grep -qEe '^[a-zA-Z0-9]([-a-zA-Z0-9]{0,61}[a-zA-Z0-9])?$'; then
                    continue
                fi

                if ${do_hosts}; then
                    printf "\t\thosts:\n"

                    do_hosts=false
                fi

                printf "\t\t\t- %s\n" "${host}"
            done
        done
    done
done >> /dyndnsd.yml
