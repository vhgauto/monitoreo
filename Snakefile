rule targets:
    input:
        "recortes/recorte.tif",
        "datos/datos_nuevos.tsv",
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
        input_tif = "recortes/recorte.tif",
        input_tsv = "datos/datos_previos.tsv"
    output:
        "datos/datos_nuevos.tsv"
    shell:
        """
        {input.script}
        """

rule firma_espectral:
    input:
        script = "scripts/firma_espectral.R",
        input = "datos/datos_previos.tsv"
    output:
        "figuras/firma.png"
    shell:
        """
        {input.script}
        """