# Map for the slide 'Trick: invisible hover layer' (talk.qmd): map 1b, but with the hitboxes made visible.
# Reuses the code of talk_examples.R up to map 1b (the expressions that print or save maps are skipped).
# Run from the project root: Rscript talk_prep/talk_hitbox.R
library(tmap)
library(tmap.mapgl)

ex = parse("talk_prep/talk_examples.R")
for (e in ex) {
	txt = paste(deparse(e), collapse = "\n")
	if (grepl("^m1b = ", txt)) break
	if (grepl("^save_map(_center)?\\(|^m1a$", txt)) next
	eval(e, envir = globalenv())
}

# Zoomed in on Paris and surroundings. Used for a screenshot (figures/europe_hitbox.png):
# node talk_prep/screenshot.mjs file://$PWD/maps/europe_hitbox.html figures/europe_hitbox.png 15000 1000 650
bb = st_bbox(c(xmin = 1.3, ymin = 48.4, xmax = 3.5, ymax = 49.4), crs = 4326)

m = tm_shape(pop_eu, bbox = bb) +
	tm_polygons_3d(
		height = "dens",
		fill = "dens", fill.scale = dens_scale,
		lwd = 0, popup = FALSE, fill.legend = tm_legend_hide(),
		options = eu3d) +   # same heights as map 1b
	tm_shape(urban) +
	tm_polygons(fill = "#00E5FF", fill_alpha = 0.5, col = "#00A0CC", lwd = 2, hover = "label", popup = FALSE) +
	tm_basemap("ofm.bright") +
	tm_maplibre(pitch = 30, zoom = 6.0, bearing = -35)
save_map(m, "europe_hitbox")

# the hover areas: how many, and the smallest cities
cat(nrow(urban), "hover areas; cities with < 250,000 inhabitants:", sum(towns$total < 2.5e5), "\n")
print(head(towns[order(towns$total), c("name", "total")], 10))
