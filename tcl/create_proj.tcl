# env
set CURRENT_DIR        [pwd]
set HOME_DIR           [file dirname $CURRENT_DIR]
set WORKSPACE_DIR      [lindex $argv 0]
set PROJECT_NAME       [lindex $argv 0]
# set BD_TCL             ${HOME_DIR}/tcl/gen_bd.tcl;
set BD_NAME            [lindex $argv 3]
set BD_TCL             [lindex $argv 4]
set IS_VITIS_AI        [lindex $argv 5]
#lappend ip_repo_path_list [file join ${CURRENT_DIR} "ip_repo"]
#set ip_repo_path_list "/home/kengo/work/univ/UMV/jpeg-codec-2024/ip_dir/ip_repo"
#set ip_repo_path_list "/home/kengo/work/UMV/UMV-jpeg-codec-HW/ip_dir/ip_repo"
#set ip_repo_path_list "/home/kengo/work/UMV/UMV-jpeg-codec-HW/ip_dir-22.1/ip_repo"
set ip_repo_path_list "/home/users/kengo/work/umv/UMV-jpeg-codec-HW/ip_dir-22.1/ip_repo"
# set ip_repo_path_list "../ip_dir/ip_repo"
set BOARD_PATH         [lindex $argv 1]
set ZYBO               "zybo-z7-20"
set KV260              "kv260"
set KR260              "kr260"
set BOARD              [lindex $argv 2]
#set BOARD              "kv260"
#set CHIP               "xczu9eg-ffvb1156-2-e"

# Create IP NAMEs
set AXI_CLK_GEN        "AXI_CLK_GEN"
set PIXEL_CLK_GEN      "PIXEL_CLK_GEN"
set ZYNQ_MP            "ZYNQMP"

#select port
if {  ${BOARD}  == ${ZYBO} } then {
    set CHIP          "xc7z020clg400-1"
    #set BOARD_PORT    "digilentinc.com:zybo-z7-20:part0:1.1"

} elseif {  ${BOARD}  == ${KV260} } then {
    set CHIP          "xck26-sfvc784-2LV-c"
    set BOARD_PORT    "xilinx.com:kv260_som:part0:1.3"
    
} elseif {  ${BOARD}  == ${KR260} } then {
    set CHIP          "xck26-sfvc784-2LV-c"
    set BOARD_PORT    "xilinx.com:kr260_som:part0:1.0"
    
} else {
    puts "ERROR:not supported board at this tcl script"
    return 1
    
}


# create project
if { [ file exists ${WORKSPACE_DIR}/${PROJECT_NAME}.xpr ] == 0 } then {
    create_project -force ${PROJECT_NAME} ${WORKSPACE_DIR} -part ${CHIP}
    set_property -name "board_part_repo_paths" -value [file normalize $BOARD_PATH] -objects [current_project]    
    set_property board_part [get_board_parts -quiet -latest_file_version "*$BOARD*"] [current_project]
    set_property platform.extensible true [current_project]
    #set ip repo
    if {[info exists ip_repo_path_list] && [llength ${ip_repo_path_list}] > 0 } {
        set_property ip_repo_paths $ip_repo_path_list [current_fileset]
        update_ip_catalog
    }
    #import bd
    if {[file exists ${HOME_DIR}/${BD_TCL}] == 1 } then {
        source ${HOME_DIR}/${BD_TCL}
        regenerate_bd_layout
        save_bd_design
        set design_bd_name  [get_bd_designs]
        make_wrapper -files [get_files ${design_bd_name}.bd] -top -import
    } else {
        create_bd_design ${BD_NAME}
        set design_bd_name [get_bd_designs]
        make_wrapper -files [get_files ${BD_NAME}.bd] -top
        add_files -norecurse ${WORKSPACE_DIR}/${PROJECT_NAME}.gen/sources_1/bd/${BD_NAME}/hdl/${BD_NAME}_wrapper.v
        update_compile_order -fileset sources_1
    } 

}

exit
