#!/bin/bash
###############################################################################
# Clue Configuration Manager
#
# Build MCRep/skin.clue package. These particular actions have to run in order
# to build components on demand. These actions typically are executed before to
# create the package.
#
# $Id: buildpart.sh 966 2017-02-13 22:54:04Z stefan $
###############################################################################

# Run TexturePacker for default theme
if [[ "${PKR}" = -*d* ]] || [[ "${PKR}" = -*a* ]]; then
	${BASEPATH}/.tools/TexturePacker -input "${RESDIR}/themes/Defaults" -output "${SRCDIR}/media/Textures.xbt"
fi

# Run TexturePacker for Blue theme
if [[ "${PKR}" = -*b* ]] || [[ "${PKR}" = -*a* ]]; then
	${BASEPATH}/.tools/TexturePacker -input "${RESDIR}/themes/Blue" -output "${SRCDIR}/media/Blue.xbt"
fi

# Run TexturePacker for Crimson theme
if [[ "${PKR}" = -*c* ]] || [[ "${PKR}" = -*a* ]]; then
	${BASEPATH}/.tools/TexturePacker -input "${RESDIR}/themes/Crimson" -output "${SRCDIR}/media/Crimson.xbt"
fi

# Run TexturePacker for Lime theme
if [[ "${PKR}" = -*l* ]] || [[ "${PKR}" = -*a* ]]; then
	${BASEPATH}/.tools/TexturePacker -input "${RESDIR}/themes/Lime" -output "${SRCDIR}/media/Lime.xbt"
fi

# Run TexturePacker for Magenta theme
if [[ "${PKR}" = -*m* ]] || [[ "${PKR}" = -*a* ]]; then
	${BASEPATH}/.tools/TexturePacker -input "${RESDIR}/themes/Magenta" -output "${SRCDIR}/media/Magenta.xbt"
fi


# Stop the execution chain
if [[ "${PKR}" = -*0* ]]; then
	exit 0
elif [[ "${PKR}" = -*1* ]]; then
	exit 1
fi
