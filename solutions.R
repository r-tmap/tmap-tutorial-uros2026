# uRos2026 tutorial: Mapping Official Statistics with the tmapverse and cols4all
# Solutions

library(tmap)
library(cols4all)


# Exercise 1: tmap in a nutshell ------------------------------------------

# 1.
tm_shape(NLD_muni) +
  tm_polygons("employment_rate")

# 2. + 3.
tm_shape(NLD_muni) +
  tm_polygons(
    fill = "employment_rate",
    fill.scale = tm_scale_intervals(style = "fixed", breaks = c(50, 60, 65, 70, 75, 80)),
    fill.legend = tm_legend("Employment rate (%)")) +
tm_shape(NLD_prov) +
  tm_borders(lwd = 2) +
tm_title("Employment rate per municipality, 2022") +
tm_credits("Source: Statistics Netherlands (CBS)")

# 4.
tm_shape(NLD_muni) +
  tm_polygons(
    fill = "employment_rate",
    fill.scale = tm_scale_intervals(style = "fixed", breaks = c(50, 60, 65, 70, 75, 80)),
    fill.legend = tm_legend("Employment rate (%)")) +
tm_facets_wrap("province")


# Exercise 2: bubble map --------------------------------------------------

# 1.
tm_shape(NLD_muni) +
  tm_polygons(fill = "grey90", col = "white") +
  tm_bubbles(
    size = "dwelling_total",
    fill = "darkorange", col = "white",
    size.legend = tm_legend("Number of dwellings"))

# 2.
tm_shape(NLD_muni) +
  tm_polygons(fill = "grey90", col = "white") +
  tm_bubbles(
    size = "dwelling_total",
    size.scale = tm_scale(values.scale = 2),
    size.legend = tm_legend("Number of dwellings"),
    fill = "dwelling_ownership",
    fill.scale = tm_scale_intervals(values = "-magma"),
    fill.legend = tm_legend("Owner-occupied (%)"),
    col = "black")


# Exercise 3: 3D map ------------------------------------------------------


library(tmap.mapgl)
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


tmap_mode("plot")
