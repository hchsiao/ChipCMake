function(PHY_TOOL_CB_add_impl_target _TARGET_NAME)
  get_property(include_dirs GLOBAL PROPERTY HDL_INCLUDE_DIRECTORIES)
  set(inc_flags "")
  foreach(inc ${include_dirs})
    list(APPEND inc_flags +incdir+${inc})
  endforeach()

  get_property(design_sources GLOBAL PROPERTY DESIGN_SOURCES)

  add_custom_target(${_TARGET_NAME}
    COMMAND ${EDI_EXECUTABLE} -f EDI_bootstrap.tcl
    COMMENT "EDI implement design"
  )

  add_dependencies(${_TARGET_NAME} c2mk_pre_implement)

endfunction()
