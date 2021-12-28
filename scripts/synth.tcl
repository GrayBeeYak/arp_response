set PART XC7Z020clg400-1
config_webtalk -user off
catch {close_project}
catch {close_sim}
create_project -in_memory
add_files ../src/arp_response.v
set_part $PART
set_property top arp_response [current_fileset]
synth_design
