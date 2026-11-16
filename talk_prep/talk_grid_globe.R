# Figure for the slide 'WorldPop' (talk.qmd): a lon/lat net around the globe.
# Cells of equal degrees get narrower towards the poles.
# (WorldPop cells are 30" x 30"; here exaggerated to 10 x 10 degrees.)
# Run from the project root: Rscript talk_prep/talk_grid_globe.R
library(sf)
library(tmap)   # World dataset
sf_use_s2(TRUE)

lon0 = 5; lat0 = 22    # centre of the view
ortho = sprintf("+proj=ortho +lon_0=%s +lat_0=%s", lon0, lat0)

# visible hemisphere (a bit less than 90 degrees, to avoid edge artefacts)
centre = st_sfc(st_point(c(lon0, lat0)), crs = 4326)
visible = st_buffer(centre, units::set_units(9900, km))

# net of 10 x 10 degree cells
cell = function(x, y, d = 10) {
	st_polygon(list(cbind(c(x, x + d, x + d, x, x), c(y, y, y + d, y + d, y))))
}
xy = expand.grid(x = seq(-180, 170, by = 10), y = seq(-90, 80, by = 10))
net = st_sfc(mapply(cell, xy$x, xy$y, SIMPLIFY = FALSE), crs = 4326)
net = st_segmentize(net, units::set_units(100, km))

clip = function(g) {
	g = st_intersection(st_make_valid(g), visible)
	g = g[!st_is_empty(g)]
	st_transform(g, ortho)
}

land = clip(st_geometry(World))
net_o = clip(net)
eq_cell = clip(st_segmentize(st_sfc(cell(0, 0), crs = 4326), units::set_units(100, km)))
pa_cell = clip(st_segmentize(st_sfc(cell(0, 45), crs = 4326), units::set_units(100, km)))
paris = st_transform(st_sfc(st_point(c(2.35, 48.85)), crs = 4326), ortho)

R = 6371008
disk = st_buffer(st_sfc(st_point(c(0, 0)), crs = ortho), R)

col_eq = "#E69F00"; col_pa = "#0072B2"

png("figures/worldpop_grid.png", width = 1700, height = 980, res = 150, bg = "white")
par(mar = c(0, 0, 0, 0))
plot(disk, col = "#EAF3F8", border = "grey60", lwd = 1.5,
	 xlim = c(-R * 1.01, R * 2.52), ylim = c(-R * 1.01, R * 1.01), xaxs = "i", yaxs = "i", asp = 1)
plot(land, col = "#D9D9D9", border = NA, add = TRUE)
plot(net_o, col = NA, border = "#7A8A99", lwd = 0.7, add = TRUE)
plot(eq_cell, col = adjustcolor(col_eq, 0.75), border = col_eq, lwd = 2.5, add = TRUE)
plot(pa_cell, col = adjustcolor(col_pa, 0.75), border = col_pa, lwd = 2.5, add = TRUE)
plot(paris, pch = 21, bg = "white", col = "black", cex = 1.1, add = TRUE)

lab = function(g, y, col, l1, l2) {
	p = st_coordinates(st_centroid(g))
	x_txt = R * 1.18
	segments(p[1], p[2], x_txt - R * 0.04, y, col = col, lwd = 2)
	text(x_txt, y, l1, adj = c(0, -0.2), col = col, font = 2, cex = 2.1)
	text(x_txt, y, l2, adj = c(0, 1.2), col = "grey20", cex = 1.8)
}
lab(pa_cell, R * 0.66, col_pa, "Paris", "0.93 × 0.61 km = 0.57 km²")
lab(eq_cell, -R * 0.25, col_eq, "Equator", "0.93 × 0.93 km = 0.86 km²")
text(R * 1.18, -R * 0.7, "Same 30″ × 30″ cell,\nsmaller towards the poles\n(net exaggerated: 10\u00b0 \u00d7 10\u00b0)",
	 adj = c(0, 0.5), col = "grey35", font = 3, cex = 1.6)
dev.off()
