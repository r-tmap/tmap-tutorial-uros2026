# uRos2026 tutorial: Mapping Official Statistics with the tmapverse and cols4all
# Exercises (solutions in solutions.R)

library(tmap)
library(cols4all)

# Data: Statistics Netherlands (CBS) key figures 2022
# NLD_prov (provinces), NLD_muni (municipalities), NLD_dist (districts)
names(NLD_muni)


# Exercise 1: tmap in a nutshell ------------------------------------------

# 1. Make a choropleth of employment_rate per municipality (NLD_muni).


# 2. Use tm_scale_intervals() with style = "fixed" and breaks at 60, 65, 70, 75.
#    Tip: the breaks also need a lower and upper bound.


# 3. Add the province borders (NLD_prov), a title (tm_title()) and a credits
#    line with the source (tm_credits()).


# 4. Bonus: make facets per urbanity (tm_facets_wrap()).



# Exercise 2: colours with cols4all ---------------------------------------

# 1. Run c4a_gui(). Find a sequential, colour-blind friendly palette you like.
c4a_gui()

# 2. Use it for the map of exercise 1 (argument values in the scale function).


# 3. Map the deviation of dwelling_ownership from its national average with
#    a diverging palette and midpoint = 0.
#    Tip: compute the national average weighted by dwelling_total.


# 4. Bonus: analyse the house-style palette of your own institute:
#    c4a_gui(pal = c("#......", "#......", ...))



# Exercise 3: mapping official statistics ---------------------------------

# 1. Map the number of dwellings (dwelling_total) per municipality as bubbles
#    on top of a light grey choropleth.


# 2. Make a Dorling cartogram sized by dwelling_total and coloured by
#    dwelling_ownership.
library(tmap.cartogram)


# 3. Make a district map (NLD_dist) of one province of your choice for
#    income_low, with a clear legend label for suppressed values.
unique(NLD_dist$province)


# 4. Bonus: bivariate map of income_low and pop_65plus.
#    Which palette from c4a_palettes(type = "bivs") works best?
c4a_palettes(type = "bivs")



# Exercise 4: interactive and 3D maps -------------------------------------

# 1. Switch to "view" mode and show the map of exercise 3.3 interactively,
#    with the district name on hover and income in the popup.


# 2. Load tmap.mapgl, switch to "maplibre" mode and make the 3D map of
#    population density (height) and education (fill) per district.
library(tmap.mapgl)


# 3. Change the pitch and the fill variable. Rotate the map with Ctrl + drag.

