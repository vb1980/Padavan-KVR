/*
 * Author: Wang Dong <dongdwdw@cn.ibm.com>
 */

#include <config.h>
#include <unistd.h>
#include <check.h>

#include <parted/vtoc.h>
#include <parted/device.h>
#include <parted/fdasd.h>
#include <parted/vtoc.h>
#include "../arch/linux.h"
#include "common.h"
#include "progname.h"

#if defined __s390__ || defined __s390x__

/* set dasd first */
static char vol_devno[7] = {0};
static char *tmp_disk;
static int fd;

static PedDisk *disk;
static struct fdasd_anchor anc;
static fdasd_anchor_t *anchor = &anc;
static LinuxSpecific *arch_specific;

/* set the enviroment */
static void set_test (void)
{
        PedDevice *dev;
        PedDiskType *type;
        type = ped_disk_type_get ("dasd");

        tmp_disk = _create_disk (20*1024*1024);
        fail_if (tmp_disk == NULL, "Failed to create temporary disk");
        dev = ped_device_get (tmp_disk);
        if (dev == NULL)
                return;

        disk = _create_disk_label (dev, type);
        if (!ped_device_open (disk->dev))
                return;

        fdasd_initialize_anchor (anchor);
        arch_specific = LINUX_SPECIFIC (disk->dev);
        fd = arch_specific->fd;
        if (!fdasd_get_geometry (dev, anchor, fd))
                return;

        fdasd_check_volume (anchor, fd);
        sprintf (vol_devno, "0X%04x", anchor->devno);
        ck_assert (strlen (vol_devno) == VOLSER_LENGTH);
}

static void free_test (void)
{
        ped_device_close (disk->dev);
        ped_device_destroy (disk->dev);
        unlink (tmp_disk);
        free (tmp_disk);
        fdasd_cleanup (anchor);
}

/* Test with default volser */
START_TEST (test_get_volser)
{
        char volser[7] = {0};
        fdasd_change_volser (anchor, vol_devno);
        fdasd_write_labels (anchor, fd);

        fdasd_get_volser (anchor, volser, fd);
        ck_assert (!strcmp (volser, vol_devno));
}
END_TEST

START_TEST (test_check_volser)
{
        char vol_long[] = "abcdefg";
        char vol_short[] = "ab_c   ";
        char vol_null[] = "      ";
        char *vol_input = NULL;

        vol_input = vol_long;
        fdasd_check_volser (vol_input, anchor->devno);
        ck_assert(!strcmp (vol_input, "ABCDEF"));

        vol_input = vol_short;
        fdasd_check_volser (vol_input, anchor->devno);
        ck_assert (!strcmp (vol_input, "ABC"));

        vol_input = vol_null;
        fdasd_check_volser (vol_input, anchor->devno);
        ck_assert (!strcmp (vol_input, vol_devno));
}
END_TEST

START_TEST (test_change_volser)
{

        char vol[] = "000000";
        char volser[7] = {0};

        fdasd_change_volser (anchor, vol);
        fdasd_write_labels (anchor, fd);

        fdasd_get_volser (anchor, volser, fd);
        ck_assert (!strcmp (volser, vol));
}
END_TEST

/*
 * fdsad_recreate_vtoc recreate the VTOC with existing one.
 * So the partition information should be not changed after recreating
 * VTOC.
*/
START_TEST (test_reuse_vtoc)
{
        ds5ext_t before;
        ds5ext_t after;

        memcpy (&before, &anchor->f5->DS5AVEXT, sizeof(ds5ext_t));

        if (anchor->fspace_trk) {
                fdasd_reuse_vtoc (anchor);
                memcpy (&after, &anchor->f5->DS5AVEXT, sizeof(ds5ext_t));
                if ((before.t != after.t) && (before.fc != after.fc) && (before.ft != after.ft))
                        ck_abort ();
        } else {
                fdasd_reuse_vtoc (anchor);
                memcpy (&after, &anchor->f5->DS5AVEXT, sizeof(ds5ext_t));
                if ((before.t != after.t) && (before.fc != after.fc) && (before.ft != after.ft))
                        ck_abort ();
        }
}
END_TEST

#endif

int main (int argc, char **argv)
{

        set_program_name (argv[0]);

#if defined __s390__ || defined __s390x__

        int number_failed = 0;

        Suite *suite = suite_create ("Volser");

        TCase *tcase_get = tcase_create ("Get");
        TCase *tcase_check = tcase_create ("Check");
        TCase *tcase_change = tcase_create ("Change");
        TCase *tcase_vtoc = tcase_create ("Vtoc");

        ped_exception_set_handler (_test_exception_handler);

        tcase_add_checked_fixture (tcase_check, set_test, free_test);
        tcase_add_test (tcase_check, test_check_volser);
        tcase_set_timeout (tcase_check, 0);
        suite_add_tcase (suite, tcase_check);

        tcase_add_checked_fixture (tcase_change, set_test, free_test);
        tcase_add_test (tcase_change, test_change_volser);
        tcase_set_timeout (tcase_change, 0);
        suite_add_tcase (suite, tcase_change);

        tcase_add_checked_fixture (tcase_get, set_test, free_test);
        tcase_add_test (tcase_get, test_get_volser);
        tcase_set_timeout (tcase_get, 0);
        suite_add_tcase (suite, tcase_get);

        tcase_add_checked_fixture (tcase_vtoc, set_test, free_test);
        tcase_add_test (tcase_vtoc, test_reuse_vtoc);
        tcase_set_timeout (tcase_vtoc, 0);
        suite_add_tcase (suite, tcase_vtoc);

        SRunner *srunner = srunner_create (suite);
        /* When to debug, uncomment this line */
        /* srunner_set_fork_status (srunner, CK_NOFORK); */

        srunner_run_all (srunner, CK_VERBOSE);

        number_failed = srunner_ntests_failed (srunner);
        srunner_free (srunner);
        return (number_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;

#endif
	return 0;
}
