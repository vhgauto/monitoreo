#!/usr/bin/env Rscript

# librerías
library(lubridate)
library(glue)
library(ggtext)
library(showtext)
library(tidyverse)

# día de la fecha
hoy <- today() - 1

# función para generar mensajes en la consola, para separar las secciones
f_msj <- function(x) {
    a <- nchar(x)
    b <- str_flatten(rep("X", a + 8))
    c <- str_flatten(c("X", rep(" ", a + 6), "X"))
    d <- str_flatten(c("X   ", x, "   X"))
    e <- glue("\n\n{b}\n{c}\n{d}\n{c}\n{b}\n\n")

    return(e)
}

# función para agregar logo
f_logo <- function(g, scale = .15, hjust = 1, valing = .045) {
    url <- "extras/gistaq_logo.png"
    logo <- magick::image_read(url)
    g <- g +
        theme(plot.margin = margin(10, 20, 15, 10))
    plot <-
        cowplot::ggdraw(g) +
        cowplot::draw_image(
            logo,
            scale = scale,
            x = 1,
            hjust = hjust,
            halign = 1,
            valign = valing
        )
    return(plot)
}

# FIRMA ESPECTRAL

print(glue("{f_msj('FIRMA ESPECTRAL')}"))

# leo la base de datos
print(glue("\n\nLectura de datos\n\n"))
firm <- read_tsv(file = "datos/datos_nuevos.tsv") # "datos/datos_nuevos.tsv"
# firm_tbl <- read.table(firm, header = TRUE) |> as_tibble()

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
    pivot_longer(cols = -c(param, centro),
                    values_to = "firma",
                    names_to = "punto") |>
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
    scale_color_manual(values = MetBrewer::met.brewer(name = "Egypt")) +
    # ejes
    labs(x = "\U03BB (nm)",
         y = "R<sub>s</sub>",
         title = glue("Firma espectral"),
         subtitle = glue("Fecha: {format(hoy, '%d-%m-%Y')}"),
         caption = glue("{now()}")) +
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
    guides(color = guide_legend(override.aes =
                   list(size = 5, linetype = NA, shape = 15, alpha = alfa))) +
    # theme
    theme(
        aspect.ratio = .7,
        # leyenda
        legend.title = element_blank(),
        legend.position = c(.85, .85),
        legend.direction = "vertical",
        legend.spacing.x = unit(.01, "line"),
        legend.key.width = unit(1, "cm"),
        legend.key.height = unit(.1, "cm"),
        legend.key = element_rect(fill = NA),
        legend.text = element_text(size = 10, family = "inter"),
        legend.background = element_rect(fill = NA),
        legend.box.background = element_rect(fill = NA, color = NA),
        # grid
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(size = .25),
        panel.border = element_rect(color = NA),
        panel.background = element_rect(fill = "ivory"),
        # plot
        plot.margin = margin(5, 20, 5, 5),
        plot.caption = element_markdown(hjust = 0, family = "inter"),
        plot.title = element_markdown(size = 17, family = "playfair"),
        plot.subtitle = element_markdown(size = 13, family = "inter"),
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
        axis.line.x.bottom = element_line(size = .25, color = "black"),
        axis.line.y.left = element_line(size = .25, color = "black")
    )

gg_logo <- f_logo(gg_firma)

# guardo como .png
print(glue("\n\nGuardo firma espectral\n\n"))
ggsave(
    plot = gg_logo,
    filename = "figuras/firma.png",
    device = "png",
    dpi = 300,
    width = 20,
    height = 17,
    units = "cm"
)
