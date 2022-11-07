rule render_index:
    input:
        rmd = "index.rmd"
    conda:
        "environment.yml"
    shell:
        """
        R -e "library(rmarkdown); render('{input.rmd}')"
        """
