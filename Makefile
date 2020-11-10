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

test: deploy


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


# Display the help text
help:
	echo -e "\
\nSYNOPSIS\n\
       make deploy | build | publish | version | release\n\
       make clean | cleanall\n\
       make help\n\
\nDESCRIPTION\n\
    Executes one of the make tasks defined through this Makefile flow, according \n\
    to the scope of this project.\n\n\
    deploy | test\n\
                  deploy addon resources on a remote test system (RPi device)\n\
    build\n\
                  build the addon package along to the new version of it\n\
    publish\n\
                  install/publish the addon (already built) on the repository file\n\
                  system (it has to be already mounted to the development environment)\n\
    version\n\
                  Commit the new release changes into GitHub repository\n\
    clean\n\
                  cleanup the build resources within the output location\n\
    cleanall\n\
                  Clean-up all resources from the output location (related or nor directly\n\
                  connected to the addon build process\n\
    release\n\
                  Build the system release for the current DEVICE\n\
    help\n\
                  Shows this text\n\
\n\
    There are couple of system variables that should be be set in order to drive the execution \n\
    of particular tasks:\n\
    PUBLISH\n\
                  Indicates the remote file system mounted to the local development environment, \n\
                  in order to deploy releases in the repository container.\n\
    OUTPUT\n\
                  Describes the local file system location where the build process will be  \n\
                  executed. Default value is '$(ROOT)/../Clue-out'\n\
    RPIHOST\n\
                  Indicates the host name or the IP address of the test system in order to deploy\n\
                  addon resources through deploy or test task. The remote system should have SSH \n\
                  service enabled and active.\n\
\n\
EXAMPLES\n\
       deploy the entire distribution on a testing environment ('deploy' task is default)\n\
       > make\n\
       > make deploy\n\n\
       build the entire distribution ('build' make task is default)\n\
       > make build\n\n\
       publish new release in the addon repository\n\
       > make publish\n\n\
       make complete addon release: build it, publish it and commit the changes on GitHub\n\
       > make release\n\n\
" | more