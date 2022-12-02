#!/usr/bin/env Rscript

# librerías
library(raster)
library(leaflet)
library(htmlwidgets)
library(leafem)
library(leaflet.opacity)
library(leaflet.extras)
library(lubridate)
library(tidyverse)



# stack ROI ---------------------------------------------------------------
# 20221127
recorte_stack <- raster::stack("recortes/recorte.tif")

# vector LR
LR_vector <- shapefile("vectores/roi_LR_mapa_turb.shp")

# recorto
recorte_subset <- crop(recorte_stack, LR_vector)

# RGB
plotRGB(recorte_subset, r = 4, g = 3, b = 2, stretch = "lin")

# MNDWI
# 10.3390/rs8040354
# (B03 - B11) / (B03 + B11)
# afecto por el factor de escala
b_b03 <- recorte_subset[[3]]/10000
b_b05 <- recorte_subset[[5]]/10000 # algoritmo TURB
b_b11 <- recorte_subset[[10]]/10000


recorte_mndwi <- (b_b03 - b_b11)/(b_b03 + b_b11)

plot(recorte_mndwi)
hist(recorte_mndwi)

# convierto a vector
mndwi_vector <- as.vector(recorte_mndwi)

kk <- kmeans(x = mndwi_vector, centers = 2)
kk$centers

kk1 <- mndwi_vector[kk$cluster == 1]
kk2 <- mndwi_vector[kk$cluster == 2]

kk_lim <- mean(kk1) - 1.96*sd(kk1)
mean(kk2)

ll <- mean(c(kk$centers[1], kk$centers[2]))


# obtengo el valor límite (threshold) Otsu
# recorte_mndwi_array <- as.array(recorte_mndwi)

# lim_mndwi <- otsu(recorte_mndwi_array)

plot(recorte_mndwi < kk_lim)
# plot(LR_vector, add = TRUE)

# máscara de agua
mask_agua <- recorte_mndwi > kk_lim
plot(mask_agua)

mask_agua2 <- mask_agua
mask_agua2[mask_agua2 == 0] <- NA
plot(mask_agua2)

# agua_crop <- crop(agua < lim_agua, LR_vector)
# plot(mask_agua2)

writeRaster(mask_agua2, filename = "mapa/mask_agua2.tif")

# polígono irregular
vector_red <- shapefile("vectores/roi_LR_mapa_turb4.shp")

# recorte a LR, máscara de agua
oo_mask_agua <- raster::mask(mask_agua2, vector_red)

plot(oo)

# diferencia tif
# dif_tif <- raster("mapa/diferencia_LR.tif")
# yy <- agua_crop*dif_tif
# extent(agua_crop)
# extent(dif_tif)

# raster::plot(agua_crop*dif_tif)
# plot(agua_crop*dif_tif)


# algoritmo ---------------------------------------------------------------

# leo los datos
datos <- read_tsv("algoritmo/turb_reflec_algoritmo.tsv")

mod_lin <- lm(formula = turb ~ I(B05*B03) + B03 + B05, data = datos)
sum_lin <- summary(mod_lin)
# R^2 = 0.9264183


# coeficientes
# a_0 + a_1 * B05 * B03 + a_2* B03 + a_3 * B05
a_0 <- sum_lin$coefficients[1, 1]
a_1 <- sum_lin$coefficients[2, 1]
a_2 <- sum_lin$coefficients[3, 1]
a_3 <- sum_lin$coefficients[4, 1]

# b_B05 <- LR_subset[[5]]/10000
# b_B03 <- LR_subset[[3]]/10000

LR_turb <- a_0 + a_1*b_b05*b_b03 + a_2*b_b03 + a_3*b_b05
plot(LR_turb)

# aplico al raster de turb, la máscara de agua (agua_crop)
turb_mask <- LR_turb*oo_mask_agua
plot(turb_mask)

# turb_mask2 <- turb_mask
# turb_mask2[turb_mask2 == 0] <- NA


# mapa

# convierto stack & vector a LON-LAT
stack_subset2 <- projectRaster(turb_mask,
                           crs = CRS("+proj=longlat +datum=WGS84 +no_defs"))
# puntos2 <- spTransform(puntos, CRS("+proj=longlat +datum=WGS84 +no_defs"))
# puntos2$nombre <- c("LR1", "LR2", "LR3", "LT") # agrego nombre de los sitios


color_max <- cellStats(stack_subset2, stat = max)
color_min <- cellStats(stack_subset2, stat = min)


# mapa
# print(glue("\n\nGenerando mapa\n\n"))

# título del mapa (fecha)
titulo <- tags$p(tags$style("p {color: black; font-size:22px}"),
             tags$p(format(ymd(20221127), format = "%d-%m-%Y")))

# zoom
ext <- extent(stack_subset2)
zoom_lat <- mean(c(ext@ymin, ext@ymax))
zoom_lng <- mean(c(ext@xmin, ext@xmax))

# logo GISTAQ
logo <- "extras/gistaq_logo.svg"

# leaflet
# options(viewer = NULL)

# paleta de colores
pal <- colorNumeric(c("#ff7300", "#f5f2f0", "#1505f5"), values(stack_subset2),
                    na.color = "transparent")

# etiquetas/labes
# etq <- 


mapa_tt <- leaflet(stack_subset2, 
                   options = leafletOptions(zoomControl = FALSE)) |> 
    # capa Google Maps
    addTiles(urlTemplate = "http://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}",
             attribution = "Google",
             group = "Google Maps") |> 
    # capa Google Satellite
    addTiles(urlTemplate = "http://mt0.google.com/vt/lyrs=s&hl=en&x={x}&y={y}&z={z}",
             attribution = "Google",
             group = "Google Satellite") |> 
    addRasterImage(stack_subset2,
                   colors = pal,
                   group = "turb",
                   layerId = "turb") |>
    # barra de transparencia p/capa RGB
    addOpacitySlider(layerId = "turb") |> 
    # control de las capas
    addLayersControl(
        baseGroups = c("Google Maps", "Google Satellite"),
        overlayGroups = c("turb"),
        options = layersControlOptions(collapsed = FALSE)) |> 
    # agrego título
    addControl(titulo, position = "topleft") |> 
    # botón p/restablecer la vista
    addResetMapButton() |> 
    # agrego logo GISTAQ
    addLogo(img = logo,
            src = "local",
            alpha = 1,
            position = "bottomleft",
            width = 200,
            height = 200 * 295 / 845) |> 
    # leyenda
    addLegend(pal = pal, values = values(stack_subset2),
              title = "Turbidez (NTU)") |> 
    # zoom
    setView(lng = zoom_lng, lat = zoom_lat, zoom = 17) |> 
    # agrego los valores de turb
    addImageQuery(
        stack_subset2,
        type="mousemove",
        layerId = "turb",
        digits = 1, prefix = "Turbidez")

mapa_tt

# guardo mapa, como .html, en un único archivo
saveWidget(widget = mapa_tt, file = "mapa_turb.html", 
           selfcontained = TRUE)