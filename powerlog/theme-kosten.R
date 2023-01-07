#########################################################################
#Theme für ggplot laden, damit alle Plots denselben Style haben
#########################################################################

# text size für geom_text()
bartextsize <- 8

theme_kosten <- function(base_size = 24, base_family = "") {
				  theme(
	# Elements in this first block aren't used directly, but are inherited
	# by others
	line =               element_line(colour = "black", size = 0.5, linetype = 1,
	lineend = "butt"),
	rect =               element_rect(fill = "white", colour = "black", size = 0.5, linetype = 1),
	text =               element_text(family = base_family, face = "plain",
																		colour = "black", size = base_size,
																		hjust = 0.5, vjust = 0.5, angle = 0, lineheight = 0.9, margin=margin(), debug=FALSE),
	axis.text =          element_text(size = rel(0.8), colour = "grey50", margin=margin(), debug=FALSE),
	strip.text =         element_text(size = rel(0.8), margin=margin(), debug=FALSE),
	axis.line =          element_blank(),
	axis.text.x =        element_text(hjust=0.5, vjust = 0.5, size=base_size*0.9, lineheight=0.9, margin=margin(), debug=FALSE),
	axis.text.y =        element_text(hjust = 1, size = base_size * 0.9, lineheight = 0.9, margin=margin(), debug=FALSE),
	axis.ticks =         element_line(colour = "grey50"),
	axis.title.x =       element_text(margin=margin(), debug=FALSE),
	axis.title.y =       element_text(angle = 90, vjust = 0.35, margin=margin(), debug=FALSE),
	axis.ticks.length =  unit(0.15, "cm"),
	#axis.ticks.margin =  unit(0.1, "cm"),

	legend.background =  element_rect(colour = NA),
	legend.spacing = 		 unit(0.2, "cm"),
	legend.key =         element_rect(fill = "grey95", colour = "white"),
	legend.key.size =    unit(1.2, "lines"),
	legend.key.height =  NULL,
	legend.key.width =   NULL,
	legend.text =        element_text(size = rel(0.8), margin=margin(), debug=FALSE),
	legend.text.align =  NULL,
	legend.title =       element_text(size = rel(0.8), face = "bold", hjust = 0, margin=margin(), debug=FALSE),
	legend.title.align = NULL,
	legend.position =    "right",
	legend.direction =   NULL,
	legend.justification = "center",
	legend.box =         NULL,

	panel.background =   element_rect(fill = "grey90", colour = NA),
	panel.border =       element_rect(fill = NA, colour="grey50"), 
	panel.grid.major =   element_line(colour = "grey90", size = 0.2),
	panel.grid.major.y = element_line(colour="black", linetype="dashed"),
	panel.grid.minor =   element_line(colour = "grey95", size = 0.25),
	panel.spacing =      unit(0.25, "lines"),

	strip.background =   element_rect(fill = "grey80", colour = NA),
	strip.text.x =       element_text(margin=margin(), debug=FALSE),
	strip.text.y =       element_text(angle = -90, margin=margin(), debug=FALSE),

	plot.background =    element_rect(colour = "white"),
	plot.title =         element_text(size = rel(1.2), margin=margin(), debug=FALSE),
	plot.margin =        unit(c(1, 1, 0.5, 0.5), "lines"),

	complete = TRUE
)
}
