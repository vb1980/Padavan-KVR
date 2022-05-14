#!/bin/sh

# Test setting empty GPT partition name in non-interactive mode

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

dev=loop-file

truncate --size 50MiB "$dev" || fail=1

# create partition with empty name
parted --script "$dev" mklabel gpt mkpart '""' ext4 1MiB 49MiB > out 2>&1 || fail=1
parted --script --machine "$dev" unit MiB print > out 2>&1 || fail=1
grep 'MiB:::;' out || fail=1

# set a non-empty name
parted --script "$dev" name 1 "test" > out 2>&1 || fail=1
parted --script --machine "$dev" unit MiB print > out 2>&1 || fail=1
grep 'MiB::test:;' out || fail=1

# set empty name
parted --script "$dev" name 1 "''" > out 2>&1 || fail=1
parted --script --machine "$dev" unit MiB print > out 2>&1 || fail=1
grep 'MiB:::;' out || fail=1

Exit $fail
