# library(sf)
# library(sen2r)
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

# if (file.exists(paste0("safe/", names(lis))) == TRUE)
#     stop(glue("{'\n\nSAFE ya descargado\n\n'}"))

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
        mutate(fecha = ymd(fecha)) |>
        # reacomodo el orden de las columnas
        select(fecha, param, LR1, LR2, LR3, LT)

# combino con la base de datos
print(glue("\n\nIncorporo a la base de datos\n\n"))
base_de_datos <- bind_rows(base_de_datos, base)

# escrivo el archivo .tsv
write_tsv(base_de_datos,
            file = "datos/datos_espectrales.tsv") # path completo del .csv

return(tail(base_de_datos, 11))
# }