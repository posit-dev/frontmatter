# parse_front_matter parses YAML correctly

    Code
      print(result)
    Output
      <front_matter format="yaml", delimiter="yaml">
      ──── Data────
      $title
      [1] "Test"
      
      $date
      [1] "2024-01-01"
      
      ──── Body────
      Body content 

# parse_front_matter parses TOML correctly

    Code
      print(result)
    Output
      <front_matter format="toml", delimiter="toml">
      ──── Data────
      $title
      [1] "Test"
      
      $count
      [1] 42
      
      ──── Body────
      Body content 

