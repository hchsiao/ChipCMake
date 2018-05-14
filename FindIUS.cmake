# This file includes simulator dependent scripts only

set(IUS_FLAGS "+nc64bit +sv +access+r -mccodegen +nctimescale+1ns/1ps")
ius: cache-dir seq
	$(Q)cd $(CACHE_DIR) &&\
		ncverilog $(IUS_FLAGS) $(SIM_PARAMS) $(DUMP_FLAG) $(RTL_FLAGS) $(SV_INCL) $(SV_SRCS)

