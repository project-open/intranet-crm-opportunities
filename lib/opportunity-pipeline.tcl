# /packages/intranet-crm-opportunities/lib/opportunity-pipeline.tcl
#
# Copyright (C) 2014 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ----------------------------------------------------------------------
# 
# ---------------------------------------------------------------------

# The following variables are expected in the environment
# defined by the calling /tcl/*.tcl libary:
#	diagram_width
#	diagram_height
#       diagram_caption


# Create a random ID for the diagram
set diagram_id "sales_pipeline_[expr {round(rand() * 100000000.0)}]"

set default_currency [im_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
set value_l10n [lang::message::lookup "" intranet-core.Value Value]
set prob_l10n [lang::message::lookup "" intranet-core.Probability Probability]

set x_axis 0
set y_axis 0
set color "yellow"
set diameter 5
set title ""
