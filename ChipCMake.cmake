if(__ChipCMake_INCLUDED)
  return()
endif()
set(__ChipCMake_INCLUDED TRUE)

include(CMakeParseArguments)

define_property(GLOBAL
  PROPERTY IP_LIST
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
define_property(GLOBAL
  PROPERTY IP_DIRECTORIES
  BRIEF_DOCS tmp
  FULL_DOCS tmpS
  )
set_property(GLOBAL PROPERTY IP_LIST "")
set_property(GLOBAL PROPERTY TESTBENCH_LIST "")
set_property(GLOBAL PROPERTY SYNTHESIS_LIST "BAZ")
set_property(GLOBAL PROPERTY IMPLEMENT_LIST "FOO;BAR")
set_property(GLOBAL PROPERTY IP_DIRECTORIES "")

function(ip_directories)
  get_property(ip_dir_list GLOBAL PROPERTY IP_DIRECTORIES)
  foreach(ip_dir_relative ${ARGN})
    get_filename_component(ip_dir ${ip_dir_relative} REALPATH)
    list(APPEND ip_dir_list ${ip_dir})
  endforeach()
  set_property(GLOBAL PROPERTY IP_DIRECTORIES ${ip_dir_list})
endfunction()

function(add_testbench_subdirectory _SUBD)
  if(NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    # Adding test from an IP, the testbench will be ignored
    return()
  endif()

  add_subdirectory(${_SUBD})
endfunction()

function(add_ip _IP_NAME)
  get_property(ip_dir_list GLOBAL PROPERTY IP_DIRECTORIES)
  foreach(ip_dir ${ip_dir_list})
    if(EXISTS "${ip_dir}/${_IP_NAME}")
      set(${_IP_NAME}_DIR "${ip_dir}/${_IP_NAME}")
      set(${_IP_NAME}_DIR "${ip_dir}/${_IP_NAME}" PARENT_SCOPE)
      break()
    endif()
  endforeach()

  if(NOT ${_IP_NAME}_DIR)
    message(FATAL_ERROR "IP not found: ${_IP_NAME}")
  endif()

  message("Adding IP: ${_IP_NAME}")

  set(param_name "")
  foreach(param_entry ${ARGN})
    if(NOT param_name)
      set(param_name ${param_entry})
    else()
      set(param_value ${param_entry})
      set(${param_name} ${param_value})
      message("IP ${_IP_NAME} parameter ${param_name} = ${param_value} (inherit from ${PROJECT_NAME})")
      set(param_name "")
    endif()
  endforeach()
  add_subdirectory(${${_IP_NAME}_DIR} ${CMAKE_CURRENT_BINARY_DIR}/ip/${_IP_NAME})
endfunction()

function(specify_design)
  set(options NO_SYNTH)
  set(oneValueArgs "")
  set(multiValueArgs SOURCES)
  cmake_parse_arguments(parser "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    # Specifying the design as top design
    set_property(GLOBAL PROPERTY DESIGN_SOURCES "${parser_SOURCES}")
    set_property(GLOBAL PROPERTY DESIGN_NO_SYNTH ${parser_NO_SYNTH})
  else()
    # Specifying the design as IP
    set(IP_NAME ${PROJECT_NAME})

    get_property(ip_list GLOBAL PROPERTY IP_LIST)
    list(FIND ip_list ${IP_NAME} _index)
    if(${_index} GREATER -1)
      message(FATAL_ERROR "IP ${IP_NAME} already exist")
    endif()

    list(APPEND ip_list ${IP_NAME})
    set_property(GLOBAL PROPERTY IP_LIST ${ip_list})

    set_property(GLOBAL PROPERTY ${IP_NAME}_IP_SOURCES "${parser_SOURCES}")
    set_property(GLOBAL PROPERTY ${IP_NAME}_IP_NO_SYNTH ${parser_NO_SYNTH})

  endif()
endfunction()

function(add_ip_sources _IP_NAME)
  get_property(ip_list GLOBAL PROPERTY IP_LIST)
  list(FIND ip_list ${_IP_NAME} _index)
  if(NOT ${_index} GREATER -1)
    message(FATAL_ERROR
      "IP ${_IP_NAME} not found while adding source files")
  endif()

  get_property(ip_sources GLOBAL PROPERTY ${_IP_NAME}_IP_SOURCES)
  list(APPEND ip_sources ${ARGN}) # TODO: check if ARGN contains valid contents
  set_property(GLOBAL PROPERTY ${_IP_NAME}_IP_SOURCES "${ip_sources}")
endfunction()

function(add_testbench _TARGET_NAME)
  if(NOT RTL_SIMULATOR_FOUND)
    message(FATAL_ERROR "An RTL simulator must be found using find_package() before adding testbench")
  endif()

  if(NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    # Adding test from an IP, the testbench will be ignored
    return()
  endif()

  get_property(design_is_set GLOBAL PROPERTY DESIGN_SOURCES SET)
  if(NOT design_is_set)
    message(FATAL_ERROR "Please specify_design() before adding testbench")
  endif()

  get_property(testbench_list GLOBAL PROPERTY TESTBENCH_LIST)
  list(APPEND testbench_list ${_TARGET_NAME})
  set_property(GLOBAL PROPERTY TESTBENCH_LIST ${testbench_list})

  set(options "")
  set(oneValueArgs "")
  set(multiValueArgs FLAGS IP_LIST)
  cmake_parse_arguments(parser "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  set(test_sources "${parser_UNPARSED_ARGUMENTS}")
  # TODO: add a check to make sure ${test_source} contains files only,
  #       otherwise cmake reports confusing error message

  set_property(GLOBAL PROPERTY ${_TARGET_NAME}_TESTBENCH_IP_LIST "${parser_IP_LIST}")
  set_property(GLOBAL PROPERTY ${_TARGET_NAME}_TESTBENCH_FLAGS "${parser_FLAGS}")
  set_property(GLOBAL PROPERTY ${_TARGET_NAME}_TESTBENCH_SOURCES "${test_sources}")

  RTL_SIMULATOR_CB_add_testbench(${_TARGET_NAME})
  update_messages()

endfunction()

function(configure_parameters)
  set(options "")
  set(oneValueArgs POSTFIX)
  set(multiValueArgs PARAM_LIST)
  cmake_parse_arguments(parser "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  foreach(param ${parser_PARAM_LIST})
    if(NOT DEFINED ${param})
      message(FATAL_ERROR "IP parameter ${param} not defined")
    endif()
  endforeach()

  configure_file(${PROJECT_NAME}_${parser_POSTFIX}.in ${PROJECT_NAME}_${parser_POSTFIX})
endfunction()

macro(hdl_include_directories)
  get_property(hdl_inc_dirs GLOBAL PROPERTY HDL_INCLUDE_DIRECTORIES)
  list(APPEND hdl_inc_dirs ${ARGN})
  set_property(GLOBAL PROPERTY HDL_INCLUDE_DIRECTORIES ${hdl_inc_dirs})
endmacro()

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

add_custom_target(c2mk_pre_simulation
  COMMENT  "Executing pre-simulation tasks"
)

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

