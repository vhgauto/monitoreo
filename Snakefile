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
