#' Parse YAML or TOML Front Matter
#'
#' Extract and parse YAML or TOML front matter from a file or a text string.
#' Front matter is structured metadata at the beginning of a document, delimited
#' by fences (`---` for YAML, `+++` for TOML). `parse_front_matter()` processes
#' a character string, while `read_front_matter()` reads from a file. Both
#' functions return a list with the parsed front matter and the document body.
#'
#' @examples
#' # Parse YAML front matter
#' text <- "---
#' title: My Document
#' date: 2024-01-01
#' ---
#' Document content here"
#'
#' result <- parse_front_matter(text)
#' result$data$title  # "My Document"
#' result$body        # "Document content here"
#'
#' # Parse TOML front matter
#' text <- "+++
#' title = 'My Document'
#' date = 2024-01-01
#' +++
#' Document content"
#'
#' result <- parse_front_matter(text)
#'
#' # Get raw YAML without parsing
#' result <- parse_front_matter(
#'   text,
#'   parsers = front_matter_parsers(yaml = identity)
#' )
#'
#' # Or read from a file
#' tmpfile <- tempfile(fileext = ".md")
#' writeLines(text, tmpfile)
#'
#' result <- read_front_matter(tmpfile)
#'
#' @param text A character string or vector containing the document text. If a
#'   vector with multiple elements, they are joined with newlines (as from
#'   `readLines()`).
#' @param parsers An optional list of parser functions created by
#'   [front_matter_parsers()]. If `NULL`, default parsers are used.
#'
#' @return A named list with two elements:
#'   - `data`: The parsed front matter as an R object, or `NULL` if no valid
#'     front matter was found.
#'   - `body`: The document content after the front matter, with leading empty
#'     lines removed. If no front matter is found, this is the original text.
#'
#' @describeIn parse_front_matter Parse front matter from text
#' @export
parse_front_matter <- function(text, parsers = front_matter_parsers()) {
  check_character(text)
  if (length(text) > 1) {
    text <- paste0(text, collapse = "\n")
  }

  if (!is.list(parsers)) {
    rlang::abort(
      "{.arg parsers} must be a list with elements {.val yaml} and {.val toml}.",
      use_cli_format = TRUE
    )
  }

  parsers <- front_matter_parsers(yaml = parsers$yaml, toml = parsers$toml)

  result <- extract_front_matter_cpp(text)

  if (!result$found) {
    return(list(
      data = NULL,
      body = result$body
    ))
  }

  parsed_data <- switch(
    result$fence_type,
    yaml = parsers$yaml(result$content),
    toml = parsers$toml(result$content),
    NULL
  )

  list(
    data = parsed_data,
    body = result$body
  )
}

#' @describeIn parse_front_matter Parse front matter from a file.
#'
#' @param path A character string specifying the path to a file. The file is
#'   assumed to be UTF-8 encoded. A UTF-8 BOM (byte order mark) at the start
#'   of the file is automatically stripped if present.
#'
#' @export
read_front_matter <- function(path, parsers = front_matter_parsers()) {
  check_string(path)

  if (!file.exists(path)) {
    rlang::abort("File does not exist: {.file {path}}")
  }

  file_size <- file.info(path, extra_cols = FALSE)$size
  if (file_size == 0) {
    return(list(data = NULL, body = ""))
  }

  raw_bytes <- readBin(path, "raw", n = file_size)

  # Strip UTF-8 BOM (EF BB BF) if present
  if (
    length(raw_bytes) >= 3 &&
      raw_bytes[1] == as.raw(0xEF) &&
      raw_bytes[2] == as.raw(0xBB) &&
      raw_bytes[3] == as.raw(0xBF)
  ) {
    raw_bytes <- raw_bytes[-c(1:3)]
  }

  text <- rawToChar(raw_bytes)
  Encoding(text) <- "UTF-8"

  parse_front_matter(text, parsers = parsers)
}
