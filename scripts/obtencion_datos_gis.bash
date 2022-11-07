#!/usr/bin/env bash

scripts/obtencion_datos_gis.R

scripts/firma_espectral.R

R -e "library(quarto); quarto_render('index.qmd')"
