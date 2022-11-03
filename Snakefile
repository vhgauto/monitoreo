rule targets:
    input:
        "datos/datos_nuevos.tsv",
        "figuras/firma.png"

rule obtencion_datos_gis:
    input:
        script = "scripts/obtencion_datos_gis.R"
    output:
        "datos/datos_nuevos.tsv"
    shell:
        """
        {input.script}
        """

rule firma_espectral:
    input:
        script = "scripts/firma_espectral.R",
        input = "datos/datos_nuevos.tsv"
    output:
        "figuras/firma.png"
    shell:
        """
        {input.script}
        """