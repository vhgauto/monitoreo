library(sf)
library(sen2r)
library(lubridate)
library(glue)
library(raster)
library(rgdal)
library(ggtext)
library(tidyverse)

disponibilidad <- function(date = fecha, server = "scihub") {
    # ROI, en coordenadas EPGS: 32721
    lr <- st_sfc(st_point(c(305789.86931, 6965069.94723)), crs = 32721)

    # descargo el producto para la fecha dada
    dia <- ymd(date)
    fecha1 <- c(dia, dia)

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

    # nombre de los productos encontrados y disponibilidad
    est <- safe_is_online(lis, verbose = FALSE)

    # mostrar el resultado en la consola, como tabla
    print(knitr::kable(tibble(producto = names(est), estado = est),
                       format = "pipe"))
}

descarga_safe <- function(server = "scihub") {
    # condición de ERROR
    # si SAFE existe, NO descarga
    if (file.exists(paste0("safe/", names(lis))) == TRUE)
        stop(glue("{'\n\nSAFE ya descargado\n\n'}"))

    # condición de ERROR
    # si SAFE NO existe, pero el recorte SÍ existe, NO descarga
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

    # si la base de datos contiene las reflectancias, NO extrae datos
    base_de_datos <- read_tsv("datos/datos_espectrales.tsv")
    fecha_x <- fecha
    # verifico si en la base de datos existe la fecha dada
    n_if <- base_de_datos  |>
        filter(fecha == ymd(fecha_x))

    if (nrow(n_if) != 0) {
        print(glue("{'\n\n\nDatos ya extraídos.\n\n\n'}"))
        return(n_if)
        }

    print(glue("\n\nLevanto el stack subset\n\n"))

    # archivo stack
    ras1 <- glue("recortes/{fecha}.tif")
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
}

firma_espectral <- function() {

    options(warn = -1)

    # condición de ERROR
    # si NO existe el recorte, NO grafica la firma espectral
    if (file.exists(glue("recortes/{fecha}.tif")) == FALSE) 
        stop(glue("{'Subset no encontrado.'}"))

    print(glue("\n\nLectura de datos\n\n"))

    firm <- glue("datos/{fecha}.csv")
    firm_tbl <- read.csv(firm) %>% as_tibble()

    lin <- 2
    punt <- 1
    alfa <- .7
    centro <- c(442, 490, 560, 665, 705, 740, 784, 842, 865, 1610, 2190)
    banda <- c("B01", "B02", "B03", "B04", "B05", "B06",
               "B07", "B08", "B8A", "B11", "B12")
    # fecha
    oo <- as.Date.character(fecha, format = "%Y%m%d")

    print(glue("\n\nGraficando\n\n"))

    gg_firma <- firm_tbl %>%
        # selecciono únicamente las filas de las bandas
        filter(str_detect(param, "B")) %>% 
        mutate(centro = centro) %>%
        pivot_longer(cols = -c(param, centro),
                     values_to = "firma",
                     names_to = "punto") %>%
        ggplot() +
        # verticales
        geom_vline(aes(xintercept = centro), color = "grey", linetype = 2) +
        # firma
        geom_point(aes(x = centro, y = firma, colour = punto), size = punt,
                   alpha = 1) +
        geom_line(aes(x = centro, y = firma, colour = punto), size = lin,
                  alpha = alfa, lineend = "round") +
        # tema
        theme_bw() +
        # scale_color_brewer(palette = "Dark2") +
        scale_color_manual(values = MetBrewer::met.brewer(name = "Egypt")) +
        # scale_color_manual(values = inthenameofthemoon("TokyoTower")) +
        # ejes
        labs(x = "\U03BB (nm)", y = "R<sub>s</sub>", title = glue(
                "<span style = 'color:#68228B'>{format(oo, '%d-%m-%Y')}</span>\\
                <span style = 'color:#36648B'> **Firma espectral**</span>")) +
        scale_x_continuous(limits = c(400, 2200), breaks = seq(400, 2200, 200),
            expand = c(0, 0), position = "bottom",
            # 2do eje horizontal
            sec.axis = sec_axis(~ ., breaks = centro, labels = glue("{banda}"))) +
        # scale_y_continuous(labels = function(x) ifelse(x == 0, "0", x)) +
        scale_y_continuous(labels = scales::label_number(big.mark = ".", decimal.mark = ",")) +
        # tema
        theme_bw() +
        guides(color = guide_legend(override.aes = list(size = 5,
                                                        linetype = NA,
                                                        shape = 15,
                                                        alpha = alfa))) +
        # theme
        theme(
            text = element_text(family = "serif"),
            aspect.ratio = .7,
            # leyenda
            legend.title = element_blank(),
            legend.position = c(.85, .85),
            legend.direction = "vertical",
            legend.spacing.x = unit(.01, "line"),
            legend.key.width = unit(1, "cm"),
            legend.key.height = unit(.1, "cm"),
            legend.key = element_rect(fill = NA),
            legend.text = element_text(size = 10),
            legend.background = element_rect(fill = NA),
            legend.box.background = element_rect(fill = NA, color = NA),
            # grid
            panel.grid.minor = element_blank(),
            panel.grid.major = element_line(size = .25),
            panel.border = element_rect(color = NA),
            panel.background = element_rect(fill = "transparent"),
            # plot
            plot.margin = margin(5, 20, 5, 5),
            plot.caption = element_markdown(),
            plot.title = element_markdown(size = 17),
            plot.subtitle = element_markdown(size = 13),
            plot.background = element_rect(fill = "transparent", color = NA),
            # eje
            axis.title = element_markdown(size = 15),
            axis.title.x = element_markdown(),
            axis.title.y = element_markdown(),
            axis.text = element_text(size = 13, color = "black"),
            axis.text.x.top = element_markdown(angle = 90, 
                                               vjust = .5, size = 6),
            axis.ticks = element_line(color = "black"),
            axis.ticks.length.x.top = unit(0, units = "cm"),
            axis.line = element_line(size = .25, color = "black")
            # axis.line.y.left = element_line(size = .25, colour = "black"),
            # axis.line.x.bottom = element_line(size = .25, colour = "black")
        )
    
    # guardo como .png
    ggsave(
        plot = gg_firma,
        filename = "figuras/firma.png",
        device = "png",
        dpi = 600,
        width = 17,
        height = 14,
        units = "cm"
    )

}