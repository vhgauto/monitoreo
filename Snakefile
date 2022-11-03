rule targets:
    input:
        "recortes/recorte.tif",
        "datos/datos_espectrales.tsv",
        "figuras/firma.png"

rule descargar_safe:
    input:
        script = "scripts/descarga_y_recorte.R"
    output:
        "recortes/recorte.tif"
    shell:
        """
        {input.script}
        """

rule extraer_reflec:
    input:
        script = "scripts/extraccion.R",
        input = "recortes/recorte.tif"
    output:
        "datos/datos_espectrales.tsv"
    shell:
        """
        {input.script}
        """

rule firma_espectral:
    input:
        script = "scripts/firma_espectral.R",
        input = "datos/datos_espectrales.tsv"
    output:
        "figuras/firma.png"
    shell:
        """
        {input.script}
        """