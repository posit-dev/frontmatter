test_that("parse_front_matter parses YAML correctly", {
  text <- "---\ntitle: Test\ndate: 2024-01-01\n---\nBody content"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(result$data$date, "2024-01-01")
  expect_equal(result$body, "Body content")
})

test_that("parse_front_matter parses TOML correctly", {
  text <- "+++\ntitle = \"Test\"\ncount = 42\n+++\nBody content"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(result$data$count, 42)
  expect_equal(result$body, "Body content")
})

test_that("parse_front_matter returns NULL for no front matter", {
  text <- "Just content\nNo front matter"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("parse_front_matter handles empty documents", {
  result <- parse_front_matter("")

  expect_null(result$data)
  expect_equal(result$body, "")
})

test_that("parse_front_matter handles documents with only front matter", {
  text <- "---\ntitle: Test\n---"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "")

  text <- "---\ntitle: Test\n---\n  \n  \n"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "")
})

test_that("parse_front_matter validates input", {
  expect_error(parse_front_matter(123), "must be a character vector")
})

test_that("parse_front_matter accepts multi-element vectors", {
  # Multi-element vectors are joined with newlines (as from readLines())
  lines <- c("---", "title: Test", "---", "Body content")
  result <- parse_front_matter(lines)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "Body content")
})

test_that("parse_front_matter validates parser arguments", {
  text <- "---\ntitle: Test\n---\nBody"

  expect_error(
    parse_front_matter(text, parse_yaml = "not a function"),
    "`parse_yaml` must be a function"
  )

  expect_error(
    parse_front_matter(text, parse_toml = "not a function"),
    "`parse_toml` must be a function"
  )
})

test_that("parse_front_matter handles multiline YAML", {
  text <- "---
title: Test
description: |
  Multi-line
  description
tags:
  - tag1
  - tag2
---
Content"

  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_true(grepl("Multi-line", result$data$description))
  expect_equal(length(result$data$tags), 2)
  expect_equal(result$body, "Content")
})

test_that("read_front_matter reads files correctly", {
  # Create a temporary file
  tmp <- tempfile(fileext = ".md")
  on.exit(unlink(tmp))

  # Binary write to ensure consistent LF line endings across platforms
  con <- file(tmp, "wb")
  writeChar("---\ntitle: Test\n---\nBody\n", con, eos = NULL)
  close(con)

  result <- read_front_matter(tmp)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "Body\n")
})

test_that("read_front_matter validates input", {
  expect_error(read_front_matter(123), "must be a single string")
  expect_error(read_front_matter("nonexistent.md"), "File does not exist")
})

test_that("read_front_matter handles files with CRLF line endings", {
  tmp <- tempfile(fileext = ".md")
  on.exit(unlink(tmp))

  # Write file with CRLF endings
  con <- file(tmp, "wb")
  writeChar("---\r\ntitle: Test\r\n---\r\nBody\r\n", con, eos = NULL)
  close(con)

  result <- read_front_matter(tmp)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "Body\r\n")
})

test_that("read_front_matter handles files without trailing newline", {
  tmp <- tempfile(fileext = ".md")
  on.exit(unlink(tmp))

  con <- file(tmp, "wb")
  writeChar("---\ntitle: Test\n---\nBody", con, eos = NULL)
  close(con)

  result <- read_front_matter(tmp)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "Body")
})

# Comment-prefixed formats preserve body unchanged --------------------------

test_that("parse_front_matter preserves body with # prefix (yaml_r format)", {
  text <- "# ---
# key: value
# ---
#
# start of script
print('hello')"

  result <- parse_front_matter(text)

  expect_equal(result$data$key, "value")
  # Body should be returned unchanged, with # prefix preserved

  expect_equal(result$body, "# start of script\nprint('hello')")
})

test_that("parse_front_matter preserves body with # prefix (toml_r format)", {
  text <- "# +++
# key = \"value\"
# +++
#
# start of script
print('hello')"

  result <- parse_front_matter(text)

  expect_equal(result$data$key, "value")
  expect_equal(result$body, "# start of script\nprint('hello')")
})

test_that("parse_front_matter preserves body with #' prefix (yaml_roxy format)", {
  text <- "#' ---
#' key: value
#' ---
#'
#' @description A function
my_function <- function() {}"

  result <- parse_front_matter(text)

  expect_equal(result$data$key, "value")
  expect_equal(
    result$body,
    "#' @description A function\nmy_function <- function() {}"
  )
})

test_that("parse_front_matter preserves body with #' prefix (toml_roxy format)", {
  text <- "#' +++
#' key = \"value\"
#' +++
#'
#' @description A function
my_function <- function() {}"

  result <- parse_front_matter(text)

  expect_equal(result$data$key, "value")
  expect_equal(
    result$body,
    "#' @description A function\nmy_function <- function() {}"
  )
})

test_that("parse_front_matter preserves body in PEP 723 format", {
  text <- "# /// script
# dependencies = [\"requests\"]
# ///
#
# A Python script
import requests"

  result <- parse_front_matter(text)

  # TOML arrays are parsed as nested lists by tomledit
  expect_equal(result$data$dependencies[[1]], "requests")
  expect_equal(result$body, "# A Python script\nimport requests")
})

test_that("parse_front_matter handles comment format without separator line", {
  # No blank # line between closing fence and body
  text <- "# ---
# key: value
# ---
# start of script"

  result <- parse_front_matter(text)

  expect_equal(result$data$key, "value")
  expect_equal(result$body, "# start of script")
})

test_that("parse_front_matter handles comment format with empty body", {
  text <- "# ---
# key: value
# ---"

  result <- parse_front_matter(text)

  expect_equal(result$data$key, "value")
  expect_equal(result$body, "")
})
