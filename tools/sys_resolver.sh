#!/bin/bash

#
# Syscall resolver
#
# Copyright (c) 2012 Red Hat <pmoore@redhat.com>
# Author: Paul Moore <pmoore@redhat.com>
#

#
# This library is free software; you can redistribute it and/or modify it
# under the terms of version 2.1 of the GNU Lesser General Public License as
# published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License
# for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this library; if not, see <http://www.gnu.org/licenses>.
#

syscall_h="/usr/include/asm/unistd.h"

####
# functions

function verify_deps() {
	[[ -z "$1" ]] && return
	if ! which "$1" >& /dev/null; then
		echo "error: install \"$1\" and include it in your \$PATH"
		exit 1
	fi
}

####
# main

# verify script dependencies
verify_deps gcc
verify_deps grep
verify_deps awk
verify_deps sed

# verify the command line
if [[ "$#" -ne 1 || -z "$1" ]]; then
	echo "usage: $0 <syscall_name>"
	exit 1
fi

# inspect the syscall header file and do the resolution
sys_def="$(gcc $CFLAGS -E -dM "$syscall_h" | grep " __NR_$1 ")"
if [[ -n "$sys_def" ]]; then
	if [[ $sys_def =~ .*__NR_[a-zA-Z_]+" "*\+" "*[0-9]+ ]]; then
		# the value is calculated using an offset from another syscall
		base="$(echo $sys_def |
			sed -e 's/\(.*\)__NR_\([a-zA-Z_]\+\)\(.*\)/\2/;')"
		offset="$(echo $sys_def |
			  sed -e 's/\(.*+ *\)\([0-9]*\)\(.*\)/\2/;')"
		echo $(($($0 $base) + $offset))
	else
		echo "$sys_def" | awk '{ print $3 }'
	fi
else
	echo "error: unknown syscall \"$1\""
	exit 1
fi

exit 0