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
#' | `"yaml_sql_line"` | YAML | `-- ---` | `-- ---` | SQL scripts (line comments) |
#' | `"toml_sql_line"` | TOML | `-- +++` | `-- +++` | SQL scripts (line comments) |
#' | `"yaml_sql_block_compact"` | YAML | `/* ---` | `--- */` | SQL scripts (block comments) |
#' | `"toml_sql_block_compact"` | TOML | `/* +++` | `+++ */` | SQL scripts (block comments) |
#' | `"yaml_sql_block_expanded"` | YAML | `/*` + `---` | `---` + `*/` | SQL scripts (block comments) |
#' | `"toml_sql_block_expanded"` | TOML | `/*` + `+++` | `+++` + `*/` | SQL scripts (block comments) |
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
#' formats (like `yaml_comment`, `yaml_roxy`, or `yaml_sql_line`), a separator
#' line is automatically inserted between the closing fence and the body when
#' the body starts with the same comment prefix, ensuring clean roundtrip
#' behavior.
#'
#' When `delimiter` is `NULL` (the default), the delimiter is inferred
#' automatically, making roundtrips seamless:
#'
#' - `format_front_matter()` uses the `fence_type` attribute preserved by
#'   [parse_front_matter()] and [read_front_matter()], so the output uses the
#'   same fence style as the original document.
#' - `write_front_matter()` additionally falls back to a built-in
#'   extension-to-delimiter map when the input has no `fence_type` attribute:
#'
#' | Extension | Default delimiter |
#' |-----------|------------------|
#' | `.sql` | `"yaml_sql_block_compact"` |
#' | `.py` | `"toml_pep723"` |
#' | `.R` | `"yaml_comment"` |
#' | `.md`, `.qmd`, `.Rmd` | `"yaml"` |
#'
#' @examples
#' # Create a document with YAML front matter
#' doc <- list(
#'   data = list(title = "My Document", author = "Jane Doe"),
#'   body = "Document content goes here."
#' )
#'
#' # Format as a string (delimiter inferred from fence_type attr, falls back to yaml)
#' format_front_matter(doc)
#'
#' # Write to a file (delimiter inferred from .md extension -> yaml)
#' tmp <- tempfile(fileext = ".md")
#' write_front_matter(doc, tmp)
#' readLines(tmp)
#'
#' # Print to console (when path is NULL)
#' write_front_matter(doc)
#'
#' # Use TOML format explicitly
#' format_front_matter(doc, delimiter = "toml")
#'
#' # Use comment-wrapped format for R scripts explicitly
#' r_script <- list(
#'   data = list(title = "Analysis Script"),
#'   body = "# Load libraries\nlibrary(dplyr)"
#' )
#' format_front_matter(r_script, delimiter = "yaml_comment")
#'
#' # Write to an R file: delimiter inferred from .R extension -> yaml_comment
#' tmp_r <- tempfile(fileext = ".R")
#' write_front_matter(r_script, tmp_r)
#' readLines(tmp_r)
#'
#' # Roundtrip: delimiter is automatically preserved from the original format
#' original <- "# ---
#' # title: Original
#' # ---
#' # R code here"
#'
#' doc <- parse_front_matter(original)
#' doc$data$title <- "Modified"
#' format_front_matter(doc) # uses yaml_comment, matching the source
#'
#' @param x A list with `data` and `body` elements, typically as returned by
#'   [parse_front_matter()] or [read_front_matter()]. The `data` element
#'   contains the metadata to serialize (can be `NULL` to write body only),
#'   and `body` contains the document content (can be `NULL` or empty).
#'
#' @param delimiter A character string specifying the fence style, or a
#'   character vector for custom delimiters. See **Delimiter Formats** for
#'   available options. When `NULL` (the default), the delimiter is inferred:
#'   first from the `fence_type` attribute of `x` (set by [parse_front_matter()]
#'   and [read_front_matter()]), then from the file extension of `path` (for
#'   `write_front_matter()` only), and finally falling back to `"yaml"`.
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
  delimiter = NULL,
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
  delimiter <- infer_delimiter(delimiter, x)
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
  shebang <- NULL
  data <- c()

  # Pre-detect shebang for comment-prefixed delimiters so that space_line is
  # computed against the post-shebang body (applied only when data is non-null)
  body_main <- body
  potential_shebang <- NULL
  is_script_prefix <- prefix %in% c("# ", "#' ", "-- ")
  if (
    is_script_prefix && !is.null(body) && nzchar(body) && startsWith(body, "#!")
  ) {
    nl_pos <- regexpr("\n", body, fixed = TRUE)
    if (nl_pos > 0) {
      potential_shebang <- sub("\r$", "", substring(body, 1, nl_pos - 1))
      body_main <- substring(body, nl_pos + 1)
    } else {
      potential_shebang <- body
      body_main <- NULL
    }
  }

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

      body_for_spaceline <- if (!is.null(potential_shebang)) body_main else body
      if (!is.null(body_for_spaceline) && !identical(prefix, "")) {
        trimmed <- trimws(prefix, "right")
        starts_with_prefix <- substring(body_for_spaceline, 1, nchar(prefix)) ==
          prefix
        starts_with_bare <- grepl(
          paste0(
            "^",
            gsub("([.|()\\^{}+$*?]|\\[|\\])", "\\\\\\1", trimmed),
            "[ \t]*(\r?\n|$)"
          ),
          body_for_spaceline
        )
        if (starts_with_prefix || starts_with_bare) {
          space_line <- trimmed
        }
      }
    }

    if (length(data) == 1) {
      data <- strsplit(data, "\n")[[1]]
    }
  }

  # Apply shebang: move to top when writing front matter
  if (!is.null(data) && !is.null(potential_shebang)) {
    shebang <- potential_shebang
    body <- body_main
  }

  lines <- if (is.null(data)) {
    body
  } else {
    c(
      shebang,
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
  delimiter = NULL,
  ...,
  format = "auto",
  format_yaml = NULL,
  format_toml = NULL
) {
  ext <- if (!is.null(path)) tools::file_ext(path) else NULL
  content <- format_front_matter(
    x = x,
    delimiter = infer_delimiter(delimiter, x, ext),
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
      yaml_sql_line = c("-- ---", "-- "),
      toml_sql_line = c("-- +++", "-- "),
      yaml_sql_block_compact = c("/* ---", "", "--- */"),
      toml_sql_block_compact = c("/* +++", "", "+++ */"),
      yaml_sql_block_expanded = c("/*\n---", "", "---\n*/"),
      toml_sql_block_expanded = c("/*\n+++", "", "+++\n*/"),
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

infer_delimiter <- function(delimiter, x, ext = NULL) {
  if (!is.null(delimiter)) {
    return(delimiter)
  }

  fence_type <- attr(x, "fence_type", exact = TRUE)
  if (!is.null(fence_type) && nzchar(fence_type) && fence_type != "none") {
    return(fence_type)
  }

  if (!is.null(ext) && nzchar(ext)) {
    mapped <- switch(
      tolower(ext),
      sql = "yaml_sql_block_compact",
      py = "toml_pep723",
      r = "yaml_comment",
      rmd = "yaml",
      qmd = "yaml",
      md = "yaml",
      NULL
    )
    if (!is.null(mapped)) return(mapped)
  }

  "yaml"
}
