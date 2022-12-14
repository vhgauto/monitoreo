#!/usr/bin/env Rscript

# librerías
library(lubridate)
library(glue)
library(ggtext)
library(showtext)
library(tidyverse)

# función para generar mensajes en la consola, para separar las secciones
f_msj <- function(x) {
    a <- nchar(x)
    b <- str_flatten(rep("X", a + 8))
    c <- str_flatten(c("X", rep(" ", a + 6), "X"))
    d <- str_flatten(c("X   ", x, "   X"))
    e <- glue("\n\n{b}\n{c}\n{d}\n{c}\n{b}\n\n")

    return(e)
}

# FIRMA ESPECTRAL

print(glue("{f_msj('FIRMA ESPECTRAL')}"))

# leo la base de datos
print(glue("\n\nLectura de datos\n\n"))
firm <- read_tsv(file = "datos/datos_nuevos.tsv")

# fecha de la imagen
fecha_ti <- distinct(firm, fecha) |> pull()

# parámetros de la figura
lin <- 2
punt <- 1
alfa <- .7
centro <- c(442, 490, 560, 665, 705, 740, 784, 842, 865, 1610, 2190)
banda <- c("B01", "B02", "B03", "B04", "B05", "B06",
           "B07", "B08", "B8A", "B11", "B12")

# grafico
print(glue("\n\nGraficando\n\n"))

# fuentes
font_add_google(name = "Playfair Display", family = "playfair") # título
font_add_google(name = "Inter", family = "inter") # resto del texto
showtext_auto()
showtext_opts(dpi = 300)

gg_firma <- firm |>
    dplyr::select(-fecha) |>
    mutate(centro = centro) |>
    # pivot_longer(cols = -c(param, centro),
    #                 values_to = "firma",
    #                 names_to = "punto") |>
    ggplot() +
    # verticales
    geom_vline(aes(xintercept = centro), color = "grey", linetype = 2) +
    # firma
    geom_point(aes(x = centro, y = reflec), size = punt,
                alpha = 1, color = "#43b284") +
    geom_line(aes(x = centro, y = reflec), linewidth = lin,
                alpha = alfa, lineend = "round", color = "#43b284") +
    # ejes
    labs(x = "\U03BB (nm)",
         y = "R<sub>s</sub>",
         title = glue("Firma espectral"),
         subtitle = glue("Fecha: {format(fecha_ti, '%d-%m-%Y')}"),
         caption = glue("{format(now(tzone = 'America/Argentina/Buenos_Aires'), '%d/%m/%Y %T')}")) +
    scale_x_continuous(limits = c(400, 2200), breaks = seq(400, 2200, 200),
        expand = c(0, 0), position = "bottom",
        # 2do eje horizontal
        sec.axis = sec_axis(~ ., breaks = centro,
                            labels = glue("{banda}"))) +
    scale_y_continuous(labels =
                       scales::label_number(big.mark = ".",
                                            decimal.mark = ",")) +
    # tema
    theme_bw() +
    # theme
    theme(
        aspect.ratio = .7,
        # grid
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(size = .25),
        panel.border = element_rect(color = NA),
        panel.background = element_rect(fill = "ivory"),
        # plot
        plot.margin = margin(0, 20, 0, 5),
        plot.title = element_markdown(size = 22, family = "playfair"),
        plot.title.position = "plot",
        plot.subtitle = element_markdown(size = 13, family = "inter"),
        plot.caption = element_markdown(hjust = 0, family = "inter"),
        plot.background = element_rect(fill = "ivory", color = NA),
        # eje
        axis.title = element_markdown(size = 15),
        axis.title.x = element_markdown(),
        axis.title.y = element_markdown(),
        axis.text = element_text(size = 13, color = "black", family = "inter"),
        axis.text.x.top = element_markdown(angle = 90, family = "inter",
                                            vjust = .5, size = 6),
        axis.ticks = element_line(color = "black"),
        axis.ticks.length.x.top = unit(0, units = "cm"),
        axis.line.x.top = element_blank(),
        axis.line.x.bottom = element_line(linewidth = .25, color = "black"),
        axis.line.y.left = element_line(linewidth = .25, color = "black")
    )

# creo la carpeta para almacenar la firma espectral
dir.create("figuras")

# elimino la firma espectral anterior
unlink(list.files("figuras/", full.names = TRUE), recursive = TRUE)

# guardo como .png
print(glue("\n\nGuardo firma espectral\n\n"))
ggsave(plot = gg_firma,
       filename = "figuras/firma.png",
       device = "png",
       dpi = 300,
       width = 20,
       height = 16,
       units = "cm")

print(glue("{f_msj('FIRMA ESPECTRAL COMPLETA')}"))
