default_yaml_parser <- function(x) {
  spec <- getOption(
    "frontmatter.parse_yaml.spec",
    default = Sys.getenv("FRONTMATTER_PARSE_YAML_SPEC", unset = "1.2")
  )

  spec <- match.arg(spec, choices = c("1.1", "1.2"))

  if (spec == "1.1") {
    rlang::check_installed("yaml", reason = "to parse YAML 1.1.")
    yaml::yaml.load(x)
  } else {
    yaml12::parse_yaml(x)
  }
}

default_toml_parser <- function(x) {
  if (!nzchar(x)) {
    return(NULL)
  }
  tomledit::from_toml(tomledit::parse_toml(x))
}
