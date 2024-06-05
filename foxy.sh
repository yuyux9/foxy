#!/usr/bin/env bash

#~INSTALL GUM~
echo " "
if ! command -v gum &> /dev/null
then
    gum style --foreground 2 "gum not found, installing gum..."
    sudo apt update && sudo apt install -y gum
    if ! command -v gum &> /dev/null
    then
        gum style --foreground 1 "Failed to install gum. Please install it manually."
        exit 1
    fi
    gum style --foreground 2 "gum installed successfully."
fi

#~CHECK FOR YQ~
if ! command -v yq &> /dev/null; then
    gum style --foreground 3 "Installing yq..."
    wget https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 -O /usr/bin/yq
    chmod +x /usr/bin/yq
fi
#~CHECK FOR FILE WITH DIR~
if [ -f "saved_directory.txt" ]; then
    DIRECTORY=$(<saved_directory.txt)
fi

# ~WEB-SERVICE TYPE CHECK~
check_web_service() {
    local response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$1)
    [ $response -eq 200 ] && echo "Web Service" || echo "Unknown Service"
}

# ~NON-WEB-SERVICE TYPE CHECK~
check_nonweb_service() {
    [ -z "$1" ] && echo "Port number is missing." && return
    nc -z localhost $1 </dev/null && echo "Non-Web Service" || echo "Unknown Service"
}

# ~OUTPUT SERVICE NAME AND DIRS IN TABLE~
show_services() {
    gum style --foreground 5 "Services:"
    gum style --border normal --padding "1 2" --margin "1" --width 50 <<EOF
$(for service in $(find $DIRECTORY -mindepth 1 -maxdepth 1 -type d); do
    service_name=$(basename $service)
    docker_compose_file=""
    
    for file in "$service/docker-compose.yml" "$service/docker-compose.yaml" "$service/compose.yml" "$service/compose.yaml"; do
        [ -f "$file" ] && docker_compose_file=$file && break
    done

    if [ ! -z "$docker_compose_file" ]; then
        port=$(yq r "$docker_compose_file" 'services.*.ports[0]' | cut -d':' -f1)
        if [ -n "$port" ]; then
            if curl -s localhost:$port >/dev/null 2>&1; then
                service_type=$(check_web_service $port)
                echo "Service Name: $service_name, Port: $port, Service Type: $service_type"
                echo "http://vuln:$port"
            else
                service_type=$(check_nonweb_service $port)
                [ "$service_type" != "Unknown Service" ] && echo "Service Name: $service_name, Port: $port, Service Type: $service_type" && echo "\`\`\`nc vuln $port \`\`\`"
            fi
        else
            echo "Service Name: $service_name, Port number is missing"
        fi
    else
        echo "Service Name: $service_name, Docker Compose file not found"
    fi
done)
EOF
}

# ~ARCHIVE~
archive_services() {
    tar -czvf services_backup.tar.gz $DIRECTORY/*/
    gum style --foreground 2 "All services have been archived successfully."
}

# ~SAVE DIR~
save_directory() {
    echo $DIRECTORY > saved_directory.txt
    gum style --foreground 2 "Current directory has been saved."
}

# ~DELETE DATA ABOUT DIR~
delete_data() {
    rm -f saved_directory.txt
    gum style --foreground 2 "All saved data have been deleted."
}

# ~CHANGE DIR~
edit_directory() {
    DIRECTORY=$(gum input --placeholder "Enter the new directory path")
    gum style --foreground 2 "Directory has been updated successfully."
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
    gum style --border normal --padding "1 2" --margin "1" --width 50 --align center --border-foreground 4 <<EOF
Service Management Script
=========================
1. Show Services
2. Archive Services
3. Save Current Directory
4. Delete All Saved Data
5. Edit Directory
6. Exit
EOF
    choice=$(gum input --placeholder "Enter your choice")

    case $choice in
        1) show_services; gum style --foreground 2 "Press enter to continue..." && read ;;
        2) archive_services; gum style --foreground 2 "Press enter to continue..." && read ;;
        3) save_directory; gum style --foreground 2 "Press enter to continue..." && read ;;
        4) delete_data; gum style --foreground 2 "Press enter to continue..." && read ;;
        5) edit_directory; gum style --foreground 2 "Press enter to continue..." && read ;;
        6) gum style --foreground 2 "Exiting the script. Goodbye!"; exit 0 ;;
        *) gum style --foreground 1 "Invalid option. Please choose again."; gum style --foreground 2 "Press enter to continue..." && read ;;
    esac
done
