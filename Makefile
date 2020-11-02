SHELL:=/bin/bash
ROOT=$(shell pwd)
NAME=$(shell basename $(ROOT))

ifndef VERBOSE
.SILENT:
endif

OUTDIR=
SRCDIR=src
RESDIR=res

ifeq ($(OUTPUT),)
	export OUTPUT=$(ROOT)/../Clue-out
endif

ifeq ($(PUBLISH),)
	export PUBLISH=~/AMSD/Web/clue/repos/addons
endif

OUTDIR=$(OUTPUT)/$(NAME)
DISTRO_VER=$(shell xmlstarlet sel -t -v "//addon/@version" $(ROOT)/$(SRCDIR)/addon.xml)
DISTRO_REL=$(shell echo "$(DISTRO_VER)" | cut -f1 -d".")
DISTRO_MAJ=$(shell echo "$(DISTRO_VER)" | cut -f2 -d".")
DISTRO_MIN=$(shell echo "$(DISTRO_VER)" | cut -f3 -d".")
NEXT_MIN=$(shell python -c "print int($(DISTRO_MIN)) + 1")
NEXT_VER="${DISTRO_REL}.${DISTRO_MAJ}.${NEXT_MIN}"

FILE1=/usr/bin/perl
FILE2=/nofile

# Build addon package in deployment format
build:
	xmlstarlet edit -L -P -u "//addon/@version" -v "$(NEXT_VER)" $(ROOT)/$(SRCDIR)/addon.xml
	mkdir -p $(OUTDIR) $(OUTDIR)/$(TARGETS)
	cp -rf ${SRCDIR}/* $(OUTDIR)/
	cp -rf LICENSE $(OUTDIR)/
	cd $(OUTPUT) && /usr/bin/zip -q -y -r $(NAME).zip $(NAME) && cd $(ROOT)
	mv -f $(OUTPUT)/$(NAME).zip $(OUTPUT)/targets/$(NAME).zip


test:
ifneq ($(RPIHOST),)
	rsync -a -zvh --progress --delete -e ssh $(ROOT)/$(SRCDIR)/ root@$(RPIHOST):$/clue/.kodi/addons/$(NAME)
else
	echo "Your remote RPi device should have SSH service enabled, local public SSH key \
	already shared and RPIHOST local variable setted up with the host name or \
	IP address of the RPi device!"
endif


publish: build
ifneq ($(PUBLISH),)
	# deploy package resources, rebuild repository descriptor
ifeq ($(shell [[ -f $(PUBLISH)/addons.xml ]] && echo -n yes),yes)
	# define location and copy meta files
	$(shell [[ ! -d $(PUBLISH)/$(NAME) ]] && mkdir $(PUBLISH)/$(NAME))
	cp -f $(ROOT)/$(SRCDIR)/addon.xml $(PUBLISH)/$(NAME)/
	$(shell [[ -f $(ROOT)/$(SRCDIR)/icon.png ]] && cp -f  $(ROOT)/$(SRCDIR)/icon.png $(PUBLISH)/$(NAME)/)
	$(shell [[ -f $(ROOT)/$(SRCDIR)/fanart.jpg ]] && cp -f  $(ROOT)/$(SRCDIR)/fanart.jpg $(PUBLISH)/$(NAME)/)
	$(shell [[ -f $(ROOT)/$(SRCDIR)/changelog.txt ]] && cp -f $(ROOT)/$(SRCDIR)/changelog.txt $(PUBLISH)/$(NAME)/)
	cp -f $(OUTPUT)/targets/$(NAME).zip $(PUBLISH)/$(NAME)/$(NAME)-$(DISTRO_VER).zip
	md5sum $(PUBLISH)/$(NAME)/$(NAME)-$(DISTRO_VER).zip > $(PUBLISH)/$(NAME)/$(NAME)-$(DISTRO_VER).zip.md5
	python $(PUBLISH)/xmlgen.py
else
	echo "Repository location described by PUBLISH variable is not correct (doesn't \
	contain the expected structure and remote resources)!"
endif
else
	echo "Repository location is not specified in PUBLISH variable. Set it up and try again!"
endif

clean:
	rm -rf $(OUTDIR)


# Clean-up all build distributions, cache and stamps
cleanall:
	rm -rf $(OUTDIR)/* $(OUTDIR)/.stamp $(OUTDIR)/.ccache
