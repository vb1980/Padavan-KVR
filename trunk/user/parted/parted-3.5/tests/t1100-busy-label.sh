#!/bin/sh
# partitioning (parted -s DEV mklabel) a busy disk must fail.

# Copyright (C) 2007-2014, 2019-2022 Free Software Foundation, Inc.

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
require_fat_
require_filesystem_ vfat

ss=$sector_size_

scsi_debug_setup_ sector_size=$ss dev_size_mb=10 > dev-name ||
  skip_ 'failed to create scsi_debug device'
dev=$(cat dev-name)

parted -s "$dev" mklabel msdos mkpart primary fat32 1 4 > out 2>&1 || fail=1
compare /dev/null out || fail=1
wait_for_dev_to_appear_ ${dev}1 || fail=1
mkfs.vfat ${dev}1 || fail=1

mount_point="`pwd`/mnt"

# Be sure to unmount upon interrupt, failure, etc.
cleanup_fn_() { umount "${dev}1" > /dev/null 2>&1; }

# create mount point dir. and mount the just-created partition on it
mkdir $mount_point || fail=1
mount "${dev}1" $mount_point || fail=1

# now that a partition is mounted, mklabel attempt must fail
parted -s "$dev" mklabel msdos > out 2>&1; test $? = 1 || fail=1

# create expected output file
echo "Error: Partition(s) on $dev are being used." > exp
compare exp out || fail=1

# Adding a partition must succeed, even though another
# on this same device is mounted (active).
parted -s "$dev" mkpart primary fat32 5 10 > out 2>&1 || fail=1
compare /dev/null out || fail=1
parted -s "$dev" u s print

# ==================================================
# Repeat the test in interactive mode.
# create input file
echo c > in

# as above, this mklabel attempt must fail
parted ---pretend-input-tty "$dev" mklabel msdos < in > out 2>&1
test $? = 1 || fail=1

cat <<EOF > exp || fail=1
Warning: Partition(s) on $dev are being used.
Ignore/Cancel? c
EOF

# Transform the actual output, removing ^M   ...^M.
# normalize the actual output
mv out o2 && sed -e 's,   *,,g;s, $,,;s/^.*Warning/Warning/' \
                 -e 's,^.*/lt-parted: ,parted: ,' o2 > out

# check for expected failure diagnostic
compare exp out || fail=1

Exit $fail
