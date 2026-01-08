test_that("parse_front_matter parses YAML correctly", {
  skip_if_not_installed("yaml12")

  text <- "---\ntitle: Test\ndate: 2024-01-01\n---\nBody content"
  result <- parse_front_matter(text)

  expect_true(!is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(result$data$date, "2024-01-01")
  expect_equal(result$body, "Body content")
})

test_that("parse_front_matter parses TOML correctly", {
  skip_if_not_installed("toml")

  text <- "+++\ntitle = \"Test\"\ncount = 42\n+++\nBody content"
  result <- parse_front_matter(text)

  expect_true(!is.null(result$data))
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
  skip_if_not_installed("yaml12")

  text <- "---\ntitle: Test\n---"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "")
})

test_that("parse_front_matter validates input", {
  expect_error(parse_front_matter(123), "must be a character vector")
})

test_that("parse_front_matter accepts multi-element vectors", {
  skip_if_not_installed("yaml12")

  # Multi-element vectors are joined with newlines (as from readLines())
  lines <- c("---", "title: Test", "---", "Body content")
  result <- parse_front_matter(lines)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "Body content")
})

test_that("parse_front_matter validates parsers argument", {
  text <- "---\ntitle: Test\n---\nBody"

  expect_error(
    parse_front_matter(text, parsers = "invalid"),
    "must be a list with elements"
  )

  expect_error(
    parse_front_matter(text, parsers = list(yaml = "not a function")),
    "`yaml` must be a function"
  )

  expect_error(
    parse_front_matter(
      text,
      parsers = list(yaml = identity, toml = "not a function")
    ),
    "must be a function"
  )
})

test_that("parse_front_matter handles multiline YAML", {
  skip_if_not_installed("yaml12")

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
  skip_if_not_installed("yaml12")

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
  skip_if_not_installed("yaml12")

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
  skip_if_not_installed("yaml12")

  tmp <- tempfile(fileext = ".md")
  on.exit(unlink(tmp))

  con <- file(tmp, "wb")
  writeChar("---\ntitle: Test\n---\nBody", con, eos = NULL)
  close(con)

  result <- read_front_matter(tmp)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "Body")
})
