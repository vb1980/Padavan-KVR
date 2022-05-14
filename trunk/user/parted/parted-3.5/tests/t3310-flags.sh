#!/bin/sh
# Exercise partition flags.

# Copyright (C) 2010-2014, 2019-2022 Free Software Foundation, Inc.

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

. "${srcdir=.}/init.sh"; path_prepend_ ../parted .
ss=$sector_size_
dev=dev-file

extract_flags()
{
  perl -nle '/^[^:]*:4096s:6143s:2048s::[^:]*:(.+);$/ and print $1' "$@"
}

for table_type in aix amiga atari bsd dvh gpt mac msdos pc98 sun loop; do
  ptn_num=1

  case $table_type in
    aix)   # Support for writing AIX disk labels and adding partitions
           # is not yet implemented.
           continue
           ;;
    amiga) primary_or_name='PTNNAME'
           ;;
    atari)  primary_or_name='primary'
           # atari only supports 512b sectors
           [ $ss -ne 512 ] && continue
           ;;
    bsd)   primary_or_name=''
           ;;
    dvh)   primary_or_name='primary'
           ;;
    gpt)   primary_or_name='PTNNAME'
           ;;
    mac)   primary_or_name='PTNNAME'
           # MAC table has the partition map partition as the first
           # partition so the created test partition will be number 2.
           ptn_num=2
           ;;
    msdos) primary_or_name='primary'
           ;;
    pc98)  primary_or_name='PTNNAME'
           # pc98 only supports 512b sectors
           [ $ss -ne 512 ] && continue
           ;;
    sun)   primary_or_name=''
           ;;
    loop)  # LOOP table doesn't support creation of a partition nor any
           # flags.
           continue
           ;;
  esac

  n_sectors=8192
  dd if=/dev/null of=$dev bs=$ss seek=$n_sectors || fail=1

  parted -s $dev mklabel $table_type \
    mkpart $primary_or_name ext2 $((4*1024))s $((6*1024-1))s \
      > out 2> err || fail=1
  compare /dev/null out || fail=1

  # Query libparted for the available flags for this test partition.
  flags=`print-flags $dev $ptn_num` \
    || { warn_ "$ME_: $table_type: failed to get available flags";
         fail=1; continue; }
  case $table_type in
    dvh)   # FIXME: Exclude boot flag as that can only be set on logical
           # partitions in the DVH disk label and this test only uses
           # primary partitions.
           flags=`echo "$flags" | egrep -v 'boot'`
           ;;
    mac)   # FIXME: Setting root or swap flags also sets the partition
           # name to root or swap respectively.  Probably intended
           # behaviour.  Setting lvm or raid flags after root or swap
           # takes two goes to clear the lvm or raid flag.  Is this
           # intended?  For now don't test lvm or raid flags as this
           # test only tries to clear the flags once which causes this
           # test to fail.
           flags=`echo "$flags" | egrep -v 'lvm|raid'`
           ;;
  esac

  for mode in on_only on_and_off ; do
    for flag in $flags; do
      # Turn on each flag, one at a time.
      parted -m -s $dev set $ptn_num $flag on unit s print > raw 2> err || fail=1
      extract_flags raw > out
      grep -w "$flag" out \
        || { warn_ "$ME_: $table_type: flag '$flag' not turned on: $(cat out)"; fail=1; }
      compare /dev/null err || fail=1

      if test $mode = on_and_off; then
        # Turn it off
        parted -m -s $dev set $ptn_num $flag off unit s print > raw 2> err || fail=1
        extract_flags raw > out
        grep -w "$flag" out \
          && { warn_ "$ME_: $table_type: flag '$flag' not turned off: $(cat out)"; fail=1; }
        compare /dev/null err || fail=1
      fi
    done
  done
done

# loop filesystems support no flags.  Make sure this doesn't crash

if [ $ss = 512 ]; then
   # only test on 512 byte ss since mke2fs assumes this on a file
   truncate -s 5m img || framework_failure
   mke2fs img || framework_failure
   echo Error: No flags supported > out.exp
   parted -s img set 1 foo on > out 2>&1
   compare out.exp out || fail=1
   parted -s img disk_set foo on > out 2>&1
   compare out.exp out || fail=1
fi

Exit $fail
