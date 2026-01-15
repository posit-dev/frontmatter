# write_front_matter() writes standard YAML front matter

    Code
      write_front_matter(fm)
    Output
      ---
      title: Test
      author: Me
      ---
      
      Body content

# write_front_matter() writes standard TOML front matter

    Code
      write_front_matter(fm, delimiter = "toml")
    Output
      +++
      title = "Test"
      count = 42
      +++
      
      Body content

# write_front_matter() writes yaml_comment format

    Code
      write_front_matter(fm, delimiter = "yaml_comment")
    Output
      # ---
      # title: Test
      # ---
      #
      # R code here

# write_front_matter() writes toml_comment format

    Code
      write_front_matter(fm, delimiter = "toml_comment")
    Output
      # +++
      # title = "Test"
      # +++
      #
      # R code here

# write_front_matter() writes yaml_roxy format

    Code
      write_front_matter(fm, delimiter = "yaml_roxy")
    Output
      #' ---
      #' title: Test
      #' ---
      #'
      #' Roxygen comment

# write_front_matter() writes toml_roxy format

    Code
      write_front_matter(fm, delimiter = "toml_roxy")
    Output
      #' +++
      #' title = "Test"
      #' +++
      #'
      #' Roxygen comment

# write_front_matter() writes PEP 723 format

    Code
      write_front_matter(fm, delimiter = "toml_pep723")
    Output
      # /// script
      # dependencies = ["requests", "numpy"]
      # ///
      
      import requests
      print('hello')

