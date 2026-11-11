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
tm_facets_wrap("urbanity")


# Exercise 2: colours with cols4all ---------------------------------------

# 1.
c4a_gui()

# 2. e.g. "tol.iridescent", "scico.batlow", "hcl.purple_blue", "brewer.yl_gn_bu"
tm_shape(NLD_muni) +
  tm_polygons(
    fill = "employment_rate",
    fill.scale = tm_scale_intervals(style = "fixed", breaks = c(50, 60, 65, 70, 75, 80),
                                    values = "tol.iridescent"),
    fill.legend = tm_legend("Employment rate (%)"),
    col = "white", lwd = 0.3) +
tm_shape(NLD_prov) +
  tm_borders(col = "grey25", lwd = 1.5)

# 3.
nl_avg = weighted.mean(NLD_muni$dwelling_ownership, NLD_muni$dwelling_total, na.rm = TRUE)
NLD_muni$own_dev = NLD_muni$dwelling_ownership - nl_avg

tm_shape(NLD_muni) +
  tm_polygons(
    fill = "own_dev",
    fill.scale = tm_scale_intervals(
      breaks = c(-40, -20, -10, -3, 3, 10, 20, 40),
      values = "cols4all.bu_br_div",
      midpoint = 0),
    fill.legend = tm_legend("Owner-occupied dwellings,\ndeviation from NL (%-pt)"),
    col = "white", lwd = 0.3)

# 4. an example corporate palette
house = c("#00a1cd", "#0058b8", "#afcb05", "#53a31d", "#f39200", "#e94c0a")
c4a_plot(house, include.cvd = TRUE)
c4a_gui(pal = house)


# Exercise 3: mapping official statistics ---------------------------------

# 1.
tm_shape(NLD_muni) +
  tm_polygons(fill = "grey90", col = "white") +
  tm_bubbles(
    size = "dwelling_total",
    fill = "darkorange", col = "white",
    size.legend = tm_legend("Number of dwellings"))

# 2.
library(tmap.cartogram)
tm_shape(NLD_muni) +
  tm_cartogram_dorling(
    size = "dwelling_total",
    fill = "dwelling_ownership",
    fill.scale = tm_scale_intervals(values = "brewer.bu_pu", style = "fisher"),
    fill.legend = tm_legend("Owner-occupied (%)"),
    col = "white")

# 3.
gld = NLD_dist[NLD_dist$province == "Gelderland", ]
map_gld = tm_shape(gld) +
  tm_polygons(
    fill = "income_low",
    fill.scale = tm_scale_intervals(
      style = "fixed", breaks = c(10, 20, 30, 40, 50, 60, 90),
      values = "brewer.or_rd",
      value.na = "white", label.na = "Not published\n(confidentiality)"),
    fill.legend = tm_legend("Low income households (%)"),
    col = "grey60", lwd = 0.3) +
tm_layout(frame = FALSE)
map_gld

# 4.
c4a_palettes(type = "bivs")
tm_shape(NLD_muni) +
  tm_polygons(
    fill = tm_vars(c("income_low", "pop_65plus"), multivariate = TRUE),
    fill.scale = tm_scale_bivariate(
      scale1 = tm_scale_intervals(style = "quantile", n = 3, labels = c("L", "M", "H")),
      scale2 = tm_scale_intervals(style = "quantile", n = 3, labels = c("L", "M", "H")),
      values = "bu_br_bivs"),
    fill.legend = tm_legend_bivariate(
      xlab = "Low income", ylab = "65+",
      item.r = 0, item.width = 2, item.height = 2),
    col = "white", lwd = 0.5)


# Exercise 4: interactive and 3D maps -------------------------------------

# 1.
tmap_mode("view")
tm_shape(gld) +
  tm_polygons(
    fill = "income_low",
    fill.scale = tm_scale_intervals(
      style = "fixed", breaks = c(10, 20, 30, 40, 50, 60, 90),
      values = "brewer.or_rd",
      value.na = "white", label.na = "Not published"),
    fill.legend = tm_legend("Low income households (%)"),
    fill_alpha = 0.8,
    hover = "name",
    popup = tm_popup(vars = c("Province" = "province", "Population" = "population",
                                "Low income (%)" = "income_low")))

# 2.
library(tmap.mapgl)
tmap_mode("maplibre")
NLD_dist$pop_dens = NLD_dist$population / NLD_dist$area

tm_shape(NLD_dist) +
  tm_polygons_3d(
    height = "pop_dens",
    fill = "edu_appl_sci",
    fill.scale = tm_scale_intervals(style = "kmeans", values = "tol.iridescent"),
    fill.legend = tm_legend("University degree (%)"),
    hover = "name") +
tm_maplibre(pitch = 45) +
tm_crs(3857)      # Web Mercator: avoids 3D artefacts of the default globe

# 3.
tm_shape(NLD_dist) +
  tm_polygons_3d(
    height = "pop_dens",
    fill = "income_high",
    fill.scale = tm_scale_intervals(style = "kmeans", values = "tol.iridescent"),
    fill.legend = tm_legend("High income households (%)"),
    hover = "name") +
tm_maplibre(pitch = 60, bearing = -20) +
tm_crs(3857)

tmap_mode("plot")
