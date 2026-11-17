# uRos2026 tutorial: Mapping Official Statistics with the tmapverse and cols4all
# Exercises

library(tmap)
library(cols4all)

# Data: Statistics Netherlands (CBS) key figures 2022
# NLD_prov (provinces), NLD_muni (municipalities), NLD_dist (districts)
names(NLD_muni)


# Exercise 1: tmap in a nutshell (30 min) ---------------------------------

# 1. Make a choropleth of employment_rate per municipality (NLD_muni).


# 2. Use tm_scale_intervals() with style = "fixed" and breaks at 60, 65, 70, 75.
#    Tip: the breaks also need a lower and upper bound.


# 3. Add the province borders (NLD_prov), a title (tm_title()) and a credits
#    line with the source (tm_credits()).


# 4. Bonus: make facets per province (tm_facets_wrap()).



# Exercise 2: bubble map (10 min) -----------------------------------------

# 1. Map the number of dwellings (dwelling_total) per municipality as bubbles
#    (tm_bubbles()) on top of a light grey choropleth.


# 2. Bonus: colour the bubbles by dwelling_ownership, using the reversed
#    "magma" palette, and give them black borders. Make the bubbles twice as
#    large.
#    Tip: size.scale = tm_scale(values.scale = 2).



# Exercise 3: 3D map (10 min) ---------------------------------------------

# Load tmap.mapgl, switch to "maplibre" mode and make a 3D map of the
# districts (NLD_dist) with tm_polygons_3d(): height = population density,
# fill = edu_appl_sci, legend title "Higher education (%)".
# Tip: population density = population / area.
library(tmap.mapgl)


