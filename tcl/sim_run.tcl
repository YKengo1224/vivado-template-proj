database -shm -open top -default -into top.shm
probe -create -packed 6144 tb_top.test_inst.dct_calculator_inst.mat_calc_dout
probe -create -packed 5376 tb_top.test_inst.quantizer_inst.quan_data_fixed
probe -create -packed 4808 tb_top.test_inst.i_marker_array
probe -create -database top [scope -tops] -depth all -all
run
exit
