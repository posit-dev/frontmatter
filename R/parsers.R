#' Custom Front Matter Parsers
#'
#' Create a custom parser configuration for front matter parsing. By default,
#' the package uses `yaml12::parse_yaml()` for YAML and `toml::parse_toml()` for
#' TOML. You can provide custom parser functions to override these defaults.
#'
#' @param yaml,toml A function that takes a string and returns a parsed R
#'   object, or `NULL` to use the default YAML or TOML parser. Use `identity` to
#'   return the raw YAML or TOML string without parsing.
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
#' # Or another YAML parser
#' # parsers <- front_matter_parsers(yaml = yaml::yaml.load)
#'
#' # Use a custom parser that adds metadata
#' parsers <- front_matter_parsers(
#'   yaml = function(x) {
#'     data <- yaml12::parse_yaml(x)
#'     data$parsed_at <- Sys.time()
#'     data
#'   }
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
