#! /usr/bin/env python

import os
import logging
from gimpfu import *

def run(color) :
	logger = logging.getLogger(__name__)
	for image in gimp.image_list():
		try:
			pdb.gimp_convert_rgb(image)
		except BaseException as be:
			logger.info("Unexpected error: %s" %str(be))
		pdb.script_fu_neon_logo_alpha(image, image.active_layer , 30, "#000000", color, 0)
		layer = image.layers[2]
		image.remove_layer(layer)
		layer = image.layers[1]
		pdb.gimp_layer_set_visible(layer, False)
		filepath_png = os.path.splitext(image.filename)[0] + ".png"
		pdb.file_png_save_defaults(image, image.layers[0], filepath_png, image.filename)

register(
	"icon-builder",
	"Icon Builder for Clue Theme",
	"Create theme icons from standard icon library",
	"Clue",
	"Clue Media Experience",
	"2019",
	"<Toolbox>/Xtns/Languages/Python-Fu/Icon Builder",
	"RGB*, GRAY*",
	[
		(PF_COLOR, "color", "Theme Color", "#dc143c")
	],
	[],
	run)

main()
