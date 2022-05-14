/* Print the available flags for a particular partition. */

#include <config.h>
#include <parted/parted.h>
#include <stdio.h>
#include <stdlib.h>
#include "progname.h"

int
main (int argc, char **argv)
{
	PedDevice *dev;
	PedDisk *disk;
	PedPartition *part;
	int partnum;

	set_program_name (argv[0]);

	if (argc != 3 ) {
		fprintf (stderr, "Usage: %s <device> <ptnnum>\n", argv[0]);
		return EXIT_FAILURE;
	}

	dev = ped_device_get(argv[1]);
	if (!dev) {
		fprintf (stderr, "Error: failed to create device %s\n",
		                 argv[1]);
		return EXIT_FAILURE;
	}
	if (!ped_device_open (dev)) {
		fprintf (stderr, "Error: failed to open device %s\n", argv[1]);
		return EXIT_FAILURE;
	}
	disk = ped_disk_new (dev);
	if (!disk) {
		fprintf (stderr,
		         "Error: failed to read partition table from device %s\n",
		         argv[1]);
		return EXIT_FAILURE;
	}

	partnum = atoi (argv[2]);
	part = ped_disk_get_partition (disk, partnum);
	if (!part) {
		fprintf (stderr,
		         "Error: failed to get partition %d from device %s\n",
		         partnum, argv[1]);
		return EXIT_FAILURE;
	}

	for (PedPartitionFlag flag = PED_PARTITION_FIRST_FLAG;
	     flag <= PED_PARTITION_LAST_FLAG; flag++)
	{
		if (ped_partition_is_flag_available (part, flag))
			puts (ped_partition_flag_get_name (flag));
	}
	return EXIT_SUCCESS;
}
