port=1421
host=127.0.0.1
user=fisher

nc -z $host $port
success=$?
if [[ $success != 0 ]]; then echo "port $port empty on $host, cannot login" && exit; fi

ssh -p $port $user@$host
