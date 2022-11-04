rule demo:
    input:
        script: "scripts/demo.R"
    shell:
        """
        {input.script}
        """