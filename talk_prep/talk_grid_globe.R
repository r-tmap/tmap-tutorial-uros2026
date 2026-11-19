# Figure for the slide 'WorldPop' (talk.qmd), three panels:
# 1. a lon/lat net around the globe, with one cell (near Paris) highlighted
# 2. the WorldPop microdata of that cell: 960 x 960 cells of 30 arc seconds
# 3. the same cell aggregated to the cells of map 1a (15 x 15)
# - The net is drawn at 8 x 8 degrees, so that one net cell holds exactly 15 x 15 cells of
#   map 1a (64 x 64 WorldPop cells of 30 arc seconds = 0.533 degree, see talk_examples.R).
# - Cells of equal degrees get narrower towards the poles: the zoom panel is drawn in its true
#   shape (width / height = cos(latitude)).
# - The map 1a cells in the zoom panel are coloured by population density, with the colour
#   scale of map 1a.
# Run from the project root: Rscript talk_prep/talk_grid_globe.R
library(sf)
library(terra)
library(tmap)   # World dataset
sf_use_s2(TRUE)

lon0 = 5; lat0 = 22    # centre of the view
ortho = sprintf("+proj=ortho +lon_0=%s +lat_0=%s", lon0, lat0)
d = 8                  # size of the net cells (degrees)

# visible hemisphere (a bit less than 90 degrees, to avoid edge artefacts)
centre = st_sfc(st_point(c(lon0, lat0)), crs = 4326)
visible = st_buffer(centre, units::set_units(9900, km))

cell = function(x, y) {
	st_polygon(list(cbind(c(x, x + d, x + d, x, x), c(y, y, y + d, y + d, y))))
}
xy = expand.grid(x = seq(-184, 176, by = d), y = seq(-88, 80, by = d))
net = st_sfc(mapply(cell, xy$x, xy$y, SIMPLIFY = FALSE), crs = 4326)
net = st_segmentize(net, units::set_units(100, km))

clip = function(g) {
	g = st_intersection(st_make_valid(g), visible)
	g = g[!st_is_empty(g)]
	st_transform(g, ortho)
}
to_ortho = function(lon, lat) st_coordinates(st_transform(st_sfc(st_point(c(lon, lat)), crs = 4326), ortho))

pa_x = 0; pa_y = 48    # the zoomed net cell: 0-8 E, 48-56 N (contains Paris)

land = clip(st_geometry(World))
net_o = clip(net)
pa_cell = clip(st_segmentize(st_sfc(cell(pa_x, pa_y), crs = 4326), units::set_units(100, km)))
paris = to_ortho(2.35, 48.85)

# population density: microdata and the map 1a cells within the zoomed net cell
pop = rast("data/global_pop_2025_1km.tif")
pop_c = crop(pop, ext(pa_x, pa_x + d, pa_y, pa_y + d))            # 960 x 960 cells
pop_a = aggregate(pop_c, fact = 64, fun = "sum", na.rm = TRUE)   # 15 x 15 cells
breaks = c(0, 25, 100, 250, 500, 1000, 2500, 5000, Inf)
pal = cols4all::c4a("ocean.thermal", 8, reverse = TRUE)
col_sea = "#EAF3F8"
dens_cols = function(r) {
	dens = r / cellSize(r, unit = "km")
	dm = matrix(values(dens), nrow = nrow(r), byrow = TRUE)       # row 1 = north
	cm = matrix(pal[cut(dm, breaks, include.lowest = TRUE)], nrow = nrow(r))
	cm[is.na(dm)] = col_sea                                       # sea
	cm[!is.na(dm) & dm == 0] = "#F4F4F4"                          # land, no inhabitants
	cm
}
cm_micro = dens_cols(pop_c)
cm_agg = dens_cols(pop_a)
n = nrow(pop_a)

R = 6371008
disk = st_buffer(st_sfc(st_point(c(0, 0)), crs = ortho), R)

col_pa = "#0072B2"

# panels 2 and 3 (true shape: width / height = cos(52 degrees))
ph = R * 1.7
pw = ph * cos((pa_y + d / 2) * pi / 180)
gap = R * 0.32
py0 = -R * 0.78; py1 = py0 + ph
p2x0 = R * 1.3; p2x1 = p2x0 + pw
p3x0 = p2x1 + gap; p3x1 = p3x0 + pw
pz = function(x0) c(x0 + (2.35 - pa_x) / d * pw, py0 + (48.85 - pa_y) / d * ph)

png("figures/worldpop_grid.png", width = 2400, height = 1000, res = 150, bg = "white")
par(mar = c(0, 0, 0, 0))
plot(disk, col = col_sea, border = "grey60", lwd = 1.5,
	 xlim = c(-R * 1.01, p3x1 + R * 0.02), ylim = c(-R * 1.01, R * 1.07), xaxs = "i", yaxs = "i", asp = 1)
plot(land, col = "#D9D9D9", border = NA, add = TRUE)
plot(net_o, col = NA, border = "#7A8A99", lwd = 0.7, add = TRUE)
plot(pa_cell, col = adjustcolor(col_pa, 0.75), border = col_pa, lwd = 2.5, add = TRUE)
points(paris[1], paris[2], pch = 21, bg = "white", col = "black", cex = 1.1)

# connectors: corners of the net cell on the globe -> corners of panel 2
c_tr = to_ortho(pa_x + d, pa_y + d); c_br = to_ortho(pa_x + d, pa_y)
segments(c(c_tr[1], c_br[1]), c(c_tr[2], c_br[2]), p2x0, c(py1, py0), col = col_pa, lwd = 1.5, lty = 2)

# panel 2: microdata
rasterImage(as.raster(cm_micro), p2x0, py0, p2x1, py1, interpolate = FALSE)
rect(p2x0, py0, p2x1, py1, border = col_pa, lwd = 3)

# arrow panel 2 -> panel 3
arrows(p2x1 + gap * 0.15, (py0 + py1) / 2, p3x0 - gap * 0.15, (py0 + py1) / 2, length = 0.12, lwd = 3, col = "grey40")

# panel 3: aggregated cells
xs = seq(p3x0, p3x1, length.out = n + 1); ys = seq(py1, py0, length.out = n + 1)
for (i in 1:n) for (j in 1:n) rect(xs[j], ys[i + 1], xs[j + 1], ys[i], col = cm_agg[i, j], border = "white", lwd = 0.6)
rect(p3x0, py0, p3x1, py1, border = col_pa, lwd = 3)

for (x0 in c(p2x0, p3x0)) {
	p = pz(x0)
	points(p[1], p[2], pch = 21, bg = "white", col = "black", cex = 1.8)
}
p = pz(p3x0); text(p[1], p[2], "Paris", pos = 4, cex = 1.7, font = 2, col = "white")

text(p2x0, py1 + R * 0.06, "960 \u00d7 960 cells", adj = c(0, 0), col = col_pa, font = 2, cex = 2)
text(p3x0, py1 + R * 0.06, "15 \u00d7 15 cells", adj = c(0, 0), col = col_pa, font = 2, cex = 2)
dev.off()
