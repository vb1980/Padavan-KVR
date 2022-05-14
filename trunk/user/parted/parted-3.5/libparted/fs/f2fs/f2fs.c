/*
    libparted/fs/f2fs - Flash-Friendly File System
    Copyright (C) 2020-2022 Free Software Foundation, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <config.h>

#include <parted/parted.h>
#include <parted/endian.h>

#include "f2fs.h"

static PedGeometry*
f2fs_probe (PedGeometry* geom)
{
        struct f2fs_super_block *sb = alloca(geom->dev->sector_size);

        if (!ped_geometry_read (geom, sb, F2FS_SB_OFFSET, 1))
                return NULL;

        if (PED_LE32_TO_CPU(sb->magic) == F2FS_MAGIC)
                return ped_geometry_new (geom->dev, geom->start, geom->length);

        return NULL;
}

static PedFileSystemOps f2fs_ops = {
        probe:          f2fs_probe,
};

static PedFileSystemType f2fs_type = {
        next:   NULL,
        ops:    &f2fs_ops,
        name:   "f2fs",
};

void
ped_file_system_f2fs_init ()
{
        ped_file_system_type_register (&f2fs_type);
}

void
ped_file_system_f2fs_done ()
{
        ped_file_system_type_unregister (&f2fs_type);
}
