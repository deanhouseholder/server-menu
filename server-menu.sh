# Server Menu

script_dir="$(cd $(dirname $BASH_SOURCE) && echo $(pwd))"
config_file="$script_dir/config.txt"
config_example_file="$script_dir/config-example.txt"

if [[ ! -f "$config_file" ]]; then
  cp "$config_example_file" "$config_file"
  echo "Please edit $config_file and add your servers to it."
  return 1
fi

source "$config_file"

# Define SSH aliases for each server
for i in ${!servers[@]}; do
  tmp_server="$(echo "${servers[$i]}" | cut -d: -f2)"
  if [[ $tmp_server =~ (.*)@(.*) ]]; then
    tmp_user=${BASH_REMATCH[1]}
    tmp_server=${BASH_REMATCH[2]}
  fi
  if [[ -z $tmp_user ]]; then
    tmp_user=$username
  fi
  if [[ -z "$server_suffix" ]]; then
    alias $((i + 1))="connect $tmp_user@$tmp_server"
  else
    alias $((i + 1))="connect $tmp_user@$tmp_server.$server_suffix"
  fi
done
unset tmp_server tmp_user

# Generate a new server menu
function generate_menu() {
  source "$config_file"
  source "$script_dir/display-boxes/display-boxes.sh"

  # Define vars
  local headers body server ip env user server_lookup
  headers="Alias   Env   Server   IP Address"

  for key in ${!servers[@]}; do
    unset server ip env user
    server=${servers[$key]}

    # Parse config line into variables
    if [[ $server =~ (.*):(.*) ]]; then
      env=${BASH_REMATCH[1]}
      server=${BASH_REMATCH[2]}
      if [[ $server =~ (.*)@(.*) ]]; then
         user=${BASH_REMATCH[1]}
         server=${BASH_REMATCH[2]}
      fi
    else
      env=unknown
    fi

    # Look up IP address
    if [[ -z "$server_suffix" ]]; then
      server_lookup=$server
    else
      server_lookup=$server.$server_suffix
    fi

    # Get IP with getent which uses the hosts file
    ip="$(getent ahosts $server_lookup | head -n1 | awk '{print $1}')"
    # If empty look up using dig
    [[ -z "$ip" ]] && ip=$(dig +short $server_lookup | head -n1)
    # If still empty, just use the server name
    [[ -z "$ip" ]] && ip=$server

    # Add line to menu
    if [[ -z "$user" ]]; then
      body+="$(($key + 1))   $env   $server   $ip"$'\n'
    else
      body+="$(($key + 1))   $env   $user@$server   $ip"$'\n'
    fi
  done
  display-box "$headers " "$body"> ~/.servers
  source "$script_dir/server-menu.sh"
}

# Display a menu of servers
function menu() {
  test -f ~/.servers || generate_menu
  printf "\n"
  command cat ~/.servers
  printf "\n"
}

# Set the window title to function arguments
function set_title(){
  printf '\033]2;%s\007' "$your_computer_name"
}

# SSH connect function
function connect(){
  if [[ $1 =~ (.*)@(.*) ]]; then
    local user=${BASH_REMATCH[1]}
    local server=${BASH_REMATCH[2]}
  else
    local server="$1"
  fi
  ssh $1
  command clear
  set_title
  echo "Exiting: $server"
  menu
}
