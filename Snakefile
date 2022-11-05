rule targets:
    input:
        "datos/datos_nuevos.tsv",
        "figuras/firma.png",
        "index.html"

rule obtencion_datos_gis:
    input:
        script = "scripts/obtencion_datos_gis.bash"
    output:
        "datos/datos_nuevos.tsv"
    conda:
        "environment.yml"
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
    conda:
        "environment.yml"
    shell:
        """
        {input.script}
        """

rule render_index:
    input:
        rmd = "index.Rmd",
        png = "figuras/firma.png"
    output:
        "index.html"
    conda:
        "environment.yml"
    shell:
        """
        R -e "library(rmarkdown); render('{input.rmd}')"
        """
