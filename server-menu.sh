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
  alias $((i + 1))="connect $tmp_server.$server_suffix"
done
unset tmp_server

# Generate a new server menu
function generate_menu() {
  source "$config_file"
  source "$script_dir/display-boxes/display-boxes.sh"
  local headers="Alias   Env   Server   IP Address"
  local body=""
  for key in ${!servers[@]}; do
    unset server ip env
    local server=${servers[$key]}
    if [[ $server =~ : ]]; then
      [[ $server =~ (.*):(.*) ]]
      local env=${BASH_REMATCH[1]}
      local server=${BASH_REMATCH[2]}
    else
      local env=unknown
    fi
    local ip=$(dig +short $server.$server_suffix | head -n1)
    body+="$(($key + 1))   $env   $server   $ip"$'\n'
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
  test -z "$2" && u=$username || u=$2
  local server="$(echo "$1" | cut -d: -f2)"
  ssh $u@$server
  command clear
  set_title
  echo "Exiting: $server"
  menu
}
