set PART XC7Z020clg400-1
config_webtalk -user off
catch {close_project}
catch {close_sim}
create_project -force -part $PART sim_proj  ../temp
add_files ../src/arp_response.v
add_files ../sim/arp_response_tb.sv -fileset sim_1
set_property top arp_response_tb [get_filesets sim_1]
launch_simulation
restart
run all
