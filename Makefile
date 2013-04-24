#  File: vo-support/Makefile
#  Author: Dennis van Dok <dennisvd@nikhef.nl>
#
#  Copyright 2012  Stichting FOM
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# This package is pretty trivial to set up and install.
# There is no source code to compile; it only contains
# a couple of scripts.
# This Makefile respects the $DESTDIR convention that
# is commonly used in the GNU build system.

# the relevant variables
prefix = /usr
datadir = $(prefix)/share
sbindir = $(prefix)/sbin
DESTDIR =

# These variables should not be changed by the user

package = vo-support
version = 0.5
triggers = vomsdir.sh vomses.sh gridmapdir.sh grid-mapfile.sh
triggersrc = vomsdir.sh vomses.sh gridmapdir.sh.in grid-mapfile.sh.in
scripts = maintainerscript-helpers.sh config-helpers.sh
utils = vo-config vo-support
utilssources = vo-config.pl.in vo-support.pl.in
distfiles = Makefile LICENSE Changes vo-support.spec $(scripts) $(triggersrc) $(utilssources)

.PHONY: install build installdirs install-scripts install-triggers

build:
	@echo "build done. Run 'make install' to finish the installation"

installdirs:
	mkdir -p $(DESTDIR)/$(datadir)/$(package)/scriptlets
	mkdir -p $(DESTDIR)/$(datadir)/vo-support/triggers/install
	mkdir -p $(DESTDIR)/$(datadir)/vo-support/triggers/remove
	mkdir -p $(DESTDIR)/$(datadir)/man/man1
	mkdir -p $(DESTDIR)/$(sbindir)

%.sh: %.sh.in
	$(do_subst) $< > $@

%: %.pl.in
	$(do_subst) $< > $@
	chmod +x $@

install-mans: installdirs $(utils)
	for i in $(utils) ; do \
	    pod2man -c "VO SUPPORT" $$i $(DESTDIR)/$(datadir)/man/man1/$$i.1 ; \
	done

install-scripts: installdirs
	install -m 644 maintainerscript-helpers.sh $(DESTDIR)/$(datadir)/$(package)/scriptlets/

install-utils: installdirs $(utils)
	for i in $(utils) ; do \
	    install -m 755 $$i $(DESTDIR)/$(sbindir)/ ; \
	done

install-triggers: installdirs $(triggers)
	for i in $(triggers) ; do \
	    install -m 755 $$i $(DESTDIR)/$(datadir)/vo-support/triggers/install/ ; \
	    install -m 755 $$i $(DESTDIR)/$(datadir)/vo-support/triggers/remove/ ; \
	done

install: install-scripts install-utils install-triggers install-mans

dist:
	rm -rf _dist/
	mkdir -p _dist/$(package)-$(version)
	install -m 644 $(distfiles) _dist/$(package)-$(version)
	tar cCfz _dist $(package)-$(version).tar.gz $(package)-$(version)

clean:
	rm -f gridmapdir.sh grid-mapfile.sh vo-config vo-support

do_subst = sed -e 's,[@]sbindir@,$(sbindir),' \
               -e 's,[@]datadir@,$(datadir),'
