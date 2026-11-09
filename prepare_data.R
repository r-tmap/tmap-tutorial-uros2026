# Prepare data for the talk examples (run once; results are cached in data/)
library(sf)
library(jsonlite)

dir.create("data", showWarnings = FALSE)

# ---------------------------------------------------------------------------
# 1. Small area estimates with 95% intervals: RIVM/CBS 'Gezondheid per wijk
#    en buurt 2024' (table 50150NED, model-based estimates from the
#    Gezondheidsmonitor Volwassenen en Ouderen 2024)
# ---------------------------------------------------------------------------
# the ODataFeed endpoint returns pages of 10000 records with a link to the next page
get_odata = function(url) {
	out = list()
	while (!is.null(url)) {
		x = fromJSON(url)
		out[[length(out) + 1]] = x$value
		url = x$odata.nextLink
	}
	do.call(rbind, out)
}

# level: "buurten" (neighbourhoods) or "wijken" (districts); both have their own estimates
get_health = function(level = "buurten") {
	prefix = c(buurten = "BU", wijken = "WK")[level]
	vars = c("WijkenEnBuurten", "Marges", "Gemeentenaam_1",
			 "Eenzaam_25", "MoeiteMetRondkomen_32", "GoedErvarenGezondheid_4")
	url = paste0("https://dataderden.cbs.nl/ODataFeed/odata/50150NED/TypedDataSet?$format=json&",
				 "$filter=", URLencode(paste0("Leeftijd eq '20300' and Perioden eq '2024JJ00' and substringof('",
											  prefix, "',WijkenEnBuurten)"), reserved = TRUE),
				 "&$select=", paste(vars, collapse = ","))
	h = get_odata(url)
	h$WijkenEnBuurten = trimws(h$WijkenEnBuurten)
	h$Marges = c(MW00000 = "est", MOG0095 = "lo", MBG0095 = "hi")[trimws(h$Marges)]

	# wide format: one row per area, columns <var>_<est|lo|hi>
	hw = reshape(h[, c("WijkenEnBuurten", "Marges", vars[4:6])],
				 idvar = "WijkenEnBuurten", timevar = "Marges", direction = "wide", sep = "_")

	# -----------------------------------------------------------------------
	# 2. Polygons 2024 (CBS Wijk- en buurtkaart, via PDOK WFS)
	# -----------------------------------------------------------------------
	wfs = paste0("https://service.pdok.nl/cbs/wijkenbuurten/2024/wfs/v1_0?service=WFS&version=2.0.0&request=GetFeature&typeName=wijkenbuurten:",
				 level, "&outputFormat=application/json&count=1000&startIndex=")
	bu = list(); i = 0
	repeat {
		x = st_read(paste0(wfs, i), quiet = TRUE)
		if (!nrow(x)) break
		bu[[length(bu) + 1]] = x
		i = i + 1000
	}
	bu = do.call(rbind, bu)
	unit = c(buurten = "buurt", wijken = "wijk")[level]
	bu = bu[bu$water == "NEE", c(paste0(unit, "code"), paste0(unit, "naam"), "gemeentenaam", "aantalInwoners", "geometry")]
	names(bu)[1:4] = c("code", "name", "municipality", "population")
	bu$population[bu$population < 0] = NA   # negative values are CBS codes for 'secret'

	NLD_health = merge(bu, hw, by.x = "code", by.y = "WijkenEnBuurten")

	# short names: <var> (estimate), <var>_lo and <var>_hi (95% interval)
	short = c(MoeiteMetRondkomen_32 = "poverty", Eenzaam_25 = "lonely", GoedErvarenGezondheid_4 = "health")
	for (v in names(short)) {
		for (m in c("est", "lo", "hi")) {
			names(NLD_health)[names(NLD_health) == paste(v, m, sep = "_")] =
				if (m == "est") short[v] else paste(short[v], m, sep = "_")
		}
	}
	cols = c("code", "name", "municipality", "population",
			 as.vector(outer(c("", "_lo", "_hi"), short, function(a, b) paste0(b, a))))
	NLD_health = rmapshaper::ms_simplify(NLD_health, keep = 0.1, keep_shapes = TRUE)
	NLD_health[, cols]   # (ms_simplify changes the column order)
}

if (!file.exists("data/NLD_health.rds")) saveRDS(get_health("buurten"), "data/NLD_health.rds")
if (!file.exists("data/NLD_health_wijk.rds")) saveRDS(get_health("wijken"), "data/NLD_health_wijk.rds")

# ---------------------------------------------------------------------------
# 3. WorldPop 2025 (1 km), see https://hub.worldpop.org/geodata/summary?id=80031
#    Reprojected to the European equal-area grid (LAEA, EPSG:3035), so that
#    every cell has the same area: height = density = count.
# ---------------------------------------------------------------------------
library(terra)
library(tmap)

worldpop_file = "data/global_pop_2025_1km.tif"
if (!file.exists(worldpop_file)) {
	options(timeout = 2000)   # ~280 MB
	download.file(paste0("https://data.worldpop.org/GIS/Population/Global_2015_2030/R2025A/2025/",
						 "0_Mosaicked/v1/1km_ua/constrained/global_pop_2025_CN_1km_R2025A_UA_v1.tif"),
				  destfile = worldpop_file, mode = "wb")
}
pop = rast(worldpop_file)

# 1 km grid in LAEA; method "sum" preserves the population totals
pop_laea = project(crop(pop, ext(-25, 45, 34, 72)), "EPSG:3035", res = 1000, method = "sum")
names(pop_laea) = "pop"

# Europe (excl. Russia) on a 20 km grid
data(World)
europe = vect(st_transform(World[World$continent == "Europe" & World$name != "Russia", ], 3035))
pop_eu = crop(pop_laea, ext(2500000, 7000000, 1400000, 5500000)) |> mask(europe)
pop_eu = aggregate(pop_eu, fact = 20, fun = "sum", na.rm = TRUE)
writeRaster(pop_eu, "data/pop_europe_20km.tif", overwrite = TRUE)

# Paris region (100 x 100 km) on the 1 km grid
paris = st_coordinates(st_transform(st_sfc(st_point(c(2.35, 48.86)), crs = 4326), 3035))
pop_paris = crop(pop_laea, ext(paris[1] + c(-50000, 50000), paris[2] + c(-50000, 50000)))
writeRaster(pop_paris, "data/pop_paris_1km.tif", overwrite = TRUE)
