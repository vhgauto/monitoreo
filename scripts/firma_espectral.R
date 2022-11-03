#!/usr/bin/env Rscript

# librerías
library(lubridate)
library(glue)
library(ggtext)
library(tidyverse)

# día de la fecha
hoy <- ymd(20221102) # ymd(20221102) # today()

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
firm <- "datos/datos_nuevos.tsv"
firm_tbl <- read.table(firm, header = TRUE) %>% as_tibble()

# parámetros de la figura
lin <- 2
punt <- 1
alfa <- .7
centro <- c(442, 490, 560, 665, 705, 740, 784, 842, 865, 1610, 2190)
banda <- c("B01", "B02", "B03", "B04", "B05", "B06",
           "B07", "B08", "B8A", "B11", "B12")

# grafico
print(glue("\n\nGraficando\n\n"))

gg_firma <- firm_tbl %>%
    # filter(fecha == hoy) |>
    dplyr::select(-fecha) |>
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
    scale_color_manual(values = MetBrewer::met.brewer(name = "Egypt")) +
    # ejes
    labs(x = "\U03BB (nm)", y = "R<sub>s</sub>", title = glue(
            "<span style = 'color:#68228B'>{format(hoy, '%d-%m-%Y')}</span>\\
            <span style = 'color:#36648B'> **Firma espectral**</span>")) +
    scale_x_continuous(limits = c(400, 2200), breaks = seq(400, 2200, 200),
        expand = c(0, 0), position = "bottom",
        # 2do eje horizontal
        sec.axis = sec_axis(~ ., breaks = centro,
                            labels = glue("{banda}"))) +
    # scale_y_continuous(labels = function(x) ifelse(x == 0, "0", x)) +
    scale_y_continuous(labels =
                       scales::label_number(big.mark = ".",
                                            decimal.mark = ",")) +
    # tema
    theme_bw() +
    guides(color = guide_legend(override.aes =
                   list(size = 5, linetype = NA, shape = 15, alpha = alfa))) +
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
        axis.line.x.top = element_blank(),
        axis.line.x.bottom = element_line(size = .25, color = "black"),
        axis.line.y.left = element_line(size = .25, color = "black")
    )

# guardo como .png
print(glue("\n\nGuardo firma espectral\n\n"))
ggsave(
    plot = gg_firma,
    filename = "figuras/firma.png",
    device = "png",
    dpi = 600,
    width = 17,
    height = 14,
    units = "cm"
)