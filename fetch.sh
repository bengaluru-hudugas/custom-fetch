#!/bin/bash

# Define colors
arch_blue='\033[38;2;23;147;209m'
reset='\033[0m'        # Reset to default color
red='\033[1;31m'
green='\033[1;32m'
yellow='\033[1;33m'
blue='\033[1;34m'
magenta='\033[1;35m'
cyan='\033[1;36m'
white='\033[1;37m'

# Define ASCII art logo
logo="
                   ▄                   
                  ▟█▙                  
                 ▟███▙                 
                ▟█████▙                
               ▟███████▙               
              ▂▔▀▜██████▙              
             ▟██▅▂▝▜█████▙             
            ▟█████████████▙            
           ▟███████████████▙           
          ▟█████████████████▙          
         ▟███████████████████▙         
        ▟█████████▛▀▀▜████████▙        
       ▟████████▛      ▜███████▙       
      ▟█████████        ████████▙      
     ▟██████████        █████▆▅▄▃▂     
    ▟██████████▛        ▜█████████▙    
   ▟██████▀▀▀              ▀▀██████▙   
  ▟███▀▘                       ▝▀███▙  
 ▟▛▀                               ▀▜▙ 
"

# Define system information
userhost=$(printf "%s @ %s" "$(id -un | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')" "$(uname -n | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')") 
os=$(hostnamectl | awk -F ': ' '/Operating System/ {print $2}')
kernel=$(hostnamectl | awk -F ': ' '/Kernel/ {split($2, a, "-"); print a[1]}')
host=$(paste -d' ' <(cat /sys/devices/virtual/dmi/id/sys_vendor | awk '{print $1}') <(cat /sys/devices/virtual/dmi/id/product_name))
cpu=$(echo "$(lscpu | awk -F: '
/Model name:/ { model=$2 }
/Core\(s\) per socket:/ { cores=$2 }
/CPU max MHz:/ { freq=$2 }
END {
    gsub(/^[ \t]+|[ \t]+$/, "", model)
    gsub(/\(R\)|\(TM\)/, "", model)  # Remove (R) and (TM)
    gsub(/^[ \t]+|[ \t]+$/, "", cores)
    gsub(/^[ \t]+|[ \t]+$/, "", freq)
    freq_ghz=sprintf("%.3f", freq / 1000)
    printf "%s (%s Core) @ %sGHz", model, cores, freq_ghz
}') [$(sensors | awk '/^Core 0:/ {gsub(/\+/, "", $3); print $3}')]")
gpu=$(lspci | grep -i vga | awk '{print $5" "$7" "$8" "$9" "$10" "$11}')
resolution=$(xrandr | awk '/\*/ {gsub(/[\*\+]/, "", $2); printf "%s @ %.2fHz\n", $1, $2}')
battery=$(cat /sys/class/power_supply/BAT*/uevent | grep -E '^(POWER_SUPPLY_(STATUS|CAPACITY))=' | awk -F '=' '
    /POWER_SUPPLY_CAPACITY/ {capacity=$2}
    /POWER_SUPPLY_STATUS/ {status=$2}
    END {
        # Print capacity and status in a format that can be adjusted by the next awk command
        print capacity, status
    }
' | awk '
    {
        # Construct the full status string
        status = $2$3
        # Check if the status is "Notcharging" and replace it with "On Hold"
        if (status == "Notcharging") {
            status = "Charging On Hold"
        }
        # Print the output with the modified status
        print $1 " Percent (" status ")"
    }
')


# Get the output of the free command
free_output=$(free -b)  # Using bytes for precision

# Extract total and used memory in bytes
total_mem=$(echo "$free_output" | awk '/^Mem:/ {print $2}')
used_mem=$(echo "$free_output" | awk '/^Mem:/ {print $3}')

# Convert used and total memory to GB (integer division, so rounding is done implicitly)
total_mem_gb=$((total_mem / 1024 / 1024 / 1024))
used_mem_gb=$((used_mem / 1024 / 1024 / 1024))

# Calculate percentage of used memory
percent_used=$((100 * used_mem / total_mem))


mem=$(echo "${used_mem_gb} GB Used / ${percent_used} Percent")
disk=$(df -h / | grep / | awk '{print $3 "B Used / " $4 "B Free"}')
uptime=$(uptime -p | sed 's/^up //' | sed 's/,//g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')
de=$(env | grep XDG_CURRENT_DESKTOP= | cut --complement -d "=" -f 1)

# Calculate the maximum width of the logo
max_width=0
while IFS= read -r line; do
    length=${#line}
    if (( length > max_width )); then
        max_width=$length
    fi
done <<< "$logo"

# Print logo and system information side by side
IFS=$'\n'  # Set IFS to newline to preserve leading whitespace in the logo
logo_lines=($logo)
for (( i=0; i<${#logo_lines[@]}; i++ )); do
    # Print the logo in arch blue
    printf "${arch_blue}%-${max_width}s${reset}   " "${logo_lines[i]}"

    # Print system information in different colors
    case $i in
        4) printf "${green}$userhost${reset}" ;;
        5) printf "${yellow}OS: $os${reset}" ;;
        6) printf "${blue}Kernel: $kernel${reset}" ;;
        7) printf "${magenta}Host: $host${reset}" ;;
        8) printf "${cyan}CPU: $cpu${reset}" ;;
        9) printf "${red}GPU: $gpu${reset}" ;;
        10) printf "${white}Resolution: $resolution${reset}" ;;
        11) printf "${green}Battery: $battery${reset}" ;;
        12) printf "${yellow}Memory Usage: $mem${reset}" ;;
        13) printf "${blue}Disk Usage: $disk${reset}" ;;
        14) printf "${magenta}Uptime: $uptime${reset}" ;;
        15) printf "${cyan}DE: $de${reset}" ;;
        *) printf "" ;;
    esac
    echo   # Print a newline after each line
done
