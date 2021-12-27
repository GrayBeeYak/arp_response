config_webtalk -user off
catch {close_project}
create_project -in_memory
add_files ../src/arp_response.v
set_part XC7Z020clg400-1
set_property top arp_response [current_fileset]
synth_design
