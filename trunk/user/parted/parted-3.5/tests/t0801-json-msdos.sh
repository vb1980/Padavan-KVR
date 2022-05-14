#!/bin/sh

# Test JSON output with MS-DOS label

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

. "${srcdir=.}/init.sh"; path_prepend_ ../parted
require_512_byte_sector_size_

dev=loop-file

# create device
truncate --size 50MiB "$dev" || fail=1

# create msdos label and some partitions
parted --script "$dev" mklabel msdos > out 2>&1 || fail=1
parted --script "$dev" mkpart primary ext4 10% 20% > out 2>&1 || fail=1
parted --script "$dev" mkpart extended 20% 60% > out 2>&1 || fail=1
parted --script "$dev" mkpart logical ext4 20% 40% > out 2>&1 || fail=1
parted --script "$dev" set 5 lvm on > out 2>&1 || fail=1

# print with json format
parted --script --json "$dev" unit MiB print > out 2>&1 || fail=1

cat <<EOF > exp || fail=1
{
   "disk": {
      "path": "loop-file",
      "size": "50.0MiB",
      "model": "",
      "transport": "file",
      "logical-sector-size": 512,
      "physical-sector-size": 512,
      "label": "msdos",
      "max-partitions": 4,
      "partitions": [
         {
            "number": 1,
            "start": "5.00MiB",
            "end": "10.0MiB",
            "size": "5.00MiB",
            "type": "primary"
         },{
            "number": 2,
            "start": "10.0MiB",
            "end": "30.0MiB",
            "size": "20.0MiB",
            "type": "extended",
            "flags": [
                "lba"
            ]
         },{
            "number": 5,
            "start": "10.0MiB",
            "end": "20.0MiB",
            "size": "10.0MiB",
            "type": "logical",
            "flags": [
                "lvm"
            ]
         }
      ]
   }
}
EOF

# remove full path of device from actual output
mv out o2 && sed "s,\"/.*/$dev\",\"$dev\"," o2 > out || fail=1

# check for expected output
compare exp out || fail=1

Exit $fail
