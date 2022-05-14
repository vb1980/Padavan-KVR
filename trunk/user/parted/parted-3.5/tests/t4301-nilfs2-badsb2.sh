#!/bin/sh
# Trigger a nilfs2-related bug.

# Copyright (C) 2011-2014, 2019-2022 Free Software Foundation, Inc.

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
ss=$sector_size_
len=32
dev=dev-file

dd if=/dev/zero of=$dev bs=512 count=$(($len+$ss/512)) || framework_failure_

end=$(($len * 512 / $ss))
parted -s $dev mklabel msdos mkpart primary 1s ${end}s || framework_failure_

# Write a secondary superblock with the nilfs magic number and a nilfs
# superblock length (s_bytes) field of only 10 bytes.
# struct nilfs2_super_block starts with these four fields...
#	uint32_t	s_rev_level;
#	uint16_t	s_minor_rev_level;
#	uint16_t	s_magic;
#	uint16_t	s_bytes;
sb2_offset=$(( 24 / ($ss / 512) + 1))
perl -e "print pack 'LSSS.', 0, 0, 0x3434, 10, $ss" |
    dd of=$dev bs=$ss seek=$sb2_offset count=1 conv=notrunc

# This used to give parted a sigsegv.
parted -s $dev print || fail=1

Exit $fail
