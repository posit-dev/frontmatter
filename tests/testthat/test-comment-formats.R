test_that("standard # comment-wrapped YAML works", {
  text <- "# ---\n# title: Test\n# date: 2024-01-01\n# ---\n\nBody content"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(result$data$date, "2024-01-01")
  expect_equal(result$body, "Body content")
})

test_that("standard # comment-wrapped TOML works", {
  text <- "# +++\n# title = \"Test\"\n# count = 42\n# +++\n\nBody content"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(result$data$count, 42)
  expect_equal(result$body, "Body content")
})

test_that("Roxygen #' comment-wrapped YAML works", {
  text <- "#' ---\n#' title: Test\n#' author: Someone\n#' ---\n#'\n#' Body content"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(result$data$author, "Someone")
  # Body is preserved unchanged (including #' prefix)
  expect_equal(result$body, "#' Body content")
})

test_that("Roxygen #' comment-wrapped TOML works", {
  text <- "#' +++\n#' title = \"Test\"\n#' count = 99\n#' +++\n#'\n#' Body content"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(result$data$count, 99)
  # Body is preserved unchanged (including #' prefix)
  expect_equal(result$body, "#' Body content")
})

test_that("comment-wrapped with empty comment lines works", {
  text <- "# ---\n# title: Test\n#\n# description: Multi-line\n# ---\n\nBody"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "Body")
})

test_that("comment-wrapped multiline YAML works", {
  text <- "# ---\n# title: Test\n# tags:\n#   - tag1\n#   - tag2\n# ---\n\nBody"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(length(result$data$tags), 2)
  expect_equal(result$body, "Body")
})

test_that("comment-wrapped front matter only works", {
  text <- "# ---\n# title: Test\n# ---"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "")
})

test_that("comment-wrapped with body that has comments works", {
  text <- "# ---\n# title: Test\n# ---\n\n# This is a comment in the body\nBody content"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "# This is a comment in the body\nBody content")
})

test_that("mismatched comment styles don't parse", {
  # Opening with # but closing with #'
  text <- "# ---\n# title: Test\n#' ---\nBody"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("comment-wrapped requires exact prefix", {
  # Missing space after #
  text <- "#---\n#title: Test\n#---\nBody"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("standard and comment-wrapped don't mix", {
  # Standard opening, comment closing
  text <- "---\ntitle: Test\n# ---\nBody"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("comment-wrapped with CRLF works", {
  text <- "# ---\r\n# title: Test\r\n# ---\r\nBody"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "Body")
})

test_that("comment-wrapped with trailing spaces on fences", {
  text <- "# ---   \n# title: Test\n# ---   \nBody"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "Body")
})
