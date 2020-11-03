SHELL:=/bin/bash
ROOT=$(shell pwd)
NAME=$(shell basename $(ROOT))

ifndef VERBOSE
.SILENT:
endif

OUTDIR=
SYSDIR=sys
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


# Deploy resources (sources and/or system files) into the remote RPI container.
deploy:
ifneq ($(RPIHOST),)
ifeq ($(shell [[ -d $(ROOT)/$(SRCDIR) ]] && echo -n yes),yes)
	/usr/bin/rsync -a -zvh --progress --delete -e ssh $(ROOT)/$(SRCDIR)/ root@$(RPIHOST):$/clue/.kodi/addons/$(NAME)
endif
ifeq ($(shell [[ -d $(ROOT)/$(SYSDIR) ]] && echo -n yes),yes)
	/usr/bin/scp -r $(ROOT)/$(SYSDIR)/* root@$(RPIHOST):$/clue/
endif
else
	echo "Your remote RPi device should have SSH service enabled, local public SSH key \
	already shared and RPIHOST local variable setted up with the host name or \
	IP address of the RPi device!"
endif


# Build addon package in deployment format
build:
	xmlstarlet edit -L -P -u "//addon/@version" -v "$(NEXT_VER)" $(ROOT)/$(SRCDIR)/addon.xml
	mkdir -p $(OUTDIR) $(OUTDIR)/$(TARGETS)
	cp -rf ${SRCDIR}/* $(OUTDIR)/
	cp -rf LICENSE $(OUTDIR)/
	cd $(OUTPUT) && /usr/bin/zip -q -y -r $(NAME).zip $(NAME) && cd $(ROOT)
	mv -f $(OUTPUT)/$(NAME).zip $(OUTPUT)/targets/$(NAME).zip


# Publish the last build in the addon repository
publish:
ifeq ($(shell [[ -f $(OUTPUT)/targets/$(NAME).zip ]] && echo -n yes),yes)
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
else
	echo "Repository location is not specified in PUBLISH variable. Set it up and try again!"
endif


# Setup and push the new versioning label in the GitHUB
version:
	git add .
	git commit -m "Release $(DISTRO_VER)"
	git push
	git tag "$(DISTRO_VER)"
	git push origin --tags


# Create a complete release: new build, publish it in the repository, update the versioning
release: build publish version


# Clean-up the release
clean:
	rm -rf $(OUTDIR)


# Clean-up all build distributions, cache and stamps
cleanall:
	rm -rf $(OUTDIR)/* $(OUTDIR)/.stamp $(OUTDIR)/.ccache
