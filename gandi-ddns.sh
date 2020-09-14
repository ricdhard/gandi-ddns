#!/bin/bash

#echo -e "\n"$(date)

API_KEY=

ZONE_FQDN=
ZONE_RECS=
ZONE_TTL=3600
ZONE_UUID=

LOC_IP=""
LOC_LOG=""
touch $LOC_LOG
touch $LOC_LOG

IPV4_PUBLIC="$(wget https://ipecho.net/plain -O - -q ; echo)"
IPV4_PUBLIC_OLD="$(cat $LOC_IP)"

if [ -z $IPV4_PUBLIC ]
then
        echo "[$(date)] Public IP could not be determined - abort [ERROR]" >> $LOC_LOG
        exit 0
fi
if [ $IPV4_PUBLIC = $IPV4_PUBLIC_OLD ]
then
        echo "[$(date)] Public IP: $IPV4_PUBLIC - did not change, DNS records have not been updated [OK]" >> $LOC_LOG
        exit 0
fi

echo $IPV4_PUBLIC > $LOC_IP

update_records ()
{
        curl -D- -X PUT \
                -H "Content-Type: application/json" \
                -H "Authorization: Apikey $API_KEY" \
                -d "$records" \
                https://api.gandi.net/v5/livedns/domains/$ZONE_FQDN/records

        echo "[$(date)] Public IP: $IPV4_PUBLIC - changed from $IPV4_PUBLIC_OLD, DNS records have been updated [OK]" >> $LOC_LOG
}

generate_records ()
{
        rec_str=$ZONE_RECS
        rec_json='{"items":['
        IFS=',' read -a rec_arr <<< "$rec_str"
        for rec in "${rec_arr[@]}"
        do
                rec_json=${rec_json}'{
                "rrset_name":"'$rec'",
                "rrset_type":"A",
                "rrset_ttl":'$ZONE_TTL',
                "rrset_values":'"[\"$IPV4_PUBLIC\"]"'
                },'
        done
        records=${rec_json: : -1}"]}"
}

generate_records
update_records
