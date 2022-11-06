rule targets:
    input:
        script = "scripts/obtencion_datos_gis.bash"
    conda:
        "environment.yml"
    shell:
        """
        {input.script}
        """
