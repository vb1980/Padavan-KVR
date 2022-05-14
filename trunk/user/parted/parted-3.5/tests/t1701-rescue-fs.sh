#!/bin/sh
# rescue ext4 file system

# Copyright (C) 2008-2014, 2019-2022 Free Software Foundation, Inc.

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
require_512_byte_sector_size_
require_root_
require_scsi_debug_module_

# create memory-backed device
scsi_debug_setup_ sector_size=$sector_size_ dev_size_mb=10 > dev-name ||
  skip_ 'failed to create scsi_debug device'
scsi_dev=$(cat dev-name)

( mkfs.ext4 2>&1 | grep -i '^usage' ) > /dev/null \
    || { warn_ "$ME: no ext4 support"; Exit $fail; }

parted -s $scsi_dev mklabel msdos mkpart primary ext2 1m 100%
wait_for_dev_to_appear_ ${scsi_dev}1 || fail=1
mkfs.ext4 ${scsi_dev}1 || { warn_ $ME: mkfs.ext4 failed; fail=1; Exit $fail; }

# remove the partition
parted -s $scsi_dev rm 1 || fail=1

# rescue the partition
echo yes | parted ---pretend-input-tty $scsi_dev rescue 1m 100% > out 2>&1
cat > exp <<EOF
Information: A ext4 primary partition was found at 1049kB -> 10.5MB.  Do you want to add it to the partition table?
Yes/No/Cancel? yes
Information: You may need to update /etc/fstab.
EOF
# Transform the actual output, to avoid spurious differences when
# $PWD contains a symlink-to-dir.  Also, remove the ^M      ...^M bogosity.
# normalize the actual output
mv out o2 && sed -e "s,   *,,g;s, $,," \
                      -e "s,^.*/lt-parted: ,parted: ," o2 > out
echo '' >> exp
compare exp out || fail=1
Exit $fail
