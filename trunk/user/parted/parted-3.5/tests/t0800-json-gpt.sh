#!/bin/sh

# Test JSON output with GPT label

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

# create gpt label and some partitions
parted --script "$dev" mklabel gpt > out 2>&1 || fail=1
parted --script "$dev" disk_set pmbr_boot on > out 2>&1 || fail=1
parted --script "$dev" mkpart "test1" ext4 10% 20% > out 2>&1 || fail=1
parted --script "$dev" mkpart "test2" xfs 20% 60% > out 2>&1 || fail=1
parted --script "$dev" set 2 raid on > out 2>&1 || fail=1

# print with json format
parted --script --json "$dev" unit s print free > out 2>&1 || fail=1

cat <<EOF > exp || fail=1
{
   "disk": {
      "path": "loop-file",
      "size": "102400s",
      "model": "",
      "transport": "file",
      "logical-sector-size": 512,
      "physical-sector-size": 512,
      "label": "gpt",
      "max-partitions": 128,
      "flags": [
          "pmbr_boot"
      ],
      "partitions": [
         {
            "number": 0,
            "start": "34s",
            "end": "10239s",
            "size": "10206s",
            "type": "free"
         },{
            "number": 1,
            "start": "10240s",
            "end": "20479s",
            "size": "10240s",
            "type": "primary",
            "name": "test1"
         },{
            "number": 2,
            "start": "20480s",
            "end": "61439s",
            "size": "40960s",
            "type": "primary",
            "name": "test2",
            "flags": [
                "raid"
            ]
         },{
            "number": 0,
            "start": "61440s",
            "end": "102366s",
            "size": "40927s",
            "type": "free"
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
