# 1. Inicio ----
# escribo la fecha de interés, en formato AAAAMMDD
fecha <- 20221028
# cargo funciones externas
source("scripts/funciones__001.R", encoding = "UTF-8")
# activo los paquetes necesarios
paquetes()

# 2. Descarga ----
disponibilidad()
descarga_safe()

# 3. Extracción ----
datos_reflec()

# 4. Firma espectral ----
firma_espectral()
