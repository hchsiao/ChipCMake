if(__ChipCMake_INCLUDED)
  return()
endif()
set(__ChipCMake_INCLUDED TRUE)

include(CMakeParseArguments)

define_property(GLOBAL
  PROPERTY DESIGN_LIST
  BRIEF_DOCS tmp
  FULL_DOCS tmpS
  )
define_property(GLOBAL
  PROPERTY TESTBENCH_LIST
  BRIEF_DOCS tmp
  FULL_DOCS tmpS
  )
define_property(GLOBAL
  PROPERTY SYNTHESIS_LIST
  BRIEF_DOCS tmp
  FULL_DOCS tmpS
  )
define_property(GLOBAL
  PROPERTY IMPLEMENT_LIST
  BRIEF_DOCS tmp
  FULL_DOCS tmpS
  )
set_property(GLOBAL PROPERTY DESIGN_LIST "")
set_property(GLOBAL PROPERTY TESTBENCH_LIST "")
set_property(GLOBAL PROPERTY SYNTHESIS_LIST "BAZ")
set_property(GLOBAL PROPERTY IMPLEMENT_LIST "FOO;BAR")

function(add_design _TARGET_NAME)
  get_property(design_list GLOBAL PROPERTY DESIGN_LIST)
  list(APPEND design_list ${_TARGET_NAME})
  set_property(GLOBAL PROPERTY DESIGN_LIST ${design_list})

  set_property(GLOBAL PROPERTY ${_TARGET_NAME}_DESIGN_SOURCES "${ARGN}")
endfunction()

function(add_testbench _TARGET_NAME)
  if(NOT RTL_SIMULATOR_FOUND)
    message(FATAL_ERROR "An RTL simulator must be found using find_package() before adding testbench")
  endif()

  get_property(testbench_list GLOBAL PROPERTY TESTBENCH_LIST)
  list(APPEND testbench_list ${_TARGET_NAME})
  set_property(GLOBAL PROPERTY TESTBENCH_LIST ${testbench_list})

  set(options "")
  set(oneValueArgs DESIGN)
  set(multiValueArgs FLAGS)
  cmake_parse_arguments(parser "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  set(test_sources "${parser_UNPARSED_ARGUMENTS}")

  set_property(GLOBAL PROPERTY ${_TARGET_NAME}_TESTBENCH_DESIGN "${parser_DESIGN}")
  set_property(GLOBAL PROPERTY ${_TARGET_NAME}_TESTBENCH_FLAGS "${parser_FLAGS}")
  set_property(GLOBAL PROPERTY ${_TARGET_NAME}_TESTBENCH_SOURCES "${test_sources}")

  RTL_SIMULATOR_CB_add_testbench(${_TARGET_NAME})
  update_messages()

endfunction()

macro(update_messages)
  file(WRITE "${CMAKE_BINARY_DIR}/target_list.txt" "")
  # construct help message
  set(HELP_MSG "=== ChipCMake Help ===\\n"
               "\\n"
               "TODO\\n"
               )

  # construct rule message
  set(RULE_MSG_HEAD "=== Available ChipCMake Rules ===\\n"
                    "\\n"
                    "-Project specific:"
                    )
  get_property(testbench_list GLOBAL PROPERTY TESTBENCH_LIST)
  foreach(item ${testbench_list})
    file(APPEND "${CMAKE_BINARY_DIR}/target_list.txt"
                    "   -${item} (simulation)\n")
  endforeach()
  get_property(synthesis_list GLOBAL PROPERTY SYNTHESIS_LIST)
  foreach(item ${synthesis_list})
    file(APPEND "${CMAKE_BINARY_DIR}/target_list.txt"
                    "   -${item} (synthesis)\n")
  endforeach()
  get_property(implement_list GLOBAL PROPERTY IMPLEMENT_LIST)
  foreach(item ${implement_list})
    file(APPEND "${CMAKE_BINARY_DIR}/target_list.txt"
                    "   -${item} (implementation)\n")
  endforeach()
  list(APPEND RULE_MSG_TAIL
                    "\\n"
                    "-General:\\n"
                    "  -help (look for help)\\n"
                    "  -rule (display this message)\\n"
                    "\\n"
                    "================================")
endmacro()

update_messages()
add_custom_target(help VERBATIM
  COMMAND echo -e ${HELP_MSG}
  COMMENT  "Print help message"
)
add_custom_target(rule ALL VERBATIM
  COMMAND echo -e ${RULE_MSG_HEAD}
  COMMAND cat ${CMAKE_BINARY_DIR}/target_list.txt
  COMMAND echo -e ${RULE_MSG_TAIL}
  COMMENT  "Print available options"
)

message("ChipCMake module initialized")

