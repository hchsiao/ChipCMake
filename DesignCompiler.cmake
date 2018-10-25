set(BOOTSTRAP_FILENAME DesignCompiler_bootstrap.tcl)
set(FLOWMAN_FILENAME DesignCompiler_flowman.tcl)

function(SYNTHESIZER_CB_add_synth_target _TARGET_NAME _TOP)
  get_property(include_dirs GLOBAL PROPERTY HDL_INCLUDE_DIRECTORIES)

  get_property(ip_list GLOBAL PROPERTY IP_LIST)
  set(synth_sources "")
  set(syn_db_list "")
  foreach(ip ${ip_list})
    get_property(ip_srcs GLOBAL PROPERTY ${ip}_IP_SOURCES_SYNTH)
    get_property(ip_syn_dbs GLOBAL PROPERTY ${ip}_IP_SYN_DB)
    list(APPEND synth_sources ${ip_srcs})
    list(APPEND syn_db_list ${ip_syn_dbs})
  endforeach()
  get_property(design_sources GLOBAL PROPERTY DESIGN_SOURCES)
  list(APPEND synth_sources ${design_sources})

  add_custom_target(${_TARGET_NAME}
    COMMAND ${DesignCompiler_EXECUTABLE} -f ${BOOTSTRAP_FILENAME}
    COMMENT "DesignCompiler synthesize design"
  )

  add_dependencies(${_TARGET_NAME} c2mk_pre_synthesis)

  find_package(CBDK)
  set(search_path      ${include_dirs}
                       ${CBDK_DIR}/${CBDK_DB_PATH}
                       )
  set(target_library   ${CBDK_TARGET_LIBRARY}
                       ${syn_db_list}
                       )
  set(symbol_library   ${CBDK_SYMBOL_LIBRARY})
  set(current_design   ${_TOP})
  configure_file(${ChipCMake_DIR}/${BOOTSTRAP_FILENAME}.in ${BOOTSTRAP_FILENAME})
  configure_file(${ChipCMake_DIR}/${FLOWMAN_FILENAME}.in ${FLOWMAN_FILENAME})

endfunction()
