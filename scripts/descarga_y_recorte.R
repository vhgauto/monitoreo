library(sf)
library(sen2r)
library(lubridate)
library(glue)
library(raster)
library(rgdal)
# library(ggtext)
library(tidyverse)

hoy <- ymd(20221102) # today()

# descarga_safe <- function(server = "scihub") {
    # condición de ERROR
    # si SAFE existe, NO descarga
base_de_datos <- read_tsv("datos/datos_espectrales.tsv")

n_if <- base_de_datos  |>
        filter(fecha == hoy)

if (nrow(n_if) != 0) {
    print(glue("{'\n\n\nDatos ya extraídos.\n\n\n'}"))
    return(n_if)
    }

lr <- st_sfc(st_point(c(305789.86931, 6965069.94723)), crs = 32721) 

    # descargo el producto para la fecha dada
# dia <- ymd(date)
fecha1 <- c(hoy, hoy)

# lista de productos Sentinel-2, nivel L2A
# tile: T21JUK
# server: 'apihub' ó 'dhus'

lis <<- s2_list(
                spatial_extent = lr,
                time_interval = fecha1,
                level = "L2A",
                tile = "21JUK", # únicamente el tile JUK
                server = server # scihub
                )

# if (file.exists(paste0("safe/", names(lis))) == TRUE)
#     stop(glue("{'\n\nSAFE ya descargado\n\n'}"))

    # condición de ERROR
    # si SAFE NO existe, pero el recorte SÍ existe, NO descarga
# if (file.exists(paste0("recortes/", fecha, ".tif")) == TRUE)
#     stop(glue("{'\n\nSubset ya creado\n\n'}")) 

    # descarga
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

print(glue("\n\nCargo las bandas\n\n"))

# vector
vec <- shapefile("vectores/roi.shp", verbose = FALSE)

# solo me interesan R10m y R20m (R60m NO!)
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

print(glue("\n\nRecorto las bandas al \u00E1rea de inter\u00E9s\n\n"))
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

# eliminar carpeta SAFE post recorte
unlink(glue("{getwd()}/safe/recorte.tif"), recursive = TRUE)
# }