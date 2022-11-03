# 1. Inicio ----
fecha <- 20221028 # escribo la fecha de interés, en formato AAAAMMDD
# cargo funciones externas
source("scripts/funciones__001.R", encoding = "UTF-8")

# 2. Descarga ----
disponibilidad()
descarga_safe()

# 3. Extracción ----
datos_reflec()

# 4. Firma espectral ----
firma_espectral()
