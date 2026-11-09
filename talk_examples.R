# Examples for the (15 minute) talk "3D Thematic Mapping in R with tmap v4 and tmap.mapgl"
#
#   1. Population (WorldPop 2025)
#      1a. the globe            ~ 60 km cells (lon/lat)
#      1b. Europe               10 km cells (equal-area grid, LAEA), with hover text for the urban centres
#   2. Health per district (RIVM/GGDs/CBS Gezondheidsmonitor 2024, 3 393 'wijken')
#      2a. 3D: height = population density, colour = health compared to the Dutch average
#      2b. + texture "mottle": the colour is uncertain (width of the 95% interval)
#      2c. + texture "sketch": idem, attached to the map (it is enlarged when zooming in)
#
# The maps are saved to maps/*.html (to embed as <iframe> in the slides). Screenshots (figures/ex_*.png)
# are made with: node screenshot.mjs file://$PWD/maps/<name>.html figures/ex_<name>.png
#
# Data: data/global_pop_2025_1km.tif and data/NLD_health_wijk.rds, made by prepare_data.R
# Requires the development versions of tmap and tmap.mapgl (textures "mottle" and "sketch", and
# tm_maplibre(pattern.zoom)):
# remotes::install_github(c("r-tmap/tmap", "r-tmap/tmap.mapgl"))
library(tmap)
library(tmap.mapgl)
library(terra)
library(sf)

tmap_mode("maplibre")

save_map = function(tm, name) {
	tmap_save(tm, file.path("maps", paste0(name, ".html")), selfcontained = FALSE, libdir = "lib")
}

# For global views (zoom < 3), tmap.mapgl centres the map at (0, 0). This saves the widget with another centre.
save_map_center = function(tm, name, center) {
	w = print(tm, show = FALSE)   # the maplibre htmlwidget
	w$x$center = center
	htmlwidgets::saveWidget(w, file.path("maps", paste0(name, ".html")), selfcontained = FALSE, libdir = "lib")
}

pop = rast("data/global_pop_2025_1km.tif")   # WorldPop 2025, 1 km (30 arc seconds)

# One colour scale for both population maps: population density (inhabitants per km2)
dens_scale = tm_scale_intervals(breaks = c(0, 25, 100, 250, 500, 1000, 2500, 5000, Inf),
								values = "-ocean.thermal",
								labels = c("< 25", "25 - 100", "100 - 250", "250 - 500", "500 - 1,000",
										   "1,000 - 2,500", "2,500 - 5,000", "> 5,000"))
dens_legend = tm_legend("Inhabitants per km²")
credits_pop = tm_credits("Data: WorldPop (2025), www.worldpop.org, CC BY 4.0")

# ---------------------------------------------------------------------------
# 1a. Population of the world, on the globe
# ---------------------------------------------------------------------------
# 64 x 64 cells of 30 arc seconds: ~ 60 km at the equator. Lon/lat cells are not equal-area (they
# shrink towards the poles), so the population is divided by the cell area: height = density.
pop_world = aggregate(pop, fact = 64, fun = "sum", na.rm = TRUE)
pop_world = pop_world / cellSize(pop_world, unit = "km")
names(pop_world) = "dens"
pop_world[pop_world == 0] = NA   # leave out empty cells

m1a = tm_shape(pop_world) +
	tm_polygons_3d(
		height = "dens",
		fill = "dens", fill.scale = dens_scale, fill.legend = dens_legend,
		lwd = 0, popup = FALSE,
		options = opt_tm_polygons_3d(height.max = "5%")) +
	credits_pop +
	tm_maplibre(zoom = 1.8, pitch = 20)   # zoom < 4: globe projection
m1a
save_map_center(m1a, "world_globe", center = c(60, 25))   # Europe, Africa and Asia

# ---------------------------------------------------------------------------
# 1b. Population of Europe (excl. Russia), 10 km equal-area grid
# ---------------------------------------------------------------------------
# Reprojected to the European equal-area grid (LAEA, EPSG:3035) at 1 km; "sum" preserves the population. The
# 1 km grid is used for the urban centres (hover text), and aggregated to 10 km for the map. All cells are
# 100 km2, so height = density = count.
file_eu = "data/pop_europe_1km.tif"
if (!file.exists(file_eu)) {
	europe = vect(st_transform(World[World$continent == "Europe" & World$name != "Russia", ], 3035))
	crop(pop, ext(-25, 45, 34, 72)) |>
		project("EPSG:3035", res = 1000, method = "sum") |>
		crop(ext(2500000, 7400000, 1400000, 5500000)) |>
		mask(europe) |>
		writeRaster(file_eu, overwrite = TRUE)
}
pop_eu1 = rast(file_eu)
names(pop_eu1) = "pop"
pop_eu = aggregate(pop_eu1, fact = 10, fun = "sum", na.rm = TRUE)
pop_eu[pop_eu < 100] = NA        # leave out (nearly) uninhabited cells (< 1 per km2)
pop_eu$dens = pop_eu$pop / 100   # per km2

# Urban centres, as in the 'Degree of Urbanisation' of Eurostat/OECD/UN: contiguous 1 km cells (4 neighbours)
# with at least 1,500 inhabitants per km2 and together at least 50,000 inhabitants. So Paris without Creil, and
# London without the commuter belt. Some urban centres contain several cities, e.g. the Ruhr area, and
# The Hague with Delft. Cities shouldn't eat each other, so these are split between the cities (from
# maps::world.cities) of at least 75,000 inhabitants and 15% of the largest city: each cell goes to the city with
# the highest 'gravity' (population / distance^2). Returns the 1 km cells with their city.
urban_centres = function(pop, cities, min_dens = 1500, min_pop = 5e4, city_min = 75000, city_ratio = 0.15) {
	core = classify(pop, cbind(-Inf, min_dens, NA), right = FALSE)
	uc = patches(core, directions = 4)
	cells = as.data.frame(c(uc, pop), cells = TRUE, na.rm = TRUE)
	names(cells) = c("cell", "uc", "pop")
	tot = tapply(cells$pop, cells$uc, sum)
	cells = cells[cells$uc %in% as.integer(names(tot)[tot >= min_pop]), ]
	# the cities per urban centre (the largest one, and the others that are large enough); also the cities
	# within 2 km of an urban centre, e.g. Belgrade, of which the point lies at the confluence of the rivers
	uc2 = focal(uc, 5, "modal", na.policy = "only", na.rm = TRUE)
	cities$uc = extract(uc2, vect(cities))[, 2]
	cities = cities[cities$uc %in% cells$uc, ]
	cities = cities[order(-cities$pop), ]
	largest = tapply(cities$pop, cities$uc, max)[as.character(cities$uc)]
	cities = cities[!duplicated(cities$uc) | cities$pop >= pmax(city_min, city_ratio * largest), ]
	# the city per cell
	xy = xyFromCell(pop, cells$cell)
	cxy = st_coordinates(cities)
	cells$city = NA_integer_
	for (k in unique(cities$uc)) {
		i = which(cells$uc == k)
		s = which(cities$uc == k)
		d2 = outer(xy[i, 1], cxy[s, 1], "-")^2 + outer(xy[i, 2], cxy[s, 2], "-")^2 + 1e6
		cells$city[i] = s[max.col(-d2 / rep(cities$pop[s], each = length(i)), ties.method = "first")]
	}
	cells = cells[!is.na(cells$city), ]
	cells$name = cities$name[cells$city]
	cells
}
cities = maps::world.cities
cities = cities[cities$long > -25 & cities$long < 45 & cities$lat > 34 & cities$lat < 72, ]
cities = st_transform(st_as_sf(cities, coords = c("long", "lat"), crs = 4326), 3035)
cities$name[cities$name == "s-Gravenhage"] = "The Hague"
cities$name[cities$name == "Piraieus"] = "Piraeus"
uc = urban_centres(pop_eu1, cities)

# Per city: the population of its (part of the) urban centre, and the peak density, i.e. the highest 10 km cell
# of the map. Only the cities with at least 250,000 inhabitants.
uc$dens10 = values(pop_eu$dens)[cellFromXY(pop_eu, xyFromCell(pop_eu1, uc$cell)), 1]
towns = data.frame(city = sort(unique(uc$city)))
towns$name = uc$name[match(towns$city, uc$city)]
towns$total = tapply(uc$pop, uc$city, sum)[as.character(towns$city)]
towns$peak = tapply(uc$dens10, uc$city, max, na.rm = TRUE)[as.character(towns$city)]
towns = towns[towns$total >= 1e5, ]
towns$label = sprintf("<b>%s</b>: %s inhabitants (urban centre)<br>peak: %s inhabitants per km² (10 km cell)",
					  towns$name,
					  ifelse(towns$total >= 1e6, sprintf("%.1f million", towns$total / 1e6),
					  	   format(round(towns$total, -4), big.mark = ",", trim = TRUE)),
					  format(round(towns$peak, -1), big.mark = ",", trim = TRUE))

# Hover text: attached to an invisible layer of 'hitboxes', since the thin columns are hard to hit with the mouse.
# A hitbox is an urban centre, extended by up to 10 km (between neighbouring urban centres: to the nearest one),
# smoothed, and without holes. The hitboxes are flat (on the ground): on the globe, MapLibre does not find most 3D
# features under the mouse (it tests them as if the map were flat), so hover over the foot of the columns.
r_uc = rast(pop_eu1)
r_uc[uc$cell] = ifelse(uc$city %in% towns$city, uc$city, -1)   # -1: smaller cities (no hover text)
# grow by 1 km per step (alternately 4 and 8 neighbours, which gives rounder shapes)
w4 = matrix(c(NA, 1, NA, 1, 1, 1, NA, 1, NA), 3)
for (i in 1:10) r_uc = focal(r_uc, if (i %% 2) w4 else 3, "modal", na.policy = "only", na.rm = TRUE)
r_uc[r_uc < 0] = NA
names(r_uc) = "city"
# the outer rings of the polygons (without holes) of at least 10 km2
outer_rings = function(g) {
	st_sfc(lapply(g, function(p) {
		parts = lapply(st_cast(st_sfc(p), "POLYGON"), function(q) st_polygon(q[1]))
		st_multipolygon(parts[vapply(parts, st_area, numeric(1)) >= 1e7])
	}), crs = st_crs(g))
}
urban = st_as_sf(as.polygons(r_uc))
st_geometry(urban) = st_geometry(urban) |>
	st_buffer(5000) |> st_buffer(-5000) |>   # smooth
	outer_rings() |>
	st_simplify(dTolerance = 500)
urban = merge(urban, towns[, c("city", "label")])

# height.min: all cells get a small minimum height (1 km, in metres), since flat cells give artefacts on the globe
eu3d = opt_tm_polygons_3d(height.max = 250000, height.min = 1000)

m1b = tm_shape(pop_eu) +
	tm_polygons_3d(
		height = "dens",
		fill = "dens", fill.scale = dens_scale, fill.legend = dens_legend,
		lwd = 0, popup = FALSE, options = eu3d) +
	tm_shape(urban) +
	tm_polygons(fill_alpha = 0, col_alpha = 0, hover = "label", popup = FALSE) +   # invisible
	credits_pop +
	tm_basemap("ofm.bright") +
	tm_maplibre(pitch = 45, zoom = 3.6)
m1b
save_map(m1b, "europe_10km")

# ---------------------------------------------------------------------------
# 2. Health per district: share of adults who rate their health as good or very good
#    (model-based small area estimates, with 95% intervals), compared to the Dutch average
# ---------------------------------------------------------------------------
NLD = readRDS("data/NLD_health_wijk.rds")
NLD = NLD[!is.na(NLD$health), ]
NLD$pop_dens = NLD$population / (as.numeric(st_area(NLD)) / 1e6)   # per km2
NLD$health_ci = NLD$health_hi - NLD$health_lo                        # width of the 95% interval
NLD$label = sprintf("%s (%s): %.1f%% [%.1f - %.1f]", NLD$name, NLD$municipality,
					NLD$health, NLD$health_lo, NLD$health_hi)

# Dutch average: weighted by the population of the districts
nl = weighted.mean(NLD$health, NLD$population)
NLD$health_diff = NLD$health - nl

# Diverging scale, purple (less healthy) to green (healthier), with the Dutch average in the middle class
health_scale = tm_scale_intervals(breaks = c(-30, -8, -5, -2, 2, 5, 8, 30), values = "brewer.prgn", midpoint = 0,
								  labels = c("< -8", "-8 to -5", "-5 to -2", "-2 to 2", "2 to 5", "5 to 8", "> 8"))
health_title = sprintf("Good health vs. NL (%.1f%%)", nl)   # difference in %-points

ci_scale = tm_scale_intervals(breaks = c(0, 3, 5, 9, 40), values = c(0, 0.35, 0.7, 1),
							  labels = c("< 3", "3 - 5", "5 - 9", "> 9"))
ci_legend = tm_legend_cross("fill", xlab = health_title, ylab = "Width of 95% interval")

h3d = opt_tm_polygons_3d(height.max = "8%")
credits_health = tm_credits("Data: Gezondheidsmonitor Volwassenen en Ouderen 2024 (GGDs, CBS, RIVM);\ndistrict boundaries: CBS, Kadaster")

# The textures are best seen when zoomed in: 2b and 2c start in the Randstad
bb_randstad = st_bbox(c(xmin = 4.2, ymin = 51.8, xmax = 5.3, ymax = 52.45), crs = 4326)

# ---------------------------------------------------------------------------
# 2a. Height = population density (so volume = population), colour = health
# ---------------------------------------------------------------------------
m2a = tm_shape(NLD) +
	tm_polygons_3d(
		height = "pop_dens",
		fill = "health_diff", fill.scale = health_scale, fill.legend = tm_legend(health_title),
		lwd = 0, hover = "label", popup = FALSE, options = h3d) +
	credits_health +
	tm_maplibre(pitch = 50)
m2a
save_map(m2a, "nld_health")

# ---------------------------------------------------------------------------
# 2b. + texture "mottle": the wider the 95% interval, the more 'poorly painted' the roof
#     (the average colour stays the same, so the estimate can still be read)
# ---------------------------------------------------------------------------
m2b = tm_shape(NLD, bbox = bb_randstad) +
	tm_polygons_3d(
		height = "pop_dens",
		fill = "health_diff", fill.scale = health_scale,
		pattern = tm_patterns("mottle", grain = 0.5, random = 1),
		pattern_col = "black",
		pattern_density = "health_ci", pattern_density.scale = ci_scale, pattern_density.legend = ci_legend,
		lwd = 0, hover = "label", popup = FALSE, options = h3d) +
	credits_health +
	tm_maplibre(pitch = 50, zoom = 9)
m2b
save_map(m2b, "nld_health_mottle")

# ---------------------------------------------------------------------------
# 2c. + texture "sketch": the wider the 95% interval, the sketchier the roof
#     pattern.zoom = "map": the texture is attached to the map, so it is enlarged when zooming in
#     (by default, patterns keep their size on the screen)
# ---------------------------------------------------------------------------
m2c = tm_shape(NLD, bbox = bb_randstad) +
	tm_polygons_3d(
		height = "pop_dens",
		fill = "health_diff", fill.scale = health_scale,
		pattern = "sketch",
		pattern_density = "health_ci", pattern_density.scale = ci_scale, pattern_density.legend = ci_legend,
		lwd = 0, hover = "label", popup = FALSE, options = h3d) +
	credits_health +
	tm_maplibre(pitch = 50, zoom = 9, pattern.zoom = "map")
m2c
save_map(m2c, "nld_health_sketch")
