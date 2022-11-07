rule targets:
    input:
        "figuras/firma.png",
        "index.html"

rule datos_firma:
    input:
        script = "scripts/obtencion_datos_gis.bash"
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