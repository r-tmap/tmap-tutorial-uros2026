# tmap-tutorial-uros2026

Materials for [uRos2026](https://urosconf.org), Paris, 18–20 November 2026.

| | Session | When | Files |
|---|---|---|---|
| Tutorial | *Mapping Official Statistics with the tmapverse and cols4all* | Wed 18 Nov, 11:00–12:30, Room 2 | `tutorial.qmd`, `exercises.R`, `solutions.R` |
| Talk | *3D Thematic Mapping in R with tmap v4 and tmap.mapgl* (A5, Spatial and Small Area Analysis) | Fri 20 Nov, 13:45–15:15, Room 1 | `talk.qmd` |

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
quarto render talk.qmd
```

The live maps in `talk.qmd` are separate HTML files in `maps/`, embedded as iframes (loaded when the slide is shown; basemaps need internet). They require the development versions of tmap and tmap.mapgl (`remotes::install_github(c("r-tmap/tmap", "r-tmap/tmap.mapgl"))`). To rebuild them:

```sh
Rscript prepare_data.R    # downloads WorldPop (~280 MB) and the CBS/RIVM health estimates + district polygons -> data/
Rscript talk_toy_maps.R   # maps/toy_*.html: the toy maps (view, maplibre, 3D)
Rscript talk_examples.R   # maps/world_globe.html, europe_10km.html, nld_health*.html: the applications
Rscript talk_hitbox.R     # maps/europe_hitbox.html: map 1b with the hover areas made visible, for a screenshot:
node screenshot.mjs file://$PWD/maps/europe_hitbox.html figures/europe_hitbox.png 15000 1000 650
```

Talk data: WorldPop 2025 1 km (CC BY 4.0); Health Monitor Adults and Elderly 2024 (GGDs, CBS, RIVM; model-based estimates per district with 95% intervals); CBS Wijk- en buurtkaart 2024 (PDOK).

## Sources

Built on the [tmap vignettes](https://r-tmap.github.io/tmap/articles/) and the courses *Interactive maps with tmap & Shiny* and *Advanced static cartography in R*.
