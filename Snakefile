rule targets:
    input:
        script = "scripts/demo.R"
    shell:
        """
        {input.script}
        """
