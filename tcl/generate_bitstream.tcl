set WORKSPACE_DIR [lindex $argv 0]
set PROJECT_NAME  [lindex $argv 0]
set TOP_MODULE    [lindex $argv 1]
set JOBS          [lindex $argv 2]
 


#open_project ${WORKSPACE_DIR}/vivado_proj/${PROJECT_NAME}.xpr
open_project ${WORKSPACE_DIR}/${PROJECT_NAME}.xpr


set_param general.maxThreads 4


# synthesis
reset_run synth_1
launch_runs synth_1 -jobs ${JOBS}
wait_on_run synth_1

# impl
launch_runs impl_1 -jobs ${JOBS}
wait_on_run impl_1

# generate bitstream
launch_runs impl_1 -to_step write_bitstream -jobs ${JOBS}
wait_on_run impl_1

#hardware platform
write_hw_platform -fixed -include_bit -force -file ${TOP_MODULE}.xsa

exit


