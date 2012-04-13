#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License, Version 1.0 only
# (the "License").  You may not use this file except in compliance
# with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#
#
# Copyright 2012 OmniTI Computer Consulting, Inc.  All rights reserved.
# Use is subject to license terms.
#

VERSION=r151002
BUILDSEND=rpool/kayak_image


BUILDSEND_MP=$(shell zfs get -o value -H mountpoint $(BUILDSEND))

all:	$(BUILDSEND_MP)/miniroot.gz $(BUILDSEND_MP)/kayak_$(VERSION).zfs.bz2
	@ls -l $^

INSTALLS=anon.dtrace.conf anon.system build_image.sh build_zfs_send.sh \
	data/access.log data/boot data/etc data/filelist.ramdisk data/kernel \
	data/known_extras data/mdb data/platform disk_help.sh install_help.sh \
	install_image.sh Makefile net_help.sh README.md \
	sample/000000000000.sample sample/menu.lst.000000000000

TFTP_FILES=$(DESTDIR)/tftpboot/boot/platform/i86pc/kernel/amd64/unix \
	$(DESTDIR)/tftpboot/omnios/kayak/miniroot.gz \
	$(DESTDIR)/tftpboot/menu.lst \
	$(DESTDIR)/tftpboot/pxegrub

WEB_FILES=$(DESTDIR)/var/kayak/kayak/$(VERSION).zfs.bz2

anon.dtrace.conf:
	dtrace -A -q -n'int seen[string]; fsinfo:::/substr(args[0]->fi_pathname,0,1)=="/" && seen[args[0]->fi_pathname]==0/{printf("%d %s %s\n",timestamp/1000000, args[0]->fi_pathname, args[0]->fi_mount);seen[args[0]->fi_pathname]=1;}' -o $@.tmp
	cat /kernel/drv/dtrace.conf $@.tmp > $@
	rm $@.tmp

MINIROOT_DEPS=build_image.sh anon.dtrace.conf anon.system \
	install_image.sh disk_help.sh install_help.sh net_help.sh

$(BUILDSEND_MP)/kayak_$(VERSION).zfs.bz2:	build_zfs_send.sh
	@test -d "$(BUILDSEND_MP)" || (echo "$(BUILDSEND) missing" && false)
	./build_zfs_send.sh -d $(BUILDSEND) $(VERSION)

$(DESTDIR)/tftpboot/pxegrub:	/boot/grub/pxegrub
	cp -p $< $@

$(DESTDIR)/tftpboot/menu.lst:	sample/menu.lst.000000000000
	cp -p $< $@

$(DESTDIR)/tftpboot/boot/platform/i86pc/kernel/amd64/unix:	/platform/i86pc/kernel/amd64/unix
	cp -p $< $@

$(DESTDIR)/tftpboot/omnios/kayak/miniroot.gz:	$(BUILDSEND_MP)/miniroot.gz
	cp -p $< $@

$(BUILDSEND_MP)/miniroot.gz:	$(MINIROOT_DEPS)
	./build_image.sh begin

install-dirs:
	mkdir -p $(DESTDIR)/tftpboot/boot/platform/i86pc/kernel/amd64
	mkdir -p $(DESTDIR)/tftpboot/kayak
	mkdir -p $(DESTDIR)/var/kayak/kayak
	mkdir -p $(DESTDIR)/usr/share/kayak/data
	mkdir -p $(DESTDIR)/var/kayak/log

install-package:	install-dirs
	for file in $(INSTALLS) ; do \
		cp $$file $(DESTDIR)/usr/share/kayak/$$file ; \
	done
	cp http/svc-kayak /lib/svc/method/svc-kayak
	chmod a+x /lib/svc/method/svc-kayakhttp
	cp http/kayak.xml /lib/svc/manifest/kayak.xml

install:	$(TFTP_FILES) $(WEB_FILES) /platform/i86pc/kernel/amd64/unix
	cp -p /platform/i86pc/kernel/amd64/unix $(DESTDIR)/tftpboot/boot/platform/i86pc/kernel/amd64/unix
	cp -p sample/menu.lst.000000000000 $(DESTDIR)/tftpboot/menu.lst
	cp -p $(WEB_FILES) $(DESTDIR)/var/kayak/kayak/
