default_yaml_parser <- function(x) {
  spec <- getOption(
    "frontmatter.parse_yaml.spec",
    default = Sys.getenv("FRONTMATTER_PARSE_YAML_SPEC", unset = "1.2")
  )

  spec <- arg_match(spec, c("1.1", "1.2"), error_call = parent.frame())

  if (spec == "1.1") {
    rlang::check_installed("yaml", reason = "to parse YAML 1.1.")
    yaml::yaml.load(x)
  } else {
    yaml12::parse_yaml(x)
  }
}

default_yaml_formatter <- function(x) {
  spec <- getOption(
    "frontmatter.serialize_yaml.spec",
    default = Sys.getenv("FRONTMATTER_SERIALIZE_YAML_SPEC", unset = "1.2")
  )

  spec <- arg_match(spec, c("1.1", "1.2"), error_call = parent.frame())

  if (spec == "1.1") {
    rlang::check_installed("yaml", reason = "to serialize YAML 1.1.")
    yaml::as.yaml(x, indent.mapping.sequence = TRUE)
  } else {
    yaml12::format_yaml(x)
  }
}

default_toml_parser <- function(x) {
  if (!nzchar(x)) {
    return(NULL)
  }
  tomledit::from_toml(tomledit::parse_toml(x))
}

default_toml_formatter <- function(x) {
  tomledit::to_toml(tomledit::as_toml(x))
}
