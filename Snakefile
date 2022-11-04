rule targets:
    input:
        script = "scripts/demo.bash"
    conda:
        "environment.yml"
    shell:
        """
        {input.script}
        """
