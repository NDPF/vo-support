# Source this file to run some manual tests
# Test data in ./vo-support-test. Remove this
# directory to start with a fresh slate.

# This script is essentially the same as onTimeSetUp,
# except the test directory isn't overwritten.
tmpdir=./vo-support-test-manual
test -d $tmpdir || cp -r testdata $tmpdir

CONFDIR=$tmpdir/conf
SHAREDIR=$tmpdir/vodata
OUTPUTDIR=$tmpdir/output
CONFDIR=$tmpdir/conf
SHAREDIR=$tmpdir/vodata
OUTPUTDIR=$tmpdir/output
TESTDIR=`dirname $0`
test -d $OUTPUTDIR || mkdir $OUTPUTDIR
export CONFDIR SHAREDIR OUTPUTDIR TESTDIR
VOSUPPORT="$TESTDIR/../vo-support --confdir $CONFDIR --sharedir $SHAREDIR"
if ! $VOSUPPORT --help > /dev/null 2>&1 ; then
	echo "Can't run $VOSUPPORT" >&2
	echo "Please check that the perl Site-Configuration library is found, e.g." >&2
	echo 'export PERLLIB=${path_to_site_configuration}/Site-Configuration/lib' >&2
fi

# Make sure the build dir is in the path
if ! echo $PATH | grep -qF "$TESTDIR/..:" ; then
    PATH="$TESTDIR/..:$PATH"
fi
export PATH
mkdir -p $tmpdir/etc
for i in gridmapdir.sh grid-mapfile.sh vomsdir.sh vomses.sh ; do
	install -m 755 $TESTDIR/../$i $SHAREDIR/modules/$i
done
# export the right environment variables so these modules don't try
# to edit /etc
X509_VOMSES=$tmpdir/etc/vomses
X509_VOMS_DIR=$tmpdir/etc/grid-security/vomsdir
GRID_SECURITY_DIR=$tmpdir/etc/grid-security
mkdir -p $GRID_SECURITY_DIR
VO_SUPPORT_DIR=$CONFDIR
VO_DATA_DIR=$SHAREDIR
export X509_VOMSES X509_VOMS_DIR GRID_SECURITY_DIR VO_SUPPORT_DIR VO_DATA_DIR
