#!/bin/sh
# device-mapper sector sizes are 512b, make sure partitions are the correct
# size when using larger sector sizes and a linear dm table.

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

grep '^#define USE_BLKID 1' "$CONFIG_HEADER" > /dev/null ||
  skip_ 'this system lacks a new-enough libblkid'

test "x$ENABLE_DEVICE_MAPPER" = xyes \
  || skip_ "no device-mapper support"

# Device maps names - should be random to not conflict with existing ones on
# the system
linear_=plinear-$$test

cleanup_fn_() {
    i=0
    udevadm settle
    while [ $i -lt 10 ] ; do
      [ -e "/dev/mapper/${linear_}1" ] && dmsetup remove ${linear_}1
      sleep .2
      [ -e "/dev/mapper/$linear_" ] && dmsetup remove $linear_
      sleep .2
      [ -e "/dev/mapper/${linear_}1" ] || [ -e "/dev/mapper/$linear_" ] || i=10
      i=$((i + 1))
    done
    udevadm settle
}

# Create a 10M device
ss=$sector_size_
scsi_debug_setup_ sector_size=$ss dev_size_mb=11 > dev-name ||
  skip_ 'failed to create scsi_debug device'
scsi_dev=$(cat dev-name)

# Size of device, in 512b units
scsi_dev_size=$(blockdev --getsz $scsi_dev) || framework_failure

dmsetup create $linear_ --table "0 $scsi_dev_size linear $scsi_dev 0" || framework_failure
dev="/dev/mapper/$linear_"

# Create msdos partition table with a partition from 1MiB to 10MiB
parted -s $dev mklabel msdos mkpart primary ext2 1MiB 100% > out 2>&1 || fail=1
compare /dev/null out || fail=1
wait_for_dev_to_appear_ ${dev}1 || fail=1

# The size of the partition should be 10MiB, or 20480 512b sectors
p1_size=$(blockdev --getsz ${dev}1) || framework_failure
[ $p1_size == 20480 ] || fail=1

Exit $fail
