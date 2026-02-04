# parse_front_matter parses YAML correctly

    Code
      print(result)
    Output
      <front_matter format="yaml", delimiter="yaml">
      ──── $data ────
      List of 2
       $ title: chr "Test"
       $ date : chr "2024-01-01"
      
      ──── $body ────
      Body content 

# parse_front_matter parses TOML correctly

    Code
      print(result)
    Output
      <front_matter format="toml", delimiter="toml">
      ──── $data ────
      List of 2
       $ title: chr "Test"
       $ count: int 42
      
      ──── $body ────
      Body content 

