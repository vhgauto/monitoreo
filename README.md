# Proyecto GISTAQ Monitoreo 2020

El presente repositorio contiene los scripts correspondientes al Proyecto de Investigación "Caracterización fisicoquímica de cuerpos de aguas continentales para la evaluación de la utilización de algoritmos en el monitoreo satelital de la calidad del agua" (MSPPBRE0008091), desarrollado por el Grupo de Investigación Sobre Temas Ambientales y Químicos (GISTAQ), perteneciente a la Universidad Tecnológica Nacional Facultad Regional Resistencia (UTN-FRRe).

Las tareas que se ejecutan tienen como finalidad:

- Descargar el producto Sentinel-2 MSI, nivel de procesamiento [L2A](https://sentinels.copernicus.eu/web/sentinel/user-guides/sentinel-2-msi/processing-levels/level-2), tile 21JUK, del día de la fecha.
- Recortar el producto a la región de interés para generar un stack con las bandas seleccionadas (B01, B02, B03, B04, B05, B06, B07, B08, B8A, B11, B12).
- Extraer los valores de píxel (reflectancia de superficie) de los puntos muestrales (3 ubicados en Laguna [La Ribera](https://goo.gl/maps/CBzpv8khrSonE4Fw9), 1 ubicado en [La Toma](https://goo.gl/maps/WMDzJCJnPCbFjQhb8)).
- Generar una base de datos (.tsv) unificada.
- Graficar la firma espectral de la fecha dada.

El mapa de la laguna La Ribera, con los valores de turbidez (NTU) para cada píxel de agua, se encuentra en el siguiente [link](https://vhgauto.github.io/monitoreo/).

Contacto:  
GISTAQ: [gistaq@ca.frre.utn.edu.ar](mailto:gistaq@ca.frre.utn.edu.ar)  
Dirección: French 414, Resistencia, Chaco, CP 3500  
Encargado del presente repositorio: [Víctor Gauto](mailto:victor.gauto@outlook.com)

[![Ejecuto el Proyecto Monitoreo GISTAQ 2020](https://github.com/vhgauto/monitoreo/actions/workflows/run_pipeline.yml/badge.svg)](https://github.com/vhgauto/monitoreo/actions/workflows/run_pipeline.yml)
