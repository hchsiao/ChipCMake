set(VCS_COMPILE_FLAGS
  "+vcs+fsdbon"
  #"-gui"
  "-kdb"
  "-lca"
  "+memcbk"
  "+nospecify" # TODO: consider post-synth simulation
  "+vcs+fsdbon+all"
  "-full64"
  "+systemverilogext+.sv+.svh"
  "-override_timescale=1ns/1ps"
  )
set(VCS_SIM_FLAGS
  #"-verdi"
  )

function(RTL_SIMULATOR_CB_add_testbench _TARGET_NAME)
  get_property(include_dirs GLOBAL PROPERTY HDL_INCLUDE_DIRECTORIES)
  set(inc_flags "")
  foreach(inc ${include_dirs})
    list(APPEND inc_flags +incdir+${inc})
  endforeach()

  get_property(ip_list GLOBAL PROPERTY ${_TARGET_NAME}_TESTBENCH_IP_LIST)
  set(sim_sources "")
  foreach(ip ${ip_list})
    get_property(ip_srcs GLOBAL PROPERTY ${ip}_IP_SOURCES)
    list(APPEND sim_sources ${ip_srcs})
  endforeach()
  # TODO: fix this -> design IPs does not have to specify in add_testbench()

  get_property(design_sources GLOBAL PROPERTY DESIGN_SOURCES)
  list(APPEND sim_sources ${design_sources})
  get_property(test_sources GLOBAL PROPERTY ${_TARGET_NAME}_TESTBENCH_SOURCES)
  list(APPEND sim_sources ${test_sources})

  get_property(sim_flags GLOBAL PROPERTY ${_TARGET_NAME}_TESTBENCH_FLAGS)

  set(VCS_SIMULATOR vcs_simulator_${_TARGET_NAME})
  string(REPLACE ";" " " VCS_COMPILE_FLAG
    "${VCS_COMPILE_FLAGS};${sim_flags};${inc_flags};${sim_sources}")

  add_custom_command(OUTPUT ${VCS_SIMULATOR}
    DEPENDS ${sim_sources}
    # "bash -c" prevents escaped space (i.e. "\ ") disturbing vcs argument parser
    COMMAND bash -c "${VCS_EXECUTABLE} ${VCS_COMPILE_FLAG} -o ${VCS_SIMULATOR}"
    COMMENT "VCS compile design"
    VERBATIM
  )

  string(REPLACE ";" " " VCS_SIM_FLAGS
    "${VCS_SIM_FLAGS}")

  add_custom_target(${_TARGET_NAME}
    DEPENDS ${VCS_SIMULATOR}
    COMMAND source ${VCS_ENV_FILE} && ${CMAKE_CURRENT_BINARY_DIR}/${VCS_SIMULATOR} ${VCS_SIM_FLAGS}
    COMMENT "VCS simulate design"
  )

  add_dependencies(${_TARGET_NAME} c2mk_pre_simulation)

endfunction()
