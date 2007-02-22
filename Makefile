# Simplified Makefile for devscripts

PL_FILES = bts.pl checkbashisms.pl cvs-debuild.pl dd-list.pl debchange.pl \
	debcommit.pl debdiff.pl debi.pl debpkg.pl debuild.pl dget.pl \
	dpkg-depcheck.pl dscverify.pl grep-excuses.pl mass-bug.pl \
	plotchangelog.pl rc-alert.pl rmadison.pl svnpath.pl

SH_FILES = annotate-output.sh archpath.sh cvs-debi.sh cvs-debrelease.sh \
	deb-reversion.sh debclean.sh debrelease.sh debrsign.sh debsign.sh \
	dpkg-genbuilddeps.sh mergechanges.sh nmudiff.sh pts-subscribe.sh \
	tagpending.sh uscan.sh uupdate.sh whodepends.sh who-uploads.sh \
	wnpp-alert.sh

LIBS = libvfork.so.0

PERL_MODULES = Devscripts

CWRAPPERS = debpkg-wrapper

SCRIPTS = $(PL_FILES:.pl=) $(SH_FILES:.sh=)
EXAMPLES = conf.default

GEN_MAN1S = bts.1 debcommit.1 deb-reversion.1 dget.1 mass-bug.1 \
	rmadison.1 svnpath.1
MANS_fr_DIR = po4a/fr
GEN_MAN1S_fr = $(patsubst %,$(MANS_fr_DIR)/%,$(GEN_MAN1S))
MAN1S_fr = $(subst $(MANS_fr_DIR)/,,$(wildcard $(MANS_fr_DIR)/*.1))

BINDIR = /usr/bin
LIBDIR = /usr/lib/devscripts
EXAMPLES_DIR = /usr/share/devscripts
PERLMOD_DIR = /usr/share/devscripts
BIN_LIBDIR = /usr/lib/devscripts

all: $(SCRIPTS) $(GEN_MAN1S) $(EXAMPLES) $(LIBS) $(CWRAPPERS) translated_manpages

version:
	rm -f version
	dpkg-parsechangelog | perl -ne '/^Version: (.*)/ && print $$1' \
	    > version

%: %.sh version
	if grep -q '^#! */bin/sh' $<; then \
	  echo "$< is a /bin/sh script, not a bash script!" >&2; \
	  exit 1; \
	fi
	rm -f $@ $@.tmp
	VERSION=`cat version` && sed -e "s/###VERSION###/$$VERSION/" $< \
	    > $@.tmp && chmod +x $@.tmp && mv $@.tmp $@
	bash -n $@

%: %.pl version
	rm -f $@ $@.tmp
	VERSION=`cat version` && sed -e "s/###VERSION###/$$VERSION/" $< \
	    > $@.tmp && chmod +x $@.tmp && mv $@.tmp $@
	perl -c $@

conf.default: conf.default.in version
	rm -f $@ $@.tmp
	VERSION=`cat version` && sed -e "s/###VERSION###/$$VERSION/" $< \
	    > $@.tmp && mv $@.tmp $@

%.1: %.pl
	pod2man --center=" " --release="Debian Utilities" $< > $@

%.1: %.dbk
	xsltproc --nonet -o $@ \
	  /usr/share/sgml/docbook/stylesheet/xsl/nwalsh/manpages/docbook.xsl $<

translated_manpages:
	$(MAKE) -C po4a/
	# These may or may not have been successfully made; we don't stop
	# building the rest of the package in such a case
	for i in $(GEN_MAN1S_fr); do \
	    $(MAKE) $$i || true; \
	done
	touch translated_manpages

clean_translated_manpages:
	# Update the POT/POs and remove the translated man pages
	$(MAKE) -C po4a/ clean
	rm -f translated_manpages

libvfork.o: libvfork.c
	$(CC) -fPIC -D_REENTRANT $(CFLAGS) -c $<

libvfork.so.0: libvfork.o
	$(CC) -shared $< -lc -Wl,-soname -Wl,libvfork.so.0 -o $@

clean: clean_translated_manpages
	rm -f version conf.default $(SCRIPTS) $(GEN_MAN1S) $(SCRIPT_LIBS) \
	    $(GEN_MAN1S_fr) $(CWRAPPERS) libvfork.o libvfork.so.0

install: all
	cp $(SCRIPTS) $(DESTDIR)$(BINDIR)
	cp $(LIBS) $(DESTDIR)$(LIBDIR)
	cp -a $(PERL_MODULES) $(DESTDIR)$(PERLMOD_DIR)
	# Special treatment for debpkg
	mv $(DESTDIR)$(BINDIR)/debpkg $(DESTDIR)$(PERLMOD_DIR)
	cp debpkg-wrapper $(DESTDIR)$(BINDIR)/debpkg
	cp $(EXAMPLES) $(DESTDIR)$(EXAMPLES_DIR)
#	-find $(DESTDIR) -type d -name '.svn' -exec rm -r \{\} \;
#	-find $(DESTDIR) -type d -name 'CVS' -exec rm -r \{\} \;

