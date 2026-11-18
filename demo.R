# https://github.com/r-tmap/tmap-tutorial-uros2026
library(tmapverse)

install.packages(c("sf", "stars", "terra"))
install.packages("tmap")
install.packages("tmapverse")



# inspect dataset
NLD_muni

tm_shape(NLD_muni) + tm_polygons("orange")
tm_shape(NLD_muni) + tm_polygons("orange",
								 lwd = 2,
								 col = "purple",
								 pattern = "hatch") # development version only

tm_shape(NLD_muni) +
	tm_polygons("income_high")

tmap_mode("view")

tm_shape(NLD_muni) +
	tm_polygons("income_high")

tmap_mode("plot")

tm_shape(NLD_muni) + tm_polygons("orange",
								 lwd = 2,
								 col = "purple")


tm_shape(NLD_muni) + tm_polygons(fill = "income_high",
								 lwd = "dwelling_value",
								 col = "employment_rate")


tm_shape(NLD_muni) +
	tm_polygons("income_high",
				fill.scale = tm_scale_continuous(
					values = "-matplotlib.pi_yg"))


library(tmap.cartogram)
Africa = World[World$continent == "Africa", ]
tm_shape(Africa, crs = "+proj=aea +lat_1=20 +lat_2=-23 +lon_0=25") +  # equal-area
	tm_cartogram(
		size = "*pop_est",
		fill = "press",
		fill.scale = tm_scale_intervals(breaks = c(0, 40, 55, 70, 85, 100),
										labels = c("Very serious", "Difficult", "Problematic", "Satisfactory", "Good"),
										values = "brewer.rd_yl_bu"),
		fill.legend = tm_legend("Press freedom\n(RSF index)"),
		col = "grey30", lwd = 0.5) +
	tm_labels("name",
			  size = "pop_est",                                  # label size by population
			  size.scale = tm_scale_continuous(values = c(0.5, 1.2)),
			  size.legend = tm_legend_hide(),
			  col = "auto",                                      # black or white, by fill
			  options = opt_tm_labels(
			  	placement = tm_placement(                        # labels that don't fit:
			  		fallback = c("wrap", "rotate", "shrink", "move", "drop"),
			  		move.max = 0.5),                               # move at most 50% outside
			  	leader = tm_leader(col = "gray20", lwd = 0.5, type = "elbow"))) +
	tm_title("Africa: countries sized by population") +
	tm_layout(inner.margins = c(0.02, 0.1, 0.02, 0.1))     # room for moved labels


tmap_mode("maplibre")
NLD_dist$pop_dens = NLD_dist$population / NLD_dist$area

tm_shape(NLD_dist) +
	tm_polygons_3d(
		height = "pop_dens",
		fill = "edu_appl_sci",
		fill.scale = tm_scale_intervals(style = "kmeans", values = "tol.iridescent"),
		fill.legend = tm_legend("Higher education (%)"),
		hover = "name") +
	tm_maplibre(pitch = 45) +
	tm_crs(3857)      # Web Mercator: avoids 3D artefacts of the default globe



tm_shape(NLD_dist) +
	tm_polygons_3d(
		height = "pop_dens",
		fill = "edu_appl_sci") +
	tm_maplibre(pitch = 45)

tmap_mode("view")
tm_shape(World[World$name == "Russia",]) +
	tm_polygons() +
	tm_crs("auto")
