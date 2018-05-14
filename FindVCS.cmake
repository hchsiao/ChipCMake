# This file includes simulator dependent scripts only

set(VCS_FLAG_LIST "+vcs+fsdbon"
                  "-gui"
                  "-kdb"
                  "-lca"
                  "+memcbk"
                  "+vcs+fsdbon+struct"
                  "-full64"
                  "+systemverilogext+.sv+.svh"
                  "-override_timescale=1ns/1ps"
                  )
set(VCS_SIM_FLAG_LIST "-verdi"
                  )
set(VCS_EXECUTABLE vcs)

function(RTL_SIMULATOR_CB_add_testbench _TARGET_NAME)
  get_property(design_name GLOBAL PROPERTY ${_TARGET_NAME}_TESTBENCH_DESIGN)
  get_property(sim_flags GLOBAL PROPERTY ${_TARGET_NAME}_TESTBENCH_FLAGS)
  get_property(test_sources GLOBAL PROPERTY ${_TARGET_NAME}_TESTBENCH_SOURCES)
  get_property(design_sources GLOBAL PROPERTY ${design_name}_DESIGN_SOURCES)

  set(inc_flags "")
  get_directory_property(include_dirs INCLUDE_DIRECTORIES)
  foreach(inc ${include_dirs})
    list(APPEND inc_flags +incdir+${inc})
  endforeach()

  set(VCS_SIMULATOR vcs_simulator_${_TARGET_NAME})
  string(REPLACE ";" " " VCS_COMPILE_FLAG
    "${VCS_FLAG_LIST};${sim_flags};${inc_flags};${design_sources};${test_sources}")

  add_custom_command(OUTPUT ${VCS_SIMULATOR}
    DEPENDS ${design_sources} ${test_sources}
    COMMAND ${VCS_EXECUTABLE} ${VCS_COMPILE_FLAG} -o ${VCS_SIMULATOR}
    COMMENT "VCS compile design"
  )

  string(REPLACE ";" " " VCS_SIMULATE_FLAG
    "${VCS_SIM_FLAG_LIST}")

  add_custom_target(${_TARGET_NAME}
    DEPENDS ${VCS_SIMULATOR}
    COMMAND ${CMAKE_CURRENT_BINARY_DIR}/${VCS_SIMULATOR} ${VCS_SIMULATE_FLAG}
    COMMENT "VCS simulate design"
  )

  add_dependencies(${_TARGET_NAME} ${_TARGET_NAME})

endfunction()

set(RTL_SIMULATOR_FOUND 1)
