library(sf)
library(sen2r)
library(tidyverse)
library(lubridate)


disponibilidad <- function(date = fecha, server = "scihub") {
    # ROI, en coordenadas EPGS: 32721
    LR <- st_sfc(st_point(c(305789.86931, 6965069.94723)), crs = 32721)
    # descargar una fecha específica
    dia <- ymd(date)
    fecha1 <- c(dia, dia)
    # lista de productos Sentinel-2, nivel L2A
    # tile p/LR & LT: T21JUK
    # server: 'apihub' ó 'dhus'
    
    lis <<-
        s2_list(
            spatial_extent = LR,
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