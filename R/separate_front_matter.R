# Pure R implementation of front matter extraction (optimized for speed)
# This exists as a counter-factual of the C++ implementation, for comparison.
# It ends up being about 5-6x slower than the C++ version (but still pretty
# darn fast).

separate_front_matter <- function(text) {
  if (length(text) != 1L || !is.character(text)) {
    stop("`text` must be a single character string")
  }

  n <- nchar(text)
  if (n == 0L) {
    return(list(found = FALSE, fence_type = "none", content = "", body = ""))
  }

  no_match <- list(
    found = FALSE,
    fence_type = "none",
    content = "",
    body = text
  )

  # Helper to trim body: remove leading empty lines and trailing whitespace-only
  trim_body <- function(body) {
    # Remove leading empty lines
    body <- sub("^([ \t]*(\r\n|\r|\n))+", "", body, perl = TRUE)
    # If body is only whitespace, return empty
    if (grepl("^[ \t\r\n]*$", body, perl = TRUE)) {
      return("")
    }
    body
  }

  # PEP 723: # /// script
  if (substr(text, 1L, 12L) == "# /// script") {
    # Find first newline (CR or LF)
    first_nl <- regexpr("[\r\n]", text)
    if (first_nl > 12L) {
      # Check chars between "script" and newline are only whitespace
      between <- if (first_nl > 13L) substr(text, 13L, first_nl - 1L) else ""
      if (nchar(between) == 0L || grepl("^[ \t]+$", between)) {
        # Calculate opening_end (include the newline)
        opening_end <- first_nl
        if (
          substr(text, first_nl, first_nl) == "\r" &&
            first_nl < n &&
            substr(text, first_nl + 1L, first_nl + 1L) == "\n"
        ) {
          opening_end <- first_nl + 1L
        }

        # Find closing # /// - need newline before it
        closing_match <- regexpr("[\r\n]# ///[ \t]*([\r\n]|$)", text)

        if (closing_match > 0L && closing_match >= opening_end) {
          # closing_match points to the newline before # ///
          # Actual closing fence starts after that newline
          newline_len <- if (
            substr(text, closing_match, closing_match) == "\r" &&
              closing_match + 1L <= n &&
              substr(text, closing_match + 1L, closing_match + 1L) == "\n"
          ) {
            2L
          } else {
            1L
          }
          closing_start <- closing_match + newline_len

          content_start <- opening_end + 1L
          # Include the newline in content (as per spec)
          content_end <- closing_match + newline_len - 1L

          # Handle empty content case
          if (content_end < content_start) {
            # Empty content is valid
            content <- ""
            # Body starts after closing line
            closing_line_match <- regexpr(
              "^# ///[ \t]*([\r\n]|$)",
              substr(text, closing_start, n)
            )
            body_start <- closing_start +
              attr(closing_line_match, "match.length")
            body <- if (body_start <= n) substr(text, body_start, n) else ""
            body <- trim_body(body)

            return(list(
              found = TRUE,
              fence_type = "toml",
              content = content,
              body = body
            ))
          }

          content_raw <- substr(text, content_start, content_end)
          # Each line must start with # and if more content, next char must be space
          # Use simple patterns without lookbehind for CRLF compatibility
          lines <- strsplit(content_raw, "\r?\n|\r")[[1]]
          lines_valid <- all(grepl("^#( |$)", lines) | lines == "")

          if (lines_valid) {
            # Unwrap: remove "# " or standalone "#" from line starts
            content <- gsub("(^|\r?\n|\r)# ?", "\\1", content_raw)

            # Body starts after closing line
            closing_line_len <- attr(closing_match, "match.length")
            body_start <- closing_match + closing_line_len
            body <- if (body_start <= n) substr(text, body_start, n) else ""
            body <- trim_body(body)

            return(list(
              found = TRUE,
              fence_type = "toml",
              content = content,
              body = body
            ))
          }
        }
      }
    }
    return(no_match)
  }

  # Comment-wrapped: # --- / #' --- / # +++ / #' +++
  comment_match <- regexpr(
    "^(#' |# )(---|\\+\\+\\+)[ \t]*(\r\n|\r|\n)",
    text,
    perl = TRUE
  )
  if (comment_match > 0L) {
    cap_starts <- attr(comment_match, "capture.start")
    cap_lengths <- attr(comment_match, "capture.length")
    prefix <- substr(text, cap_starts[1], cap_starts[1] + cap_lengths[1] - 1L)
    fence <- substr(text, cap_starts[2], cap_starts[2] + cap_lengths[2] - 1L)
    fence_type <- if (fence == "---") "yaml" else "toml"
    opening_end <- attr(comment_match, "match.length")

    # Build closing pattern - same prefix + fence (both escaped)
    prefix_esc <- gsub(
      "([.|()\\^{}+$*?\\[\\]\\\\])",
      "\\\\\\1",
      prefix,
      perl = TRUE
    )
    fence_esc <- gsub(
      "([.|()\\^{}+$*?\\[\\]\\\\])",
      "\\\\\\1",
      fence,
      perl = TRUE
    )
    # Use capturing group for newline instead of lookbehind
    closing_pattern <- paste0(
      "(\r\n|\n|\r)",
      prefix_esc,
      fence_esc,
      "[ \t]*(\r\n|\r|\n|$)"
    )
    closing_match <- regexpr(closing_pattern, text, perl = TRUE)

    if (closing_match > 0L && closing_match >= opening_end) {
      # closing_match points to newline before closing fence
      # Calculate newline length (1 for LF/CR, 2 for CRLF)
      newline_len <- if (
        substr(text, closing_match, closing_match) == "\r" &&
          closing_match + 1L <= n &&
          substr(text, closing_match + 1L, closing_match + 1L) == "\n"
      ) {
        2L
      } else {
        1L
      }

      content_start <- opening_end + 1L
      # Include the newline in content (as per spec)
      content_end <- closing_match + newline_len - 1L
      content_raw <- if (content_end >= content_start) {
        substr(text, content_start, content_end)
      } else {
        ""
      }

      # Unwrap comments
      bare_prefix <- sub(" $", "", prefix)
      bare_esc <- gsub(
        "([.|()\\^{}+$*?\\[\\]\\\\])",
        "\\\\\\1",
        bare_prefix,
        perl = TRUE
      )

      # Remove full prefix from lines, or bare prefix on empty comment lines
      content <- gsub(
        paste0("(^|(?<=\r\n|\r|\n))", prefix_esc),
        "\\1",
        content_raw,
        perl = TRUE
      )
      # Remove remaining bare comment markers on otherwise empty lines
      content <- gsub(
        paste0("(^|(?<=\r\n|\r|\n))", bare_esc, "[ \t]*(?=\r\n|\r|\n|$)"),
        "\\1",
        content,
        perl = TRUE
      )

      # Body
      body_start <- closing_match + attr(closing_match, "match.length")
      body <- if (body_start <= n) substr(text, body_start, n) else ""

      # Trim leading empty/bare-comment lines, then unwrap if no blank line gap
      # Check for blank line (determines whether to unwrap body)
      leading_empty <- regexpr(
        paste0("^([ \t]*(\r\n|\r|\n)|", prefix_esc, "?[ \t]*(\r\n|\r|\n))*"),
        body,
        perl = TRUE
      )
      if (leading_empty > 0L && attr(leading_empty, "match.length") > 0L) {
        leading_content <- substr(body, 1L, attr(leading_empty, "match.length"))
        has_blank <- grepl(
          "(^|(?<=\r\n|\r|\n))[ \t]*(\r\n|\r|\n)",
          leading_content,
          perl = TRUE
        )
        body <- substr(
          body,
          attr(leading_empty, "match.length") + 1L,
          nchar(body)
        )

        if (!has_blank && nchar(body) > 0L) {
          # Continuous with front matter - unwrap
          body <- gsub(
            paste0("(^|(?<=\r\n|\r|\n))", prefix_esc),
            "\\1",
            body,
            perl = TRUE
          )
        }
      }

      # Final trim for whitespace-only body
      if (grepl("^[ \t\r\n]*$", body, perl = TRUE)) {
        body <- ""
      }

      return(list(
        found = TRUE,
        fence_type = fence_type,
        content = content,
        body = body
      ))
    }
    return(no_match)
  }

  # Standard: --- or +++
  standard_match <- regexpr(
    "^(---|\\+\\+\\+)[ \t]*(\r\n|\r|\n)",
    text,
    perl = TRUE
  )
  if (standard_match > 0L) {
    fence <- substr(text, 1L, 3L)
    fence_type <- if (fence == "---") "yaml" else "toml"
    fence_char <- substr(fence, 1L, 1L)
    opening_end <- attr(standard_match, "match.length")

    # Find closing: exactly 3 chars, at line start, not 4+
    # Use capturing group for newline instead of lookbehind
    fence_esc <- gsub("([+])", "\\\\\\1", fence, perl = TRUE)
    char_esc <- gsub("([+])", "\\\\\\1", fence_char, perl = TRUE)
    closing_pattern <- paste0(
      "(\r\n|\n|\r)",
      fence_esc,
      "(?!",
      char_esc,
      ")[ \t]*(\r\n|\r|\n|$)"
    )
    # Search full text to allow lookbehind equivalent via capture group
    closing_match <- regexpr(closing_pattern, text, perl = TRUE)

    if (closing_match > 0L && closing_match >= opening_end) {
      # closing_match points to the newline before the fence
      # Calculate newline length (1 for LF/CR, 2 for CRLF)
      newline_len <- if (
        substr(text, closing_match, closing_match) == "\r" &&
          closing_match + 1L <= n &&
          substr(text, closing_match + 1L, closing_match + 1L) == "\n"
      ) {
        2L
      } else {
        1L
      }

      content_start <- opening_end + 1L
      # Include the newline in content (as per spec)
      content_end <- closing_match + newline_len - 1L
      content <- if (content_end >= content_start) {
        substr(text, content_start, content_end)
      } else {
        ""
      }

      # Body
      closing_len <- attr(closing_match, "match.length")
      body_start <- closing_match + closing_len
      body <- if (body_start <= n) substr(text, body_start, n) else ""
      body <- trim_body(body)

      return(list(
        found = TRUE,
        fence_type = fence_type,
        content = content,
        body = body
      ))
    }
    return(no_match)
  }

  no_match
}
