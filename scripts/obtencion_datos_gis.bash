#!/usr/bin/env bash

rm -rf safe/*

scripts/obtencion_datos_gis.R

# scripts/firma_espectral.R

# R -e "library(rmarkdown); render('index.rmd')"
