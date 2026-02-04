#' Format and Write YAML or TOML Front Matter
#'
#' Serialize R data as YAML or TOML front matter and combine it with document
#' content. `format_front_matter()` returns the formatted document as a string,
#' while `write_front_matter()` writes it to a file or prints to the console.
#' These functions are the inverse of [parse_front_matter()] and
#' [read_front_matter()].
#'
#' @section Delimiter Formats:
#'
#' The `delimiter` argument controls the fence style used to wrap the front
#' matter. You can use these built-in shortcuts:
#'
#' | Shortcut | Format | Opening | Closing | Use Case |
#' |----------|--------|---------|---------|----------|
#' | `"yaml"` | YAML | `---` | `---` | Markdown, R Markdown, Quarto |
#' | `"toml"` | TOML | `+++` | `+++` | Hugo, some static site generators |
#' | `"yaml_comment"` | YAML | `# ---` | `# ---` | R scripts, Python scripts |
#' | `"toml_comment"` | TOML | `# +++` | `# +++` | R scripts, Python scripts |
#' | `"yaml_roxy"` | YAML | `#' ---` | `#' ---` | Roxygen2 documentation |
#' | `"toml_roxy"` | TOML | `#' +++` | `#' +++` | Roxygen2 documentation |
#' | `"toml_pep723"` | TOML | `# /// script` | `# ///` | Python PEP 723 inline metadata |
#'
#' For custom delimiters, pass a character vector of length 1, 2, or 3:
#' - **Length 1**: Used as both opener and closer, with no line prefix
#' - **Length 2**: `c(opener, prefix)` where opener is also used as closer
#' - **Length 3**: `c(opener, prefix, closer)` for full control
#'
#' @section Custom Formatters:
#'
#' By default, the package uses [yaml12::format_yaml()] for YAML and
#' [tomledit::to_toml()] for TOML. You can provide custom formatter functions
#' via `format_yaml` and `format_toml` to override these defaults.
#'
#' Custom formatters must accept an R object and return a character string
#' containing the serialized content.
#'
#' @section YAML Specification Version:
#'
#' The default YAML formatter uses YAML 1.2 via [yaml12::format_yaml()]. To use
#' YAML 1.1 formatting instead (via [yaml::as.yaml()]), set either:
#'
#' - The R option `frontmatter.serialize_yaml.spec` to `"1.1"`
#' - The environment variable `FRONTMATTER_SERIALIZE_YAML_SPEC` to `"1.1"`
#'
#' The option takes precedence over the environment variable. Valid values are
#' `"1.1"` and `"1.2"` (the default).
#'
#' @section Roundtrip Support:
#'
#' Documents formatted with these functions can be read back with
#' [parse_front_matter()] or [read_front_matter()]. For comment-prefixed
#' formats (like `yaml_comment` or `yaml_roxy`), a separator line is
#' automatically inserted between the closing fence and the body when the body
#' starts with the same comment prefix, ensuring clean roundtrip behavior.
#'
#' @examples
#' # Create a document with YAML front matter
#' doc <- list(
#'   data = list(title = "My Document", author = "Jane Doe"),
#'   body = "Document content goes here."
#' )
#'
#' # Format as a string
#' format_front_matter(doc)
#'
#' # Write to a file
#' tmp <- tempfile(fileext = ".md")
#' write_front_matter(doc, tmp)
#' readLines(tmp)
#'
#' # Print to console (when path is NULL)
#' write_front_matter(doc)
#'
#' # Use TOML format
#' format_front_matter(doc, delimiter = "toml")
#'
#' # Use comment-wrapped format for R scripts
#' r_script <- list(
#'   data = list(title = "Analysis Script"),
#'   body = "# Load libraries\nlibrary(dplyr)"
#' )
#' format_front_matter(r_script, delimiter = "yaml_comment")
#'
#' # Roundtrip example: read, modify, write
#' original <- "---
#' title: Original
#' ---
#' Content here"
#'
#' doc <- parse_front_matter(original)
#' doc$data$title <- "Modified"
#' format_front_matter(doc)
#'
#' @param x A list with `data` and `body` elements, typically as returned by
#'   [parse_front_matter()] or [read_front_matter()]. The `data` element
#'   contains the metadata to serialize (can be `NULL` to write body only),
#'   and `body` contains the document content (can be `NULL` or empty).
#'
#' @param delimiter A character string specifying the fence style, or a
#'   character vector for custom delimiters. See **Delimiter Formats** for
#'   available options.
#'
#' @param format The serialization format: `"auto"` (detect from delimiter),
#'   `"yaml"`, or `"toml"`. Usually auto-detection works well.
#'
#' @param format_yaml,format_toml Custom formatter functions, or `NULL` to use
#'   defaults. Each function should accept an R object and return a character
#'   string.
#'
#' @return
#' - `format_front_matter()`: A character string containing the formatted
#'   document with front matter.
#' - `write_front_matter()`: Called for its side effect; returns `NULL`
#'   invisibly.
#'
#' @seealso [parse_front_matter()] and [read_front_matter()] for the inverse
#'   operations.
#'
#' @describeIn format_front_matter Format front matter as a string
#' @export
format_front_matter <- function(
  x,
  delimiter = "yaml",
  format = "auto",
  format_yaml = NULL,
  format_toml = NULL
) {
  if (!is.list(x)) {
    rlang::abort(
      '`x` must be a list with "data" and "body" items, e.g. as returned by `read_front_matter()`.'
    )
  }
  check_character(x$body, allow_null = TRUE)
  check_character(delimiter, allow_na = FALSE)
  check_function(format_yaml, allow_null = TRUE)
  check_function(format_toml, allow_null = TRUE)

  format <- arg_match(format, c("auto", "yaml", "toml"))

  delimiter <- normalize_delimiter(delimiter)
  format <- normalize_format(format, delimiter)

  format_yaml <- format_yaml %||% default_yaml_formatter
  format_toml <- format_toml %||% default_toml_formatter

  opener <- delimiter[1]
  prefix <- delimiter[2]
  body <- x$body
  closer <- delimiter[3]
  space_line <- NULL
  data <- c()

  if (!is.null(x$data)) {
    data <- switch(
      format,
      yaml = format_yaml(x$data),
      toml = format_toml(x$data)
    )

    if (!is_character(data) || length(data) == 0) {
      arg <- switch(format, yaml = "format_yaml", toml = "format_toml")
      abort(
        sprintf("`%s()` must return a character vector.", arg)
      )
    }

    if (nzchar(data)) {
      space_line <- ""

      if (!is.null(body) && !identical(prefix, "")) {
        if (substring(body, 1, nchar(prefix)) == prefix) {
          space_line <- trimws(prefix, "right")
        }
      }
    }

    if (length(data) == 1) {
      data <- strsplit(data, "\n")[[1]]
    }
  }

  lines <- if (is.null(data)) {
    body
  } else {
    c(
      opener,
      if (nzchar(prefix)) paste0(prefix, data) else data,
      closer,
      space_line,
      body
    )
  }

  lines <- paste(lines, collapse = "\n")

  # Ensure trailing newline (matching writeLines() convention)
  # Only add a newline if the content doesn't already end with one
  if (nzchar(lines) && substring(lines, nchar(lines)) != "\n") {
    lines <- paste0(lines, "\n")
  }

  lines
}

#' @describeIn format_front_matter Write front matter to a file or console
#'
#' @param path File path to write to, or `NULL` to print to the console
#'
#' @param ... Additional arguments passed to [writeBin()] when writing to a
#'   file (e.g., `useBytes`).
#'
#' @export
write_front_matter <- function(
  x,
  path = NULL,
  delimiter = "yaml",
  ...,
  format = "auto",
  format_yaml = NULL,
  format_toml = NULL
) {
  content <- format_front_matter(
    x = x,
    delimiter = delimiter,
    format = format,
    format_yaml = format_yaml,
    format_toml = format_toml
  )

  if (is.null(path)) {
    cat(content)
  } else {
    writeBin(charToRaw(enc2utf8(content)), con = path, ...)
  }
}

normalize_delimiter <- function(delimiter) {
  if (length(delimiter) == 1) {
    delimiter <- switch(
      delimiter,
      yaml = "---",
      toml = "+++",
      yaml_comment = c("# ---", "# "),
      toml_comment = c("# +++", "# "),
      yaml_roxy = c("#' ---", "#' "),
      toml_roxy = c("#' +++", "#' "),
      toml_pep723 = c("# /// script", "# ", "# ///"),
      delimiter
    )
  }

  if (length(delimiter) == 1) {
    delimiter <- c(delimiter, "", delimiter)
  } else if (length(delimiter) == 2) {
    delimiter <- c(delimiter, delimiter[1])
  } else if (length(delimiter) != 3) {
    abort(
      "`delimiter` must be of length 1, 2, or 3 with items for start, prefix, and end."
    )
  }

  delimiter
}

normalize_format <- function(format, delimiter) {
  arg_match(format, c("auto", "yaml", "toml"), error_call = parent.frame())

  if (format != "auto") {
    return(format)
  } else if (is_yaml_delimiter(delimiter)) {
    return("yaml")
  } else if (is_toml_delimiter(delimiter)) {
    return("toml")
  }

  abort(
    "Could not auto-detect format from `delimiter`. Please specify `format` explicitly.",
    call = parent.frame()
  )
}

is_yaml_delimiter <- function(delimiter) {
  grepl("---$", delimiter[1])
}

is_toml_delimiter <- function(delimiter) {
  grepl("\\+\\+\\+$", delimiter[1]) || grepl("/// script$", delimiter[1])
}
