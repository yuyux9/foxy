#!/usr/bin/env bash

# ----------------------------------
#-COLORZ-
# ----------------------------------
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'

#~CHECK FOR YQ~
if ! command -v yq &> /dev/null; then
    wget https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 -O /usr/bin/yq
    chmod +x /usr/bin/yq
fi
#~CHECK FOR FILE WITH DIR~
if [ -f "saved_directory.txt" ]; then
    DIRECTORY=$(<saved_directory.txt)
fi

# ~WEB-SERVICE TYPE CHECK~
check_web_service() {
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$1)
    if [ $response -eq 200 ]; then
        echo "Web Service"
    else
        echo "Unknown Service"
    fi
}

# ~NON-WEB-SERVICE TYPE CHECK~
check_nonweb_service() {
    if [ -z "$1" ]; then
        echo "Port number is missing."
        return
    fi
    if nc -z localhost $1 </dev/null; then
        echo "Non-Web Service"
    else
        echo "Unknown Service"
    fi
}

# ~OUTPUT SERVICE NAME AND DIRS IN TABLE~
show_services() {
    clear
    echo "Services:"
    echo "-----------------------------------------"
    for service in $(find $DIRECTORY -mindepth 1 -maxdepth 1 -type d); do
        service_name=$(basename $service)
        docker_compose_file=""

        for file in "$service/docker-compose.yml" "$service/docker-compose.yaml" "$service/compose.yml" "$service/compose.yaml"; do
            if [ -f "$file" ]; then
                docker_compose_file=$file
                break
            fi
        done

        if [ ! -z "$docker_compose_file" ]; then
            port=$(cat "$docker_compose_file" | yq r - 'services.*.ports[0]' | cut -d':' -f1)
            if [ -n "$port" ]; then
                if curl -s localhost:$port >/dev/null 2>&1; then
                    service_type=$(check_web_service)
                    printf "Service Name: $service_name, Port: $port, Service Type: ${LIGHTBLUE}$service_type${NOCOLOR}"
                    echo " "
		            echo "http://vuln:$port"
                else
                    service_type=$(check_nonweb_service $port)
                    if [ "$service_type" != "Unknown Service" ] && [ "$service_type" != "Port number is missing" ]; then
                        printf "Service Name: $service_name, Port: $port, Service Type: ${YELLOW}$service_type${NOCOLOR}"
                        echo " "
			            echo "\`\`\`nc vuln $port \`\`\`"
                    else
                        printf "Service Name: $service_name, Port: $port, Service Type: ${RED}$service_type${NOCOLOR}"
                    fi
                fi
                echo
            else
                echo "Service Name: $service_name, Port number is missing"
                echo
            fi
        else
            echo "Service Name: $service_name, Docker Compose file not found"
            echo
        fi
    done
    echo "-----------------------------------------"
    echo
}


# ~ARCHIVE~
archive_services() {
    clear
    tar -czvf services_backup.tar.gz $DIRECTORY/*/
    printf "${GREEN}All services have been archived successfully.${NOCOLOR}"
}

# ~SAVE DIR~
save_directory() {
    echo $DIRECTORY > saved_directory.txt
    printf "${GREEN}Current directory has been saved.${NOCOLOR}"
}

# ~DELETE DATA ABOUT DIR~
delete_data() {
    rm -f saved_directory.txt
    printf "${GREEN}All saved data have been deleted.${NOCOLOR}"
}

# ~CHANGE DIR~
edit_directory() {
    read -p "Enter the new directory path: " new_directory
    DIRECTORY=$new_directory
    printf "${GREEN}Directory has been updated successfully.${NOCOLOR}"
}


# ~MAIN MENU~
while true; do
    clear
cat << "EOF"
                                                                   ,-,
                                                             _.-=;~ /_
                                                          _-~   '     ;.
                                                      _.-~     '   .-~-~`-._
                                                _.--~~:.             --.____88
                              ____.........--~~~. .' .  .        _..-------~~
                     _..--~~~~               .' .'             ,'
                 _.-~                        .       .     ` ,'
               .'                                    :.    ./
             .:     ,/          `                   ::.   ,'
           .:'     ,(            ;.                ::. ,-'
          .'     ./'.`.     . . /:::._______.... _/:.o/     Service Management Script
         /     ./'. . .)  . _.,'               `88;?88|                FOXY
       ,'  . .,/'._,-~ /_.o8P'                  88P ?8b
    _,'' . .,/',-~    d888P'                    88'  88|
 _.'~  . .,:oP'        ?88b              _..--- 88.--'8b.--..__
:     ...' 88o __,------.88o ...__..._.=~- .    `~~   `~~      ~-._ _.
`.;;;:='    ~~            ~~~                ~-    -       -   -
                                    [yuyu]
                                  [893crew~]
EOF
    echo "[ Service Management Script ]"
    echo "1. Show Services"
    echo "2. Archive Services"
    echo "3. Save Current Directory"
    echo "4. Delete All Saved Data"
    echo "5. Edit Directory"
    echo "6. Exit"
    read -p "" choice

    case $choice in
        1)
            show_services
            read -p "Press enter to continue..."
            ;;
        2)
            archive_services
            read -p "Press enter to continue..."
            ;;
        3)
            save_directory
            read -p "Press enter to continue..."
            ;;
        4)
            delete_data
            read -p "Press enter to continue..."
            ;;
        5)
            edit_directory
            read -p "Press enter to continue..."
            ;;
        6)
            echo "Exiting the script. Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose again."
            read -p "Press enter to continue..."
            ;;
    esac
done
