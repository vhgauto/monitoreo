rule targets:
    input:
        script = "scripts/demo.bash"
    shell:
        """
        {input.script}
        """
