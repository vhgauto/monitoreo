library(sf)
library(sen2r)
library(lubridate)
library(glue)
library(raster)
library(rgdal)
library(tidyverse)

disponibilidad <- function(date = fecha, server = "scihub") {
    # ROI, en coordenadas EPGS: 32721
    lr <- st_sfc(st_point(c(305789.86931, 6965069.94723)), crs = 32721)
    # descargar una fecha específica
    dia <- ymd(date)
    fecha1 <- c(dia, dia)
    # lista de productos Sentinel-2, nivel L2A
    # tile p/LR & LT: T21JUK
    # server: 'apihub' ó 'dhus'

    lis <<-
        s2_list(
            spatial_extent = lr,
            time_interval = fecha1,
            level = "L2A",
            tile = "21JUK", # únicamente el tile JUK
            server = server # scihub ó gcloud
        )

    # nombre de los productos encontrados y disponibilidad
    est <- safe_is_online(lis, verbose = FALSE)
    # mostrar el resultado en la consola, como tabla
    print(knitr::kable(tibble(producto = names(est), estado = est),
                       format = "pipe"))
}

descarga_safe <- function(server = "scihub") {
    # condición de ERROR
    # si el SAFE existe, NO descarga
    if (file.exists(paste0("safe/", names(lis))) == TRUE) 
        stop(glue("{'\n\nSAFE ya descargado\n\n'}"))

    # condición de ERROR
    # si el SAFE NO existe, pero el recorte SÍ existe, NO descarga
    if (file.exists(paste0("recortes/", fecha, ".tif")) == TRUE) 
        stop(glue("{'\n\nSubset ya creado\n\n'}"))

    # descarga
    s2_download(lis, service = "apihub", overwrite = FALSE,
                outdir = "safe/")

}

datos_reflec <- function() {
    # condición de ERROR
    # si NO existe el recorte, NO extrae datos
    if (file.exists(glue("recortes/{fecha}.tif")) == FALSE) 
        stop(glue("{'Subset no encontrado.'}"))

    # si existe el .csv, NO extrae datos
    if (file.exists(glue("datos/{fecha}.csv")) == TRUE) {
        print(glue("{'\n\n\nDatos ya extraídos.\n\n\n'}"))
        return(read.csv(glue("datos/{fecha}.csv")) %>% as_tibble())
        }

    print(glue("\n\nLevanto el stack subset\n\n"))

    # stack
    ras1 <- glue("recortes/{fecha}.tif")
    # armo un stack
    rast <- raster::stack(ras1)

    # cargo el vector de puntos muestrales
    print(glue("\n\nLevanto vector de puntos muestrales\n\n"))
    # puntos <- shapefile("vectores/puntosJUK.shp")
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
    base <- base %>% pivot_longer(cols = -punto,
                                  values_to = "firma",
                                  names_to = "param") %>%
                    pivot_wider(id_cols = param,
                                values_from = firma,
                                names_from = punto)
    # cambio el nombre de las bandas
    base <- base %>% mutate(param = nomb_row)
    # factor de escala
    base <- base %>% mutate(LR1 = LR1 / 10000,
                            LR2 = LR2 / 10000,
                            LR3 = LR3 / 10000,
                            LT = LT / 10000)
    # creo el archivo .csv
    print(glue("\n\nCreo el archivo .csv\n\n"))
    nombreDATO <- glue("datos/{fecha}.csv")
    write_csv(base, file = nombreDATO) # path completo del .csv
    return(base)
}