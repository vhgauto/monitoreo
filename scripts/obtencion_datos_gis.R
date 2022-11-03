#!/usr/bin/env Rscript

# librerías
library(sf)
library(sen2r)
library(lubridate)
library(glue)
library(raster)
library(rgdal)
library(tidyverse)

# día de la fecha
hoy <- ymd(20221102) # today()

# ymd(20221102) # today()
# verifico disponibilidad del producto
# base_de_datos <- read_tsv("datos/base_de_datos.tsv")
# n_if <- base_de_datos  |>
#         filter(fecha == hoy)
# if (nrow(n_if) != 0) {
#   print(glue("{'\n\n\nDatos ya extraídos.\n\n\n'}"))
#   return(n_if)
#   }

# sitio de interés
lr <- st_sfc(st_point(c(305789.86931, 6965069.94723)), crs = 32721) 

    # descargo el producto para la fecha dada
# dia <- ymd(date)

# fecha de interés
fecha1 <- c(hoy, hoy)

# lista de productos Sentinel-2, nivel L2A
# tile: T21JUK
# server: 'apihub' ó 'dhus'

# busco producto Sentinel-2 MSI L2A, tile 21JUK
lis <- s2_list(
                spatial_extent = lr,
                time_interval = c(hoy, hoy),
                level = "L2A",
                tile = "21JUK", # únicamente el tile JUK
                server = "scihub" # scihub
                )

# CONDICIÓN DE ERROR
if (length(lis) == 0) {
   stop(glue("'\n\n\nNo hay producto disponible para el {hoy}.\n\n\n'"))
}

# if (file.exists(paste0("safe/", names(lis))) == TRUE)
#     stop(glue("{'\n\nSAFE ya descargado\n\n'}"))

    # condición de ERROR
    # si SAFE NO existe, pero el recorte SÍ existe, NO descarga
# if (file.exists(paste0("recortes/", fecha, ".tif")) == TRUE)
#     stop(glue("{'\n\nSubset ya creado\n\n'}")) 

# descarga el producto
s2_download(lis, service = "apihub", overwrite = FALSE,
            outdir = "safe/")

# }

# recorte <- function() {
    # condición de ERROR
    # si el recorte existe, NO recorta
    # if (file.exists(glue("recortes/{fecha}.tif")) == TRUE)
    #    stop(glue("{'\n\nSubset ya creado\n\n'}"))

    # condición de ERROR
    # si el SAFE NO existe, pero el recorte SÍ existe, NO recorta
    # if (file.exists(glue("safe/{names(lis)}")) == FALSE)
    #    stop(glue("{'\n\nSAFE no encontrado\n\n'}"))

print(glue("\n\nProducto descargado\n\n"))


# vector
print(glue("\n\nCargo vertor de la región de interés\n\n"))
vec <- shapefile("vectores/roi.shp", verbose = FALSE)

# solo me interesan R10m y R20m (R60m NO!)
print(glue("\n\nCargo las bandas\n\n"))

reso <- list.files(file.path(list.files(
    file.path(getwd(), "safe",
                names(lis), "GRANULE"), full.names = TRUE
), "IMG_DATA"),
full.names = TRUE)

# guardo las bandas en orden:
# B01, B02, B03, B04, B05, B06, B07, B08, B8A, B11, B12 [11 elementos]
lis_1020 <- c(
    list.files(reso[3], full.names = T)[2],    # B01
    list.files(reso[1], full.names = T)[2:4],  # B02, B03, B04
    list.files(reso[2], full.names = T)[6:8],  # B05, B06, B07
    list.files(reso[1], full.names = T)[5],    # B08
    list.files(reso[2], full.names = T)[11],   # B8A
    list.files(reso[2], full.names = T)[9:10]  # B11, B12
)

print(glue("\n\nGenero los r\u00E1ster para cada banda\n\n"))
# lista que contiene las bandas ráster
ras_1020 <- map(.x = lis_1020, raster)

print(glue("\n\nRecorto las bandas a la regi\u00F3n de inter\u00E9s\n\n")) # no lint # nolint
# lista que contiene el subset según el ROI
subset <- map(.x = ras_1020, ~ crop(.x, vec))

print(glue("\n\nResampling de bandas a 10m\n\n"))
# p/crear un stack que contenga todas las bandas, tengo que cambiar la
# resolución de las bandas
# bandas con 60m: B01 [1]
# bandas con 20m: B05 [5], B06 [6], B07 [7] , B8A [9], B11 [10], B12 [11]
# bandas con 10m: B02 [2], B03 [3], B04 [4], B08 [8]
subset_B02 <- subset[[2]]
subset_B01 <- resample(subset[[1]], subset[[2]], method = "ngb")
subset_B03 <- subset[[3]]
subset_B04 <- subset[[4]]
subset_B05 <- resample(subset[[5]], subset[[2]], method = "ngb")
subset_B06 <- resample(subset[[6]], subset[[2]], method = "ngb")
subset_B07 <- resample(subset[[7]], subset[[2]], method = "ngb")
subset_B08 <- subset[[8]]
subset_B8A <- resample(subset[[9]], subset[[2]], method = "ngb")
subset_B11 <- resample(subset[[10]], subset[[2]], method = "ngb")
subset_B12 <- resample(subset[[11]], subset[[2]], method = "ngb")

# creo el stack
subset_stack <-
    raster::stack(subset_B01, subset_B02, subset_B03,
                    subset_B04, subset_B05, subset_B06,
                    subset_B07, subset_B08, subset_B8A,
                    subset_B11, subset_B12)

names(subset_stack) <-
    c("B01", "B02", "B03", "B04", "B05", "B06",
        "B07", "B08", "B8A", "B11", "B12")

print(glue("\n\nEscribo el stack de bandas recortado\n\n"))

# escribir el stack
writeRaster(
    subset_stack,
    filename = "recortes/recorte.tif",
    "GTiff",
    overwrite = TRUE
)

# elimino el contenido de la carpeta SAFE
unlink(x = list.files("safe", full.names = TRUE), recursive = TRUE)


print(glue("\n\nEXTRACCIÓN\n\n"))


# n_if <- base_de_datos  |>
#         filter(fecha == hoy)

# if (nrow(n_if) != 0) {
#     # print()
#     return(glue("{'\n\n\nDatos ya extraídos.\n\n\n'}"))
#     }


print(glue("\n\nLevanto el stack subset\n\n"))

    # archivo stack
ras1 <- "recortes/recorte.tif"
    # levanto el stack
rast <- raster::stack(ras1)

    # cargo el vector de puntos muestrales
print(glue("\n\nLevanto vector de puntos muestrales\n\n"))
puntos <- shapefile("vectores/puntos.shp") 

    # creo el data.frame con los datos de valor de pixel
    # nombre de las filas del data.frame
nomb_row <- c("B01", "B02", "B03", "B04", "B05", "B06",
                "B07", "B08", "B8A", "B11", "B12")
print(glue("\n\nExtraigo los valores de p\u00EDxel\n\n"))

# extraigo los valores de reflectancia de superficie del ráster
base <- raster::extract(rast, puntos)

# canvierto a data.frame y agrego columna con los puntos
base <- data.frame(base, punto = c("LR1", "LR2", "LR3", "LT"))

# arreglo los datos
base <- base |>
        pivot_longer(cols = -punto,
                        values_to = "firma",
                        names_to = "param") |>
        pivot_wider(id_cols = param,
                    values_from = firma,
                    names_from = punto) |>
        # cambio el nombre de las bandas
        mutate(param = nomb_row) |>
        # factor de escala
        mutate(LR1 = LR1 / 10000,
                        LR2 = LR2 / 10000,
                        LR3 = LR3 / 10000,
                        LT = LT / 10000) |>
        # agrego la fecha dada
        mutate(fecha = ymd(hoy)) |>
        # reacomodo el orden de las columnas
        dplyr::select(fecha, param, LR1, LR2, LR3, LT)

# escribo los datos nuevos
write_tsv(base,
          file = "datos/datos_nuevos.tsv")

# leo base de datos
base_de_datos <- read_tsv("datos/base_de_datos.tsv")

# combino con la base de datos
print(glue("\n\nIncorporo a la base de datos\n\n"))
base_de_datos <- bind_rows(base_de_datos, base)

# escrivo el archivo .tsv
write_tsv(base_de_datos,
            file = "datos/base_de_datos.tsv") # path completo del .csv

# return(tail(base_de_datos, 11))

base

print(glue("\n\nElimino recorte\n\n"))

unlink("recortes/recorte.tif", recursive = TRUE)