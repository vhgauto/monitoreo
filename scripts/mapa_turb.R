#!/usr/bin/env Rscript

library(raster)
library(leaflet)
library(htmltools)
library(htmlwidgets)
library(leafem)
library(leaflet.opacity)
library(leaflet.extras)
library(EBImage)
library(lubridate)
library(tidyverse)

# stack ROI ---------------------------------------------------------------
# 20221127
recorte_stack <- raster::stack("recortes/recorte.tif")

# vector LR
laguna_vector <- shapefile("vectores/roi_LR_mapa_turb.shp")

# recorto
recorte_subset <- crop(recorte_stack, laguna_vector)

# RGB
plotRGB(recorte_subset, r = 4, g = 3, b = 2, stretch = "lin")

# máscara de agua ---------------------------------------------------------

# MNDWI
# 10.3390/rs8040354
# (B03 - B11) / (B03 + B11)
# afecto por el factor de escala
b_b03 <- recorte_subset[[3]] / 10000 # algoritmo TURB & MNDWI
b_b05 <- recorte_subset[[5]] / 10000 # algoritmo TURB
b_b11 <- recorte_subset[[10]] / 10000 # MNDWI

recorte_mndwi <- (b_b03 - b_b11) / (b_b03 + b_b11)

plot(recorte_mndwi)
hist(recorte_mndwi)

# convierto a vector
mndwi_vector <- as.vector(recorte_mndwi)

# obtengo k-means, 2 centros
k_laguna <- kmeans(x = mndwi_vector, centers = 2)
k_laguna$centers

# valores de MNDWI correspondientes al centro '1', agua
k1 <- mndwi_vector[k_laguna$cluster == 1]
k2 <- mndwi_vector[k_laguna$cluster == 2]

# k2 <- mndwi_vector[k_laguna$cluster == 2]

# valor limite de detección de agua
k_laguna_inf <- mean(k1) - 1.96 * sd(k1)
k_laguna_sup <- mean(k2) + 1.96 * sd(k2)

k_laguna_lim <- mean(k_laguna_inf, k_laguna_sup)


# EBImage
threshold <- otsu(img)
threshold


# mean(k2)
# ll <- mean(c(kk$centers[1], kk$centers[2]))
# obtengo el valor límite (threshold) Otsu
# recorte_mndwi_array <- as.array(recorte_mndwi)
# lim_mndwi <- otsu(recorte_mndwi_array)

plot(recorte_mndwi < k_laguna_lim)
# plot(LR_vector, add = TRUE)

# máscara de agua
mask_agua <- recorte_mndwi > k_laguna_lim
# plot(mask_agua)

# agrego NA
mask_agua2 <- mask_agua
mask_agua2[mask_agua2 == 0] <- NA
plot(mask_agua2)

# agua_crop <- crop(agua < lim_agua, LR_vector)
# plot(mask_agua2)

# writeRaster(mask_agua2, filename = "mapa/mask_agua2.tif")

# recorto alrededor de la laguna con un polígono irregular
# polígono irregular
vector_irr <- shapefile("vectores/roi_LR_mapa_turb4.shp")

# máscara de agua final
mask_agua3 <- raster::mask(mask_agua2, vector_irr)
# píxel agua -> 1
# píxel NO agua -> NA

plot(mask_agua3)

# diferencia tif
# dif_tif <- raster("mapa/diferencia_LR.tif")
# yy <- agua_crop*dif_tif
# extent(agua_crop)
# extent(dif_tif)
# raster::plot(agua_crop*dif_tif)
# plot(agua_crop*dif_tif)

# algoritmo ---------------------------------------------------------------

# leo los datos
datos <- read_tsv("datos/turb_reflec_algoritmo.tsv")

# modelo lineal, interacción entre B05 & B03
mod_lin <- lm(formula = turb ~ I(B05*B03) + B03 + B05, data = datos)
sum_lin <- summary(mod_lin)
# R^2 = 0.9264183

# coeficientes
# fórmula: a_0 + a_1 * B05 * B03 + a_2* B03 + a_3 * B05
a_0 <- sum_lin$coefficients[1, 1]
a_1 <- sum_lin$coefficients[2, 1]
a_2 <- sum_lin$coefficients[3, 1]
a_3 <- sum_lin$coefficients[4, 1]

laguna_turb <- a_0 + a_1 * b_b05 * b_b03 + a_2 * b_b03 + a_3 * b_b05
plot(laguna_turb)

# aplico al raster de turb, la máscara de agua (mask_agua3)
turb_mapa <- laguna_turb*mask_agua3
plot(turb_mapa)

# turb_mask2 <- turb_mask
# turb_mask2[turb_mask2 == 0] <- NA

# mapa --------------------------------------------------------------------

# convierto mapa a LON-LAT
turb_mapa2 <- projectRaster(turb_mapa,
                            crs = CRS("+proj=longlat +datum=WGS84 +no_defs"))

# obtengo los valores más/mín de turb, p/asignar colores
color_max <- cellStats(turb_mapa2, stat = max)
color_min <- cellStats(turb_mapa2, stat = min)

# mapa
# print(glue("\n\nGenerando mapa\n\n"))

# título del mapa (fecha)
titulo <- tags$p(tags$style("p {color: black; font-size:22px}"),
                 tags$p(format(ymd(20221127), format = "%d-%m-%Y")))

# zoom
ext <- extent(turb_mapa2)
zoom_lat <- mean(c(ext@ymin, ext@ymax))
zoom_lng <- mean(c(ext@xmin, ext@xmax))

# logo GISTAQ
logo <- "extras/gistaq_logo.png" # .sgv?

# paleta de colores
pal <- colorNumeric(c("#ff7300", "#f5f2f0", "#1505f5"), 
                    values(turb_mapa2),
                    na.color = "transparent")

mapa_f <- leaflet(turb_mapa2,
                  options = leafletOptions(zoomControl = FALSE)) |>
    # capa Google Maps
    addTiles(urlTemplate = "http://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}",
             attribution = "Google",
             group = "Google Maps") |>
    # capa Google Satellite
    addTiles(urlTemplate = "http://mt0.google.com/vt/lyrs=s&hl=en&x={x}&y={y}&z={z}",
             attribution = "Google",
             group = "Google Satellite") |>
    addRasterImage(turb_mapa2,
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
    addLegend(pal = pal, values = values(turb_mapa2),
              title = "Turbidez (NTU)") |>
    # zoom
    setView(lng = zoom_lng, lat = zoom_lat, zoom = 17) |>
    # agrego los valores de turb
    addImageQuery(
        turb_mapa2,
        type = "mousemove",
        layerId = "turb",
        digits = 1, 
        prefix = "Turbidez")

# guardo mapa, como .html, en un único archivo
saveWidget(widget = mapa_f, file = "mapa_turb.html",
           selfcontained = TRUE)

# elimino el recorte
# unlink(list.files(path = "recortes", full.names = TRUE), recursive = TRUE)