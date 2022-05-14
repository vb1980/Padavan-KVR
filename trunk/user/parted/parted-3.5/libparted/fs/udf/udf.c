/*
    libparted - a library for manipulating disk partitions
    Copyright (C) 2018-2022 Free Software Foundation, Inc.

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

/* Read bytes using ped_geometry_read() function */
static int read_bytes (const PedGeometry* geom, void* buffer, PedSector offset, PedSector count)
{
	char* sector_buffer;
	PedSector sector_offset, sector_count, buffer_offset;

	sector_offset = offset / geom->dev->sector_size;
	sector_count = (offset + count + geom->dev->sector_size - 1) / geom->dev->sector_size - sector_offset;
	buffer_offset = offset - sector_offset * geom->dev->sector_size;

	sector_buffer = alloca (sector_count * geom->dev->sector_size);

	if (!ped_geometry_read (geom, sector_buffer, sector_offset, sector_count))
		return 0;

	memcpy (buffer, sector_buffer + buffer_offset, count);
	return 1;
}

/* Scan VSR and check for UDF VSD */
static int check_vrs (const PedGeometry* geom, unsigned int vsdsize)
{
	PedSector block;
	PedSector offset;
	unsigned char ident[5];

	/* Check only first 64 blocks, but theoretically standard does not define upper limit */
	for (block = 0; block < 64; block++) {
		/* VRS starts at fixed offset 32kB, it is independent of block size or vsd size */
		offset = 32768 + block * vsdsize;

		/* Read VSD identifier, it is at offset 1 */
		if (!read_bytes (geom, ident, offset + 1, 5))
			return 0;

		/* Check for UDF identifier */
		if (memcmp (ident, "NSR02", 5) == 0 ||
		    memcmp (ident, "NSR03", 5) == 0)
			return 1;

		/* Unknown VSD identifier means end of VRS */
		if (memcmp (ident, "BEA01", 5) != 0 &&
		         memcmp (ident, "TEA01", 5) != 0 &&
		         memcmp (ident, "BOOT2", 5) != 0 &&
		         memcmp (ident, "CD001", 5) != 0 &&
		         memcmp (ident, "CDW02", 5) != 0)
			break;
	}

	return 0;
}

/* Check for UDF AVDP */
static int check_anchor (const PedGeometry* geom, unsigned int blocksize, int rel_block)
{
	PedSector block;
	unsigned char tag[16];

	/* Negative block means relative to the end of device */
	if (rel_block < 0) {
		block = geom->length * geom->dev->sector_size / blocksize;
		if (block <= (PedSector)(-rel_block))
			return 0;
		block -= (PedSector)(-rel_block);
		if (block < 257)
			return 0;
	} else {
		block = rel_block;
	}

	if (!read_bytes (geom, tag, block * blocksize, 16))
		return 0;

	/* Check for AVDP type (0x0002) */
	if (((unsigned short)tag[0] | ((unsigned short)tag[1] << 8)) != 0x0002)
		return 0;

	/* Check that location stored in AVDP matches */
	if (((unsigned long)tag[12] | ((unsigned long)tag[13] << 8) | ((unsigned long)tag[14] << 16) | ((unsigned long)tag[15] << 24)) != block)
		return 0;

	return 1;
}

/* Detect presence of UDF AVDP */
static int detect_anchor(const PedGeometry* geom, unsigned int blocksize)
{
	/* All possible AVDP locations in preferred order */
	static int anchors[] = { 256, -257, -1, 512 };
	size_t i;

	for (i = 0; i < sizeof (anchors)/sizeof (*anchors); i++) {
		if (check_anchor (geom, blocksize, anchors[i]))
			return 1;
	}

	return 0;
}

/* Detect UDF filesystem, it must have VRS and AVDP */
static int detect_udf (const PedGeometry* geom)
{
	unsigned int blocksize;

	/* VSD size is min(2048, UDF block size), check for block sizes <= 2048 */
	if (check_vrs (geom, 2048)) {
		for (blocksize = 512; blocksize <= 2048; blocksize *= 2) {
			if (detect_anchor (geom, blocksize))
				return 1;
		}
	}

	/* Check for block sizes larger then 2048, maximal theoretical block size is 32kB */
	for (blocksize = 4096; blocksize <= 32768; blocksize *= 2) {
		if (!check_vrs (geom, blocksize))
			continue;
		if (detect_anchor (geom, blocksize))
			return 1;
	}

	return 0;
}

PedGeometry*
udf_probe (PedGeometry* geom)
{
	if (!detect_udf (geom))
		return NULL;

	return ped_geometry_duplicate (geom);
}

static PedFileSystemOps udf_ops = {
	probe:		udf_probe,
};

static PedFileSystemType udf_type = {
	next:	NULL,
	ops:	&udf_ops,
	name:	"udf",
};

void
ped_file_system_udf_init ()
{
	ped_file_system_type_register (&udf_type);
}

void
ped_file_system_udf_done ()
{
	ped_file_system_type_unregister (&udf_type);
}
