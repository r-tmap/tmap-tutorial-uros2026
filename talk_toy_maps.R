# Toy maps for the first part of the talk (talk.qmd): the same map in modes "view", "maplibre", and in 3D
# Saved to maps/toy_*.html (embedded as <iframe> in the slides)
library(tmap)
library(tmap.mapgl)

save_map = function(tm, name) {
	tmap_save(tm, file.path("maps", paste0(name, ".html")), selfcontained = FALSE, libdir = "lib")
}

m = tm_shape(NLD_muni) +
	tm_polygons(fill = "employment_rate")

tmap_mode("view")
save_map(m, "toy_view")

tmap_mode("maplibre")
save_map(m, "toy_maplibre")

NLD_muni$pop_dens = NLD_muni$population / as.numeric(NLD_muni$area)   # per km2

m3d = tm_shape(NLD_muni) +
	tm_polygons_3d(height = "pop_dens", fill = "employment_rate") +
	tm_maplibre(pitch = 50)
save_map(m3d, "toy_3d")
