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
#ifndef _F2FS_H
#define _F2FS_H

#define F2FS_MAGIC		0xF2F52010
#define F2FS_MAX_VOLUME_NAME	512
#define F2FS_SB_OFFSET		0x02

struct f2fs_super_block {
    uint32_t magic;			/* Magic Number */
    uint16_t major_ver;			/* Major Version */
    uint16_t minor_ver;			/* Minor Version */
    uint32_t log_sectorsize;		/* log2 sector size in bytes */
    uint32_t log_sectors_per_block;	/* log2 # of sectors per block */
    uint32_t log_blocksize;		/* log2 block size in bytes */
    uint32_t log_blocks_per_seg;	/* log2 # of blocks per segment */
    uint32_t segs_per_sec;		/* # of segments per section */
    uint32_t secs_per_zone;		/* # of sections per zone */
    uint32_t checksum_offset;		/* checksum offset inside super block */
    uint64_t block_count;		/* total # of user blocks */
    uint32_t section_count;		/* total # of sections */
    uint32_t segment_count;		/* total # of segments */
    uint32_t segment_count_ckpt;	/* # of segments for checkpoint */
    uint32_t segment_count_sit;		/* # of segments for SIT */
    uint32_t segment_count_nat;		/* # of segments for NAT */
    uint32_t segment_count_ssa;		/* # of segments for SSA */
    uint32_t segment_count_main;	/* # of segments for main area */
    uint32_t segment0_blkaddr;		/* start block address of segment 0 */
    uint32_t cp_blkaddr;		/* start block address of checkpoint */
    uint32_t sit_blkaddr;		/* start block address of SIT */
    uint32_t nat_blkaddr;		/* start block address of NAT */
    uint32_t ssa_blkaddr;		/* start block address of SSA */
    uint32_t main_blkaddr;		/* start block address of main area */
    uint32_t root_ino;			/* root inode number */
    uint32_t node_ino;			/* node inode number */
    uint32_t meta_ino;			/* meta inode number */
    uint8_t uuid[16];			/* 128-bit uuid for volume */
    uint16_t volume_name[F2FS_MAX_VOLUME_NAME];	/* volume name */
} __attribute__((packed));

#endif
