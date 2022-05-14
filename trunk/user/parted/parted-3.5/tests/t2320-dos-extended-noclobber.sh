#!/bin/sh
# Ensure that the extended partition reports the correct length
# after adding another partition.

# Copyright (C) 2015, 2019-2022 Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

. "${srcdir=.}/init.sh"; path_prepend_ ../parted

require_root_
require_scsi_debug_module_

# create memory-backed device
ss=$sector_size_
scsi_debug_setup_ sector_size=$ss dev_size_mb=10 > dev-name ||
  skip_ 'failed to create scsi_debug device'
scsi_dev=$(cat dev-name)

# Create a DOS label with an extended partition and a primary partition
parted -s $scsi_dev mklabel msdos || fail=1
parted -s $scsi_dev mkpart extended 1 5 > out 2>&1 || fail=1
parted -s $scsi_dev mkpart primary 5 10 > out 2>&1 || fail=1
wait_for_dev_to_appear_ ${scsi_dev}1 || fail=1

# Make sure the size of the extended partition is correct.
# 2 sectors for 512b and 1 sector for larger. /sys/.../size is in
# 512b blocks so convert accordingly.
dev=${scsi_dev#/dev/}
ext_len=$(cat /sys/block/$dev/${dev}1/size)
if [ $ss -eq 512 ]; then
    expected_len=2
else
    expected_len=$((ss / 512))
fi
[ $ext_len -eq $expected_len ] || fail=1

Exit $fail
