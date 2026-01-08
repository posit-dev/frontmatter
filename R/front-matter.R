#' Parse Front Matter from Text
#'
#' Extract and parse YAML or TOML front matter from a text string. Front matter
#' is structured metadata at the beginning of a document, delimited by fences
#' (`---` for YAML, `+++` for TOML).
#'
#' @param text A character string containing the document text.
#' @param parsers An optional list of parser functions created by
#'   [front_matter_parsers()]. If `NULL`, default parsers are used.
#'
#' @return A named list with two elements:
#'   - `data`: The parsed front matter as an R object, or `NULL` if no valid
#'     front matter was found.
#'   - `body`: The document content after the front matter, with leading empty
#'     lines removed. If no front matter is found, this is the original text.
#'
#' @examples
#' # Parse YAML front matter
#' text <- "---
#' title: My Document
#' date: 2024-01-01
#' ---
#' Document content here"
#'
#' result <- front_matter_text(text)
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
#' result <- front_matter_text(text)
#'
#' # Get raw YAML without parsing
#' result <- front_matter_text(
#'   text,
#'   parsers = front_matter_parsers(yaml = identity)
#' )
#'
#' @export
front_matter_text <- function(text, parsers = NULL) {
  check_character(text)
  if (length(text) > 1) {
    text <- paste0(text, collapse = "\n")
  }

  parsers <- parsers %||% front_matter_parsers()

  if (!is.list(parsers) || !all(c("yaml", "toml") %in% names(parsers))) {
    rlang::abort(
      "{.arg parsers} must be a list with elements {.val yaml} and {.val toml}."
    )
  }
  check_function(parsers$yaml, arg = "parsers$yaml")
  check_function(parsers$toml, arg = "parsers$toml")

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

#' Parse Front Matter from File
#'
#' Read a file and extract and parse YAML or TOML front matter. This is a
#' convenience wrapper around [front_matter_text()] that handles file reading.
#'
#' @param path A character string specifying the path to a file.
#' @param parsers An optional list of parser functions created by
#'   [front_matter_parsers()]. If `NULL`, default parsers are used.
#'
#' @return A named list with two elements:
#'   - `data`: The parsed front matter as an R object, or `NULL` if no valid
#'     front matter was found.
#'   - `body`: The document content after the front matter.
#'
#' @examples
#' \dontrun{
#' # Parse front matter from a markdown file
#' result <- front_matter_read("document.md")
#' result$data$title
#' result$body
#' }
#'
#' @export
front_matter_read <- function(path, parsers = NULL) {
  check_string(path)

  if (!file.exists(path)) {
    rlang::abort("File does not exist: {.file {path}}")
  }

  file_size <- file.info(path, extra_cols = FALSE)$size
  if (file_size == 0) {
    return(list(data = NULL, body = ""))
  }

  raw_bytes <- readBin(path, "raw", n = file_size)
  text <- rawToChar(raw_bytes)
  Encoding(text) <- "UTF-8"

  front_matter_text(text, parsers = parsers)
}
