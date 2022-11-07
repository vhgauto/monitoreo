rule targets:
    input:
        "scripts/obtencion_datos_gis.bash",
        "figuras/firma.png",
        "index.html"

rule descarga_y_extraccion:
    input:
        script = "scripts/obtencion_datos_gis.bash"
    output:
        "figuras/firma.png"
    conda:
        "environment.yml"
    shell:
        """
        {input.script}
        """

# rule figura_firma:
#     input:
#         script = "scripts/firma_espectral.R"
#     output:
#         "figuras/firma.png"
#     conda:
#         "environment.yml"
#     shell:
#         """
#         {input.script}
#         """

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