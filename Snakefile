rule targets:
    input:
        script = "scripts/demo.bash"
    conda:
        "environmet.yml"
    shell:
        """
        {input.script}
        """
