test_that("front_matter_text parses YAML correctly", {
  skip_if_not_installed("yaml12")

  text <- "---\ntitle: Test\ndate: 2024-01-01\n---\nBody content"
  result <- front_matter_text(text)

  expect_true(!is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(result$data$date, "2024-01-01")
  expect_equal(result$body, "Body content")
})

test_that("front_matter_text parses TOML correctly", {
  skip_if_not_installed("toml")

  text <- "+++\ntitle = \"Test\"\ncount = 42\n+++\nBody content"
  result <- front_matter_text(text)

  expect_true(!is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(result$data$count, 42)
  expect_equal(result$body, "Body content")
})

test_that("front_matter_text returns NULL for no front matter", {
  text <- "Just content\nNo front matter"
  result <- front_matter_text(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("front_matter_text handles empty documents", {
  result <- front_matter_text("")

  expect_null(result$data)
  expect_equal(result$body, "")
})

test_that("front_matter_text handles documents with only front matter", {
  skip_if_not_installed("yaml12")

  text <- "---\ntitle: Test\n---"
  result <- front_matter_text(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "")
})

test_that("front_matter_text validates input", {
  expect_error(front_matter_text(123), "must be a character vector")
})

test_that("front_matter_text accepts multi-element vectors", {
  skip_if_not_installed("yaml12")

  # Multi-element vectors are joined with newlines (as from readLines())
  lines <- c("---", "title: Test", "---", "Body content")
  result <- front_matter_text(lines)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "Body content")
})

test_that("front_matter_text validates parsers argument", {
  text <- "---\ntitle: Test\n---\nBody"

  expect_error(
    front_matter_text(text, parsers = "invalid"),
    "must be a list with elements"
  )

  expect_error(
    front_matter_text(text, parsers = list(yaml = "not a function")),
    "must be a list with elements"
  )

  expect_error(
    front_matter_text(
      text,
      parsers = list(yaml = identity, toml = "not a function")
    ),
    "must be a function"
  )
})

test_that("front_matter_text handles multiline YAML", {
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

  result <- front_matter_text(text)

  expect_equal(result$data$title, "Test")
  expect_true(grepl("Multi-line", result$data$description))
  expect_equal(length(result$data$tags), 2)
  expect_equal(result$body, "Content")
})

test_that("front_matter_read reads files correctly", {
  skip_if_not_installed("yaml12")

  # Create a temporary file
  tmp <- tempfile(fileext = ".md")
  on.exit(unlink(tmp))

  # writeLines adds a trailing newline, which is preserved
  writeLines("---\ntitle: Test\n---\nBody", tmp)

  result <- front_matter_read(tmp)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "Body\n")
})

test_that("front_matter_read validates input", {
  expect_error(front_matter_read(123), "must be a single string")
  expect_error(front_matter_read("nonexistent.md"), "File does not exist")
})

test_that("front_matter_read handles files with CRLF line endings", {
  skip_if_not_installed("yaml12")

  tmp <- tempfile(fileext = ".md")
  on.exit(unlink(tmp))

  # Write file with CRLF endings
  con <- file(tmp, "wb")
  writeChar("---\r\ntitle: Test\r\n---\r\nBody\r\n", con, eos = NULL)
  close(con)

  result <- front_matter_read(tmp)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "Body\r\n")
})

test_that("front_matter_read handles files without trailing newline", {
  skip_if_not_installed("yaml12")

  tmp <- tempfile(fileext = ".md")
  on.exit(unlink(tmp))

  con <- file(tmp, "wb")
  writeChar("---\ntitle: Test\n---\nBody", con, eos = NULL)
  close(con)

  result <- front_matter_read(tmp)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "Body")
})
