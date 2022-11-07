rule targets:
    input:
        "datos/datos_nuevos.tsv",
        "figuras/firma.png",
        "index.html"

rule descarga_y_extraccion:
    input:
        script = "scripts/obtencion_datos_gis.R"
    conda:
        "environment.yml"
    shell:
        """
        {input.script}
        """

rule figura_firma:
    input:
        script = "scripts/firma_espectral.R",
        file = "datos/datos_nuevos.tsv"
    conda:
        "environment.yml"
    shell:
        """
        {input.script}
        """

rule render_index:
    input:
        rmd = "index.rmd",
        png = "figuras/firma.png"
    output:
        "index.html"
    conda:
        "environment.yml"
    shell:
        """
        R -e "library(rmarkdown); render('{input.rmd}')"
        """