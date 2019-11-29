#!/bin/bash
Col_Red='\033[1;31m'
Col_White='\033[1;37m'
Col_Default='\033[0;39m'
Col_Green='\033[1;32m'
Col_Cyan='\033[1;36m'

does_droplet_exist() {
    if [ "$(docker-machine ls -q $1 | grep $1)" ];
    then
        # 0 = true
        return 0
    else
        # 1 = false
        return 1
    fi
}

echo -e "${Col_White}DigitalOcean CTFd docker deployment 1.0"
echo -e "${Col_Default}------------------------------"

# Check whether docker-machine exists
if ! [ -x "$(command -v docker-machine)" ];
then
    echo -e "${Col_Red}docker-machine not found. Make sure Docker is installed properly.${Col_Default}."
    exit 1
fi

echo -e "${Col_Cyan}Listing docker machines:${Col_Default}"
docker-machine ls

# Prompt for the docker image
echo -n -e "${Col_White}Docker image [ctfd/ctfd:latest]: ${Col_Default}"
read docker_image
docker_image=${docker_image:-ctfd/ctfd}

# Prompt droplet specifications
echo -e "\n${Col_Cyan}Provide the details for the new Droplet:"
echo -n -e "${Col_White}Droplet name [CTFd]: ${Col_Default}"
read droplet_name
droplet_name=${droplet_name:-CTFd}

# Droplet name should not exist yet
if does_droplet_exist ${droplet_name};
then
    echo -e "${Col_Red}Droplet with name '${droplet_name}' already exists${Col_Default}"
    exit 1
fi

# Prompt for the Droplet size
echo -n -e "${Col_White}Droplet size [s-1vcpu-1gb]: ${Col_Default}"
read droplet_size
droplet_size=${droplet_size:-s-1vcpu-1gb}

# Prompt for the CTFd Dashboard port
echo -n -e "${Col_White}CTFd dashboard port [80]: ${Col_Default}"
read dashboard_port
dashboard_port=${dashboard_port:-80}

while [ -z "$access_token" ]
do
    echo -n -e "${Col_White}DigitalOcean Personal access token: ${Col_Default}"
    read access_token
done

# Final check and confirmation
echo -e "${Col_White}Droplet name: '$droplet_name'"
echo "Size: " $droplet_size
echo "Port: " $dashboard_port
echo -n -e "Create a new droplet with these parameters? [Y/n]: ${Col_Default}"
read proceed
proceed=${proceed:-Y}
shopt -s nocasematch

if [[ $proceed != "Y" ]]
then
    echo -e "${Col_Red}aborted.${Col_Default}"
    exit 1
fi

# Create the droplet
echo -e "${Col_Cyan}Creating droplet $droplet_name${Col_Default}"
docker-machine create --digitalocean-size $droplet_size --driver digitalocean --digitalocean-access-token $access_token $droplet_name
if ! does_droplet_exist $droplet_name;
then
    echo -e "${Col_Red}Droplet '$droplet_name' not found. Installation failed. Check your DigitalOcean dashboard for more details${Col_Default}"
    exit 1
fi

# Get the Droplet's IP address
ip_address=$(docker-machine ip ${droplet_name})
echo -e "\n${Col_Green}Droplet successfully created. IP Address: $ip_address ${Col_White}"

# Set the docker-machine environment parameters according to the newly created droplet
echo -e "${Col_Cyan}Connecting to the new droplet${Col_Default}"
eval $(docker-machine env $droplet_name)

# Run the docker container
echo -e "${Col_Cyan}Starting the CTFd docker container${Col_Default}"
docker run -d -p $dashboard_port:8000 $docker_image

# Done
echo -e "\n${Col_White}You can now connect to your dashboard on http://$ip_address:$dashboard_port"
echo -e "${Col_Green}done.${Col_Default}"
