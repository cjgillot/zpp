################################################################################
# Copyright (c) Julien Bigot - CEA (julien.bigot@cea.fr)
# All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
################################################################################

cmake_minimum_required(VERSION 2.8)
cmake_policy(PUSH)

# Compute the installation prefix relative to this file.
get_filename_component(_CURRENT_LIST_DIR "${CMAKE_CURRENT_LIST_FILE}" PATH)

# Compute the installation prefix relative to this file.
if(NOT DEFINED ZPP_EXECUTABLE)
	get_filename_component(_ZPP_BIN_DIR "${CMAKE_CURRENT_LIST_FILE}" PATH)
	get_filename_component(_ZPP_BIN_DIR "${_ZPP_BIN_DIR}" PATH)
	get_filename_component(_ZPP_BIN_DIR "${_ZPP_BIN_DIR}" PATH)
	get_filename_component(_ZPP_BIN_DIR "${_ZPP_BIN_DIR}" PATH)
	if(_ZPP_BIN_DIR STREQUAL "/")
		set(_ZPP_BIN_DIR "")
	endif()
	set(ZPP_EXECUTABLE "${_ZPP_BIN_DIR}/bin/zpp")
endif()

# A function to generate the ZPP config.zpp.sh file
function(zpp_gen_config OUTFILE)
	include("${_CURRENT_LIST_DIR}/TestFortType.cmake")
	foreach(TYPENAME "CHARACTER" "COMPLEX" "INTEGER" "LOGICAL" "REAL")
		foreach(TYPESIZE 1 2 4 8 16 32 64)
			test_fort_type("ZPP_${TYPENAME}${TYPESIZE}_WORKS" "${TYPENAME}" "${TYPESIZE}")
			if("${ZPP_${TYPENAME}${TYPESIZE}_WORKS}")
				set(ZPP_FORT_TYPES "${ZPP_FORT_TYPES}${TYPENAME}${TYPESIZE} ")
			endif()
		endforeach()
	endforeach()
	if(NOT EXISTS "${OUTFILE}")
		file(WRITE "${OUTFILE}"
"# All types supported by the current Fortran implementation
ZPP_FORT_TYPES=\"${ZPP_FORT_TYPES}\"
# for compatibility
ZPP_FORT_TYPES=\"\${ZPP_FORT_TYPES}\"
")
	endif()
endfunction()

# For compatibility
macro(bpp_gen_config)
	message(DEPRECATION "bpp_gen_config is deprecated, use zpp_gen_config instead")
	zpp_gen_config(${ARGV})
macro()


# A function to preprocess a source file with ZPP
function(zpp_preprocess)
	cmake_parse_arguments(ZPP_PREPROCESS "" "OUTPUT" "DEFINES;INCLUDES;SOURCES" "${FIRST_SRC}" ${ARGN})

	# old function signature for compatibility
	if ( 
			"${ZPP_PREPROCESS_OUTPUT}" STREQUAL ""
			AND "${ZPP_PREPROCESS_DEFINES}" STREQUAL ""
			AND "${ZPP_PREPROCESS_INCLUDES}" STREQUAL ""
			AND "${ZPP_PREPROCESS_SOURCES}" STREQUAL ""
	)
		list(GET ARGV 0 ZPP_PREPROCESS_OUTPUT)
		list(REMOVE_AT ARGV 0)
		set(ZPP_PREPROCESS_SOURCES ${ARGV})
	elseif(NOT "${ZPP_PREPROCESS_UNPARSED_ARGUMENTS}" STREQUAL "")
		message(SEND_ERROR "Unexpected argument(s) to zpp_preprocess: ${ZPP_PREPROCESS_UNPARSED_ARGUMENTS}")
	endif()
	
	unset(ZPP_INCLUDE_PARAMS)

	get_property(DIR_INCLUDE_DIRS DIRECTORY PROPERTY INCLUDE_DIRECTORIES)
	foreach(INCLUDE_DIR ${DIR_INCLUDE_DIRS} ${ZPP_PREPROCESS_INCLUDES})
		set(ZPP_INCLUDE_PARAMS ${ZPP_INCLUDE_PARAMS} "-I" "${INCLUDE_DIR}")
	endforeach()
	foreach(DEFINE ${ZPP_PREPROCESS_DEFINES})
		set(ZPP_INCLUDE_PARAMS ${ZPP_INCLUDE_PARAMS} "-D" "${DEFINE}")
	endforeach()

	zpp_gen_config("${CMAKE_CURRENT_BINARY_DIR}/zppconf/config.zpp.sh")
	set(ZPP_INCLUDE_PARAMS ${ZPP_INCLUDE_PARAMS} "-I" "${CMAKE_CURRENT_BINARY_DIR}/zppconf")
	
	set(OUTFILES)
	foreach(SRC ${ZPP_PREPROCESS_SOURCES})
		get_filename_component(OUTFILE "${SRC}" NAME)
		string(REGEX REPLACE "\\.[bB][pP][pP]$" "" OUTFILE "${OUTFILE}")
		set(OUTFILE "${CMAKE_CURRENT_BINARY_DIR}/${OUTFILE}")
		add_custom_command(OUTPUT "${OUTFILE}"
			COMMAND "${ZPP_EXECUTABLE}" ${ZPP_INCLUDE_PARAMS} "${SRC}" "${OUTFILE}"
			WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
			MAIN_DEPENDENCY "${SRC}"
			VERBATIM
		)
		list(APPEND OUTFILES "${OUTFILE}")
	endforeach()

	set(${ZPP_PREPROCESS_OUTPUT} "${OUTFILES}" PARENT_SCOPE)
endfunction()

# For compatibility
macro(bpp_preprocess)
	message(DEPRECATION "bpp_preprocess is deprecated, use zpp_preprocess instead")
	zpp_preprocess(${ARGV})
macro()

cmake_policy(POP)
