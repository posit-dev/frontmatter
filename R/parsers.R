default_yaml_parser <- function(x) {
  yaml12::parse_yaml(x)
}

default_toml_parser <- function(x) {
  if (!nzchar(x)) {
    return(NULL)
  }
  tomledit::from_toml(tomledit::parse_toml(x))
}
