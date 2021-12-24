#!/bin/bash
currentpath=$(pwd)
echo inprogress>$currentpath/status.log
echo inprogress>$currentpath/info.log

username=$(cat $currentpath/input.properties | grep 'mysql_username'| cut -d '=' -f 2)
password=$(cat $currentpath/input.properties | grep 'mysql_user_password'| cut -d '=' -f 2)
rootpassword=$(cat $currentpath/input.properties | grep 'mysql_root_password'| cut -d '=' -f 2)
database=$(cat $currentpath/input.properties | grep 'database_name'| cut -d '=' -f 2)
port=$(cat $currentpath/input.properties | grep 'mysql_port'| cut -d '=' -f 2)
container_name=$(cat $currentpath/input.properties | grep 'container_name'| cut -d '=' -f 2)
defined_bridge_network_name=$(cat $currentpath/input.properties | grep 'defined_bridge_network_name'| cut -d '=' -f 2)

sudo mkdir -p /opt/$container_name

echo class yamlfilecreation::var { > $currentpath/puppetinput.properties
echo \$mysql_container_name = \"$container_name\" >> $currentpath/puppetinput.properties
echo \$mysql_container_port = \"$port\" >> $currentpath/puppetinput.properties
echo \$mysql_username = \"$username\" >> $currentpath/puppetinput.properties
echo \$mysql_user_password = \"$password\" >> $currentpath/puppetinput.properties
echo \$mysql_root_password = \"$rootpassword\" >> $currentpath/puppetinput.properties
echo \$mysql_dbname = \"$database\" >> $currentpath/puppetinput.properties
echo } >> $currentpath/puppetinput.properties

sudo cp $currentpath/puppetinput.properties $currentpath/yamlfilecreation/manifests/var.pp

#defined_bridge-network creation
sudo docker network ls | grep $defined_bridge_network_name >>$currentpath/error.log 2>&1

if [ $? == 0 ]; then
echo network "$defined_bridge_network_name" is already exist >>$currentpath/error.log 2>&1
else
sudo docker network create -d bridge $defined_bridge_network_name >>$currentpath/null.log 2>&1
echo network "$defined_bridge_network_name" is created >>$currentpath/error.log 2>&1
fi

sudo docker pull mysql:5.7.34 >>$currentpath/error.log 2>&1
sudo docker run -d --network $defined_bridge_network_name -v /opt/$container_name:/var/lib/mysql --name $container_name -e MYSQL_USER=$username -e MYSQL_PASSWORD=$password -e MYSQL_ROOT_PASSWORD=$rootpassword  -e MYSQL_DATABASE=$database -p $port:3306 mysql:5.7.34 >>$currentpath/error.log 2>&1
sleep 10
puppet apply -v -d --modulepath="$currentpath" -e "include yamlfilecreation" --logdest  $currentpath/puppeterror.log
sudo docker logs $container_name >>$currentpath/error.log 2>&1
sleep 1

if grep "error" "$currentpath/error.log" ; then 
        echo "failed" > $currentpath/status.log
        echo MySQL container Creation getting failed.Kindly find the error.log for more information > $currentpath/info.log
        exit 0
    fi
if grep "(err):" "$currentpath/puppeterror.log" ;then
        echo "failed" > $currentpath/status.log
        echo Container creation successfull & MySQL YAML Creation getting failed.Kindly find the error.log for more information > $currentpath/info.log
        exit 0
    fi
if grep "Error" "$currentpath/error.log" ; then
        echo "failed" > $currentpath/status.log
        echo MySQL container Creation getting failed.Kindly find the error.log for more information > $currentpath/info.log
	sudo rm -rf $currentpath/null.log > /dev/null
        exit 0
else
        echo "success" > $currentpath/status.log
        echo MySQL container and YAML has been created successfully > $currentpath/info.log
	sudo rm -rf $currentpath/null.log > /dev/null
fi
