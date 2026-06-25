# write and roundtrip yaml_sql_line format

    Code
      write_front_matter(fm, delimiter = "yaml_sql_line")
    Output
      -- ---
      -- title: Test
      -- author: Me
      -- ---
      
      SELECT * FROM sales

# write and roundtrip toml_sql_line format

    Code
      write_front_matter(fm, delimiter = "toml_sql_line")
    Output
      -- +++
      -- title = "Test"
      -- author = "Me"
      -- +++
      
      SELECT * FROM sales

# write and roundtrip yaml_sql_block_compact format

    Code
      write_front_matter(fm, delimiter = "yaml_sql_block_compact")
    Output
      /* ---
      title: Test
      author: Me
      --- */
      
      SELECT * FROM sales

# write and roundtrip toml_sql_block_compact format

    Code
      write_front_matter(fm, delimiter = "toml_sql_block_compact")
    Output
      /* +++
      title = "Test"
      author = "Me"
      +++ */
      
      SELECT * FROM sales

# write and roundtrip yaml_sql_block_expanded format

    Code
      write_front_matter(fm, delimiter = "yaml_sql_block_expanded")
    Output
      /*
      ---
      title: Test
      author: Me
      ---
      */
      
      SELECT * FROM sales

# write and roundtrip toml_sql_block_expanded format

    Code
      write_front_matter(fm, delimiter = "toml_sql_block_expanded")
    Output
      /*
      +++
      title = "Test"
      author = "Me"
      +++
      */
      
      SELECT * FROM sales

