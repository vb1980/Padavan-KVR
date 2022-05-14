#!/bin/sh

# Test that GUID specific bits are preserved

# Copyright (C) 2021 SUSE LLC

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

. "${srcdir=.}/init.sh"; path_prepend_ ../parted $srcdir
require_512_byte_sector_size_

dev=loop-file

# create device
truncate --size 50MiB "$dev" || fail=1

# create gpt label and one partitions
parted --script "$dev" mklabel gpt > out 2>&1 || fail=1
parted --script "$dev" mkpart "test1" ext4 0% 10% > out 2>&1 || fail=1

# set guid specific bit
gpt-attrs "$dev" set 0x100000000000000 || fail=1

# create additional partition
parted --script "$dev" mkpart "test2" ext4 10% 20% > out 2>&1 || fail=1

cat <<EOF > exp || fail=1
0x100000000000000
EOF

# check guid specific bit
gpt-attrs "$dev" show > out || fail=1
compare exp out || fail=1

Exit $fail
