# Toy maps for the first part of the talk (talk.qmd): the same map in modes "view", "maplibre", and in 3D
# Saved to maps/toy_*.html (embedded as <iframe> in the slides)
library(tmap)
library(tmap.mapgl)

save_map = function(tm, name) {
	tmap_save(tm, file.path("maps", paste0(name, ".html")), selfcontained = FALSE, libdir = "lib")
}

# employment rate: deviation from the Dutch average (weighted by population), in %-points
NLD_muni$employment_rate_deviation = NLD_muni$employment_rate -
	weighted.mean(NLD_muni$employment_rate, NLD_muni$population, na.rm = TRUE)

m = tm_shape(NLD_muni) +
	tm_polygons(
		fill = "employment_rate_deviation",
		fill.scale = tm_scale_intervals(
			breaks = c(-15, -6, -3, -1, 1, 3, 6, 15),
			values = "pu_gn_div",
			label.style = "continuous"),
		fill.legend = tm_legend(
			title = "Employment rate vs. NL average",
			orientation = "landscape"))

tmap_mode("view")
save_map(m, "toy_view")

tmap_mode("maplibre")
save_map(m, "toy_maplibre")

NLD_muni$pop_dens = NLD_muni$population / as.numeric(NLD_muni$area)   # per km2

m3d = tm_shape(NLD_muni) +
	tm_polygons_3d(
		height = "pop_dens",
		fill = "employment_rate_deviation",
		fill.scale = tm_scale_intervals(
			breaks = c(-15, -6, -3, -1, 1, 3, 6, 15),
			values = "pu_gn_div",
			label.style = "continuous")) +
	tm_maplibre(pitch = 50)
save_map(m3d, "toy_3d")
