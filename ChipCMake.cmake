if(__ChipCMake_INCLUDED)
  return()
endif()
set(__ChipCMake_INCLUDED TRUE)
set(ChipCMake_DIR ${CMAKE_CURRENT_LIST_DIR})

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
set_property(GLOBAL PROPERTY SYNTHESIS_LIST "")
set_property(GLOBAL PROPERTY IMPLEMENT_LIST "")
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

  set(_IP_ARGN ${ARGN})
  message("IP ${_IP_NAME} instantiated by ${PROJECT_NAME}")
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
    if(NOT parser_NO_SYNTH)
      set_property(GLOBAL PROPERTY ${IP_NAME}_IP_SOURCES_SYNTH "${parser_SOURCES}")
    endif()
    set_property(GLOBAL PROPERTY ${IP_NAME}_IP_NO_SYNTH ${parser_NO_SYNTH})

  endif()
endfunction()

# TODO: try using specify_design() instead
function(DONTUSE_add_ip_sources _IP_NAME _SIM_SRC _SYNTH_SRC _SYN_DB)
  get_property(ip_list GLOBAL PROPERTY IP_LIST)
  list(FIND ip_list ${_IP_NAME} _index)
  if(NOT ${_index} GREATER -1)
    message(FATAL_ERROR
      "IP ${_IP_NAME} not found while adding source files")
  endif()

  get_property(ip_sources GLOBAL PROPERTY ${_IP_NAME}_IP_SOURCES)
  get_property(ip_sources_synth GLOBAL PROPERTY ${_IP_NAME}_IP_SOURCES_SYNTH)
  get_property(ip_syn_dbs GLOBAL PROPERTY ${_IP_NAME}_IP_SYN_DB)
  list(APPEND ip_sources ${_SIM_SRC}) # TODO: check if ARGN contains valid contents
  list(APPEND ip_sources ${_SYNTH_SRC})
  list(APPEND ip_sources_synth ${_SYNTH_SRC})
  list(APPEND ip_syn_dbs ${_SYN_DB})
  set_property(GLOBAL PROPERTY ${_IP_NAME}_IP_SOURCES ${ip_sources})
  set_property(GLOBAL PROPERTY ${_IP_NAME}_IP_SOURCES_SYNTH ${ip_sources_synth})
  set_property(GLOBAL PROPERTY ${_IP_NAME}_IP_SYN_DB ${ip_syn_dbs})
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
  # TODO: convert relative path to absolute

  set_property(GLOBAL PROPERTY ${_TARGET_NAME}_TESTBENCH_IP_LIST "${parser_IP_LIST}")
  set_property(GLOBAL PROPERTY ${_TARGET_NAME}_TESTBENCH_FLAGS "${parser_FLAGS}")
  set_property(GLOBAL PROPERTY ${_TARGET_NAME}_TESTBENCH_SOURCES "${test_sources}")

  RTL_SIMULATOR_CB_add_testbench(${_TARGET_NAME})
  update_messages()

endfunction()

function(add_synth_target _TARGET_NAME)
  if(NOT SYNTHESIZER_FOUND)
    message(FATAL_ERROR "A synthsize tool must be found using find_package() before adding synth target")
  endif()

  if(NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    # Adding target from an IP, the target will be ignored
    return()
  endif()

  get_property(design_is_set GLOBAL PROPERTY DESIGN_SOURCES SET)
  if(NOT design_is_set)
    message(FATAL_ERROR "Please specify_design() before adding target")
  endif()

  get_property(synthesis_list GLOBAL PROPERTY SYNTHESIS_LIST)
  list(APPEND synthesis_list ${_TARGET_NAME})
  set_property(GLOBAL PROPERTY SYNTHESIS_LIST ${synthesis_list})

  set(options "")
  set(oneValueArgs "TOP")
  set(multiValueArgs "")
  cmake_parse_arguments(parser "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  SYNTHESIZER_CB_add_synth_target(${_TARGET_NAME} ${parser_TOP})
  update_messages()

endfunction()

function(add_impl_target _TARGET_NAME)
  if(NOT PHY_TOOL_FOUND)
    message(FATAL_ERROR "A physical implementation tool must be found using find_package() before adding impl target")
  endif()

  if(NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    # Adding target from an IP, the target will be ignored
    return()
  endif()

  get_property(design_is_set GLOBAL PROPERTY DESIGN_SOURCES SET)
  if(NOT design_is_set)
    message(FATAL_ERROR "Please specify_design() before adding target")
  endif()

  get_property(implement_list GLOBAL PROPERTY IMPLEMENT_LIST)
  list(APPEND implement_list ${_TARGET_NAME})
  set_property(GLOBAL PROPERTY IMPLEMENT_LIST ${implement_list})

  set(options "")
  set(oneValueArgs "")
  set(multiValueArgs "")
  cmake_parse_arguments(parser "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  PHY_TOOL_CB_add_impl_target(${_TARGET_NAME})
  update_messages()

endfunction()

# The purpose of seperating config.cmake file is to not defaulting every parameters
# TODO: use package instead of macros
function(configure_parameters)
  # TODO: check for '\n' in values, which is not allowed
  foreach(param ${ARGN})
    if(NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
      # Adding test from an IP
      # parameter not defined in current scope, check if defined in IP instantiation
      list(FIND _IP_ARGN ${param} param_index)
      if(param_index GREATER -1)
        foreach(ent ${_IP_ARGN})
          list(FIND ARGN ${ent} ent_index)
          if(ent_index GREATER -1)
            if(ent STREQUAL param)
              set(${param} "")
            elseif(DEFINED ${param})
              break()
            endif()
          elseif(DEFINED ${param})
            list(APPEND ${param} ${ent})
          endif()
        endforeach()
        message("IP ${PROJECT_NAME} parameter ${param} = ${${param}}")
        set(${param} ${${param}} PARENT_SCOPE)
      else()
        message(FATAL_ERROR "IP parameter ${param} not defined")
      endif()
    else()
      # Root project (instead of IP instantiation)
      if(NOT DEFINED ${param})
        message(FATAL_ERROR "Parameter ${param} not defined, specify config using \"-C\"?")
      endif()
    endif()
  endforeach()
endfunction()

macro(hdl_include_directories)
  # TODO: convert paths to absolute
  get_property(hdl_inc_dirs GLOBAL PROPERTY HDL_INCLUDE_DIRECTORIES)
  list(APPEND hdl_inc_dirs ${ARGN})
  set_property(GLOBAL PROPERTY HDL_INCLUDE_DIRECTORIES ${hdl_inc_dirs})
endmacro()

macro(update_messages)
  file(WRITE "${CMAKE_BINARY_DIR}/target_list.txt" "")
  file(WRITE "${CMAKE_BINARY_DIR}/synth_list.txt" "")
  # construct help message
  set(HELP_MSG "=== ChipCMake Help ===\\n"
               "\\n"
               "TODO\\n"
               )

  # construct debug message
  get_property(design_srcs GLOBAL PROPERTY DESIGN_SOURCES)
  set(synth_sources "")
  get_property(ip_list GLOBAL PROPERTY IP_LIST)
  foreach(ip ${ip_list})
    get_property(ip_srcs GLOBAL PROPERTY ${ip}_IP_SOURCES_SYNTH)
    list(APPEND synth_sources ${ip_srcs})
  endforeach()
  list(APPEND synth_sources ${design_srcs})
  file(APPEND "${CMAKE_BINARY_DIR}/synth_list.txt" "${synth_sources}")

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
                    "  -sv_flist (generate filelist, format: SystemVerilog include)\\n"
                    "\\n"
                    "================================")
endmacro()

add_custom_target(c2mk_pre_simulation
  COMMENT  "Executing pre-simulation tasks"
)

add_custom_target(c2mk_pre_synthesis
  COMMENT  "Executing pre-synthesis tasks"
)

add_custom_target(c2mk_pre_implement
  COMMENT  "Executing pre-implement tasks"
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
add_custom_target(debug VERBATIM
  COMMAND cat ${CMAKE_BINARY_DIR}/synth_list.txt
  COMMENT  "Print debug message"
)
add_custom_command(OUTPUT all.sv
  COMMAND bash ${ChipCMake_DIR}/gen_sv_flist.sh
  COMMENT "Generating all.sv"
  )
add_custom_target(sv_flist VERBATIM
  COMMENT  "Generate filelist in SV format"
  DEPENDS all.sv
)

message("ChipCMake module initialized")

