.PHONY: true

distfiles = runtests.sh manual-test.sh shunit2 NOTES.org \
	add-gridmapdir.out groupmapfile.out list-vos.out \
	Makefile voms-grid-mapfile.out

testdata = conf/vos/pvier.conf \
	vodata/vos/ops/vomses/ops-voms.cern.ch \
	vodata/vos/ops/vomses/ops-lcg-voms.cern.ch \
	vodata/vos/ops/ops.conf \
	vodata/vos/ops/info \
	vodata/vos/ops/AUP \
	vodata/vos/ops/lcg-voms.cern.ch.lsc \
	vodata/vos/ops/voms.cern.ch.lsc \
	vodata/vos/pvier/voms.grid.sara.nl.lsc \
	vodata/vos/pvier/vomses/pvier-voms.grid.sara.nl \
	vodata/vos/pvier/info \
	vodata/vos/pvier/AUP \
	vodata/vos/pvier/pvier.conf \

test:
	./runtests.sh

NOTES.pdf: NOTES.org
	emacs -q --batch NOTES.org -f org-export-as-pdf

dist:
	mkdir $(distdir)/test
	cp -r $(distfiles) $(distdir)/test
	for i in $(testdata) ; do \
	    mkdir -p $(distdir)/test/`dirname $$i` ; \
	    install -m 644 testdata/$$i $(distdir)/test/`dirname $$i` ; \
	done
