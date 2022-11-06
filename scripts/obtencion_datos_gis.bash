#!/usr/bin/env bash

scripts/obtencion_datos_gis.R

scripts/firma_espectral.R

quarto render index.Qmd --to html