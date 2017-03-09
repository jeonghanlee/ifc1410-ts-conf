#!/bin/bash
#
#  Copyright (c) 2016 Jeong Han Lee
#  Copyright (c) 2016 European Spallation Source ERIC
#
#  The program is free software: you can redistribute
#  it and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation, either version 2 of the
#  License, or any newer version.
#
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License along with
#  this program. If not, see https://www.gnu.org/licenses/gpl-2.0.txt
#
# Author : Jeong Han Lee
# email  : jeonghan.lee@gmail.com
# Date   : 
# version : 0.0.1
#


declare -gr SC_SCRIPT="$(realpath "$0")"
declare -gr SC_TOP="$(dirname "$SC_SCRIPT")"
declare -gr SC_DATE="$(date +%Y%m%d-%H%M)"


set -a
. ${SC_TOP}/env.conf
set +a

. ${SC_TOP}/functions


local_machine_conf_file=${SC_TOP}/sources/meta-freescale/conf/machine/${MACHINE_CONF}
local_conf_backup_dir=${SC_TOP}/backup

function cp_sdk_local() {
    
    local func_name=${FUNCNAME[*]}; __ini_func ${func_name};
    local isFile=$(checkIfFile ${local_machine_conf_file})
    
    if [[ $isFile -eq "$EXIST" ]]; then
	printf "\nThere is a local file, so rename it first\n"
	mv ${local_machine_conf_file} ${local_machine_conf_file}_backup_at_${SC_DATE}
    else
	printf "no file?"
    fi
    # Use backup option even if we checked its status before.
    cp -p -b ${SDK_MACHINE_CONF_FILE} ${local_machine_conf_file}
    
    __end_func ${func_name};
}



function cp_local_to_sdk() {
    local func_name=${FUNCNAME[*]}; __ini_func ${func_name};
    local isFile=$(checkIfFile ${SDK_MACHINE_CONF_FILE})
    
    if [[ $isFile -eq "$EXIST" ]]; then
	read  -p "Found ${SDK_MACHINE_CONF_FILE}, overwrite (y/n)? " answer

	case ${answer:0:1} in
	    y|Y )
		# Use backup option even if we checked its status before.
		cp -p ${SDK_MACHINE_CONF_FILE} ${local_conf_backup_dir}/${MACHINE_CONF}_backup_from_SDK_at_${SC_DATE}
		cp -p -b ${local_machine_conf_file}  ${SDK_MACHINE_CONF_FILE}
		;;
	    * )
		printf "Nothing happens\n"
		;;
	esac

    else
	cp -p -b ${local_machine_conf_file}  ${SDK_MACHINE_CONF_FILE}
    fi
     
    __end_func ${func_name};
}


function bitbake_sdk () {
    local func_name=${FUNCNAME[*]}; __ini_func ${func_name};
    local receipe=$1

    local isVar=$(checkIfVar ${receipe})
    
    if [[ $isVar -eq "$NON_EXIST" ]]; then
	receipe=${DEFAULT_MACHINE_RECEIPE}
    fi

    pushd ${MACHINE_BUILD_DIR}

    source SOURCE_THIS
    printf "\n You are bitbaking with  %s ............\n\n" "${receipe}"
    bitbake -c populate_sdk $receipe
    popd
    __end_func ${func_name};
}

in_receipe=$2

case "$1" in
    sdk_to_loc)
	cp_sdk_to_loc
	;;
    loc_to_sdk)
	cp_local_to_sdk
	;;
    bitbake)
	bitbake_sdk ${in_receipe}
	;;
     *)

	echo "">&2
        echo " Yocto Conf Manager  ">&2
	echo ""
	echo " Usage: $0 <arg>">&2 
	echo ""
        echo "          <arg>               : info">&2 
	echo ""
	echo "          sdk_to_loc          : cp sdk to local  >> ${MACHINE_CONF} << ">&2
	echo "          loc_to_sdk          : cp local to sdk  >> ${MACHINE_CONF} << ">&2
	echo "          bitbake   <receipe> : bitbake          >> ${MACHINE_CONF} << ">&2
	echo "">&2 	
	exit 0
esac



