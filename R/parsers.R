#' Custom Front Matter Parsers
#'
#' Create a custom parser configuration for front matter parsing. By default,
#' the package uses `yaml12::parse_yaml()` for YAML and `toml::parse_toml()` for
#' TOML. You can provide custom parser functions to override these defaults.
#'
#' @param yaml A function that takes a string and returns a parsed R object, or
#'   `NULL` to use the default YAML parser. Use `identity` to return the raw
#'   YAML string without parsing.
#' @param toml A function that takes a string and returns a parsed R object, or
#'   `NULL` to use the default TOML parser. Use `identity` to return the raw
#'   TOML string without parsing.
#'
#' @return A named list with elements `yaml` and `toml` containing parser
#'   functions.
#'
#' @examples
#' # Use default parsers
#' parsers <- front_matter_parsers()
#'
#' # Get raw YAML without parsing
#' parsers <- front_matter_parsers(yaml = identity)
#'
#' # Use a custom YAML parser
#' parsers <- front_matter_parsers(
#'   yaml = function(x) yaml::yaml.load(x)
#' )
#'
#' @export
front_matter_parsers <- function(yaml = NULL, toml = NULL) {
  check_function(yaml, allow_null = TRUE)
  check_function(toml, allow_null = TRUE)

  list(
    yaml = yaml %||% yaml12::parse_yaml,
    toml = toml %||% toml::parse_toml
  )
}
