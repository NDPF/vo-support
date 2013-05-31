#!/bin/sh

# Set up test laboratory in tempdir

oneTimeSetUp() {
    tmpdir=./vo-support-test
    echo "Setting up test data in $tmpdir"
    rm -rf $tmpdir
    mkdir $tmpdir
    cp -r testdata/* $tmpdir
    CONFDIR=$tmpdir/conf
    SHAREDIR=$tmpdir/vodata
    OUTPUTDIR=$tmpdir/output
    TESTDIR=`dirname $0`
    mkdir -p $OUTPUTDIR $SHAREDIR $CONFDIR
    export CONFDIR SHAREDIR OUTPUTDIR TESTDIR
    VOSUPPORT="`dirname $0`/../vo-support --confdir $CONFDIR --sharedir $SHAREDIR"
    if ! $VOSUPPORT --help > /dev/null 2>&1 ; then
	echo "Can't run $VOSUPPORT" >&2
	echo "Please check that the perl Site-Configuration library is found, e.g." >&2
	echo 'export PERLLIB=${path_to_site_configuration}/Site-Configuration/lib' >&2
	exit 2
    fi
    # Set the path to find vo-config
    PATH="`dirname $0`/..:$PATH"
    export PATH
    mkdir -p $tmpdir/etc
    mkdir -p $SHAREDIR/modules
    for i in gridmapdir.sh grid-mapfile.sh vomsdir.sh vomses.sh ; do
	install -m 755 ../$i $SHAREDIR/modules/$i
    done
    # export the right environment variables so these modules don't try
    # to edit /etc
    X509_VOMSES=$tmpdir/etc/vomses
    X509_VOMS_DIR=$tmpdir/etc/grid-security/vomses
    GRID_SECURITY_DIR=$tmpdir/etc/grid-security
    VO_SUPPORT_DIR=$CONFDIR
    VO_DATA_DIR=$SHAREDIR
    export X509_VOMSES X509_VOMS_DIR GRID_SECURITY_DIR VO_SUPPORT_DIR VO_DATA_DIR
}

# Custom, reusable assertions

# assertGridMapEntries <VO prefix> <number of mappings>
assertGridMapEntries() {
    for i in `seq -f '%03g' $2` ; do 
	assertTrue "gridmap entry $1$i does not exist" "test -f $GRID_SECURITY_DIR/gridmapdir/$1$i"
    done
}


# listvos

testListVos() {
    $VOSUPPORT list-vos > $OUTPUTDIR/list-vos.out

    # massage output to be generic
    sed -i 's/ VOs in .*//' $OUTPUTDIR/list-vos.out

    diff $TESTDIR/list-vos.out $OUTPUTDIR/list-vos.out || \
	fail "output of list-vos not what's expected"

}

testAddRemoveGridMapdir() {
    $VOSUPPORT add-module gridmapdir.sh || fail "add-module gridmapdir.sh failed"
    assertSame "`ls $GRID_SECURITY_DIR/gridmapdir`" "`cat $TESTDIR/add-gridmapdir.out`"
    assertGridMapEntries pvier 99
    $VOSUPPORT remove-module gridmapdir.sh || fail "remove-module gridmapdir.sh failed"
    assertSame "`ls $GRID_SECURITY_DIR/gridmapdir`" ""
}

# Test that existing mappings will be preserved in the gridmapdir
testRemoveGridMapDirWithLink() {
    $VOSUPPORT add-module gridmapdir.sh || fail "add-module gridmapdir.sh failed"
    # mappings are hard links
    ln $GRID_SECURITY_DIR/gridmapdir/pvier001 $GRID_SECURITY_DIR/gridmapdir/testmapping
    $VOSUPPORT remove-module gridmapdir.sh || fail "remove-module gridmapdir.sh failed"
    assertSame "`ls $GRID_SECURITY_DIR/gridmapdir`" "pvier001
testmapping"
    rm $GRID_SECURITY_DIR/gridmapdir/testmapping
    $VOSUPPORT remove-module gridmapdir.sh || fail "remove-module gridmapdir.sh failed"
    assertSame "`ls $GRID_SECURITY_DIR/gridmapdir`" ""
}

testAddRemoveGridMapfile() {
    $VOSUPPORT add-module grid-mapfile.sh || fail "add-module grid-mapfile.sh failed"
    assertTrue "files $GRID_SECURITY_DIR/voms-grid-mapfile and $TESTDIR/voms-grid-mapfile.out differ" \
        "cmp $GRID_SECURITY_DIR/voms-grid-mapfile $TESTDIR/voms-grid-mapfile.out"
    assertTrue "files $GRID_SECURITY_DIR/groupmapfile and $TESTDIR/groupmapfile.out differ" \
        "cmp $GRID_SECURITY_DIR/groupmapfile $TESTDIR/groupmapfile.out"
    $VOSUPPORT remove-module grid-mapfile.sh || fail "remove-module grid-mapfile.sh failed"
    assertSame "`stat -c '%s' $GRID_SECURITY_DIR/voms-grid-mapfile`" 0
    assertSame "`stat -c '%s' $GRID_SECURITY_DIR/groupmapfile`" 0
}

testVomses() {
    $VOSUPPORT add-module vomses.sh || fail "add-module vomses.sh failed"
    assertTrue "$X509_VOMSES/pvier-voms.grid.sara.nl differs from $SHAREDIR/vos/pvier/vomses/pvier-voms.grid.sara.nl" \
	"cmp $X509_VOMSES/pvier-voms.grid.sara.nl $SHAREDIR/vos/pvier/vomses/pvier-voms.grid.sara.nl"
    $VOSUPPORT remove-module vomses.sh || fail "remove-module vomses.sh failed"
    assertTrue "test ! -e $X509_VOMSES/pvier-voms.grid.sara.nl"
}

testVomsDir() {
    $VOSUPPORT add-module vomsdir.sh || fail "add-module vomsdir.sh failed"
    assertTrue "$X509_VOMS_DIR/pvier/voms.grid.sara.nl.lsc differs from $SHAREDIR/vos/pvier/voms.grid.sara.nl.lsc" \
	"cmp $X509_VOMS_DIR/pvier/voms.grid.sara.nl.lsc $SHAREDIR/vos/pvier/voms.grid.sara.nl.lsc"
    $VOSUPPORT remove-module vomsdir.sh || fail "remove-module vomsdir failed"
    assertTrue "test ! -e $X509_VOMS_DIR/pvier"
}

testConfigureVO() {

    $VOSUPPORT configure-vo ops > $OUTPUTDIR/configure-vo.out

    # Inspect the side-effect of having the configuration file
    # installed now
    assertTrue "[ -e $CONFDIR/vos/ops.conf ] && cmp $CONFDIR/vos/ops.conf $SHAREDIR/vos/ops/ops.conf"
    assertGridMapEntries ops 99
    assertTrue "ops lcgadmin role not in voms-grid-mapfile" \
	"grep -q '\"/ops/Role=lcgadmin\"  *\\.ops' $GRID_SECURITY_DIR/voms-grid-mapfile"
    assertTrue "ops pilot role not in voms-grid-mapfile" \
	"grep -q '\"/ops/Role=pilot\"  *\\.ops' $GRID_SECURITY_DIR/voms-grid-mapfile"
    assertTrue "ops lcgadmin role not in groupmapfile" \
	"grep -q '\"/ops/Role=lcgadmin\"  *ops' $GRID_SECURITY_DIR/groupmapfile"
    assertTrue "ops pilot role not in groupmapfile" \
	"grep -q '\"/ops/Role=pilot\"  *ops' $GRID_SECURITY_DIR/groupmapfile"
    assertTrue "ops-lcg-voms.cern.ch vomses file missing" \
	"cmp $X509_VOMSES/ops-lcg-voms.cern.ch $SHAREDIR/vos/ops/vomses/ops-lcg-voms.cern.ch"
    assertTrue "ops-voms.cern.ch vomses file missing" \
	"cmp $X509_VOMSES/ops-voms.cern.ch $SHAREDIR/vos/ops/vomses/ops-voms.cern.ch"
    assertTrue "lcg-voms.cern.ch.lsc missing" \
	"cmp $X509_VOMS_DIR/ops/lcg-voms.cern.ch.lsc $SHAREDIR/vos/ops/lcg-voms.cern.ch.lsc"
    assertTrue "voms.cern.ch.lsc missing" \
	"cmp $X509_VOMS_DIR/ops/voms.cern.ch.lsc $SHAREDIR/vos/ops/voms.cern.ch.lsc"
}


testDeconfigureVO() {
    $VOSUPPORT deconfigure-vo ops > $OUTPUTDIR/deconfigure-vo.out 2> $OUTPUTDIR/deconfigure-vo.err

    assertTrue 'ops.conf not renamed to ops.conf-disabled' \
	"[ -e $CONFDIR/vos/ops.conf-disabled -a ! -e $CONFDIR/vos/ops.conf ]"
    $VOSUPPORT remove-module gridmapdir.sh || fail "remove-module gridmapdir.sh failed"
    assertSame "`ls $GRID_SECURITY_DIR/gridmapdir/ | grep ops`" ""
    assertTrue "ops lcgadmin role not removed from voms-grid-mapfile" \
	"! grep -q '\"/ops/Role=lcgadmin\"' $GRID_SECURITY_DIR/voms-grid-mapfile"
    assertTrue "ops pilot role not removed from voms-grid-mapfile" \
	"! grep -q '\"/ops/Role=pilot\"' $GRID_SECURITY_DIR/voms-grid-mapfile"
    assertTrue "ops lcgadmin role not removed from groupmapfile" \
	"! grep -q '\"/ops/Role=lcgadmin\"' $GRID_SECURITY_DIR/groupmapfile"
    assertTrue "ops pilot role not removed from groupmapfile" \
	"! grep -q '\"/ops/Role=pilot\"' $GRID_SECURITY_DIR/groupmapfile"
    assertTrue "left behind ops-lcg-voms.cern.ch"  "[ ! -e $X509_VOMSES/ops-lcg-voms.cern.ch ]"
    assertTrue "left behind ops-voms.cern.ch" "[ ! -e $X509_VOMSES/ops-voms.cern.ch ]"
    assertTrue "left behind lcg-voms.cern.ch.lsc" "[ ! -e $X509_VOMS_DIR/ops/lcg-voms.cern.ch.lsc ]"
    assertTrue "left behind voms.cern.ch.lsc" "[ ! -e $X509_VOMS_DIR/ops/voms.cern.ch.lsc ]"

}

. ./shunit2