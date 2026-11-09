# tmap-tutorial-uros2026

Materials for [uRos2026](https://urosconf.org), Paris, 18–20 November 2026.

| | Session | When | Files |
|---|---|---|---|
| Tutorial | *Mapping Official Statistics with the tmapverse and cols4all* | Wed 18 Nov, 11:00–12:30, Room 2 | `tutorial.qmd`, `exercises.R`, `solutions.R` |
| Talk | *3D Thematic Mapping in R with tmap v4 and tmap.mapgl* (A5, Spatial and Small Area Analysis) | Fri 20 Nov, 13:45–15:15, Room 1 | `talk_3d.qmd` |

## Setup

```r
install.packages(c("tmap", "cols4all", "tmap.cartogram", "tmap.glyphs", "tmap.mapgl"))
# or: install.packages("tmapverse")
```

All data used ship with **tmap** (`NLD_prov`, `NLD_muni`, `NLD_dist`, `World`): CBS key figures 2022 for the Netherlands. No internet connection is needed, except for basemaps.

## Tutorial outline (90 min)

1. **tmap in a nutshell**: grammar, map variables, scales, classification, facets (exercise 1)
2. **Colours with cols4all**: palette types, colour-blind friendliness, diverging palettes, house-style palettes (exercise 2)
3. **Mapping official statistics**: rates vs. counts, bubbles, cartograms, suppressed values, bivariate choropleths, donut maps, publication layout and styles (exercise 3)
4. **Interactive and 3D maps**: view mode, popups, tmap.mapgl, `tm_polygons_3d()` (exercise 4)

## Rendering

```sh
quarto render tutorial.qmd
quarto render talk_3d.qmd
```

The live maps in `talk_3d.qmd` are separate HTML files in `maps/`, embedded as iframes (loaded when the slide is shown; basemaps need internet). Screenshots for offline use / handouts: `figures/*_3d.png`. To rebuild them:

```sh
Rscript prepare_data.R   # downloads CBS/RIVM small area estimates + neighbourhood polygons, WorldPop (~280 MB) -> data/
Rscript make_maps.R      # maps/*.html and figures/nld_uncertainty.png (needs dev tmap + tmap.mapgl)
node screenshot.mjs file://$PWD/maps/europe.html figures/europe_3d.png   # headless Chrome screenshot
```

Talk data: WorldPop 2025 1 km (CC BY 4.0); RIVM/CBS *Gezondheid per wijk en buurt 2024* (StatLine table 50150NED, model-based estimates with 95% intervals); CBS Wijk- en buurtkaart 2024 (PDOK).

## Sources

Built on the [tmap vignettes](https://r-tmap.github.io/tmap/articles/) and the courses *Interactive maps with tmap & Shiny* and *Advanced static cartography in R*.
