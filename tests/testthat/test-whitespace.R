test_that("CRLF line endings preserved in body", {
  skip_if_not_installed("yaml12")

  text <- "---\r\ntitle: Test\r\n---\r\nBody\r\n"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "Body\r\n")
})

test_that("LF line endings work", {
  skip_if_not_installed("yaml12")

  text <- "---\ntitle: Test\n---\nBody\n"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "Body\n")
})

test_that("mixed line endings work", {
  skip_if_not_installed("yaml12")

  text <- "---\ntitle: Test\r\n---\nBody"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "Body")
})

test_that("trailing spaces on opening fence allowed", {
  skip_if_not_installed("yaml12")

  text <- "---     \ntitle: Test\n---\nBody"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
})

test_that("trailing tabs on opening fence allowed", {
  skip_if_not_installed("yaml12")

  text <- "---\t\t\ntitle: Test\n---\nBody"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
})

test_that("trailing spaces on closing fence allowed", {
  skip_if_not_installed("yaml12")

  text <- "---\ntitle: Test\n---     \nBody"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
})

test_that("trailing tabs on closing fence allowed", {
  skip_if_not_installed("yaml12")

  text <- "---\ntitle: Test\n---\t\t\nBody"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
})

test_that("leading empty lines in body are trimmed", {
  skip_if_not_installed("yaml12")

  text <- "---\ntitle: Test\n---\n\n\nBody"
  result <- parse_front_matter(text)

  expect_equal(result$body, "Body")
})

test_that("leading whitespace-only lines in body are trimmed", {
  skip_if_not_installed("yaml12")

  text <- "---\ntitle: Test\n---\n   \n\t\nBody"
  result <- parse_front_matter(text)

  expect_equal(result$body, "Body")
})

test_that("leading whitespace before content is preserved", {
  skip_if_not_installed("yaml12")

  text <- "---\ntitle: Test\n---\n   Body with leading spaces"
  result <- parse_front_matter(text)

  expect_equal(result$body, "   Body with leading spaces")
})

test_that("whitespace in content is preserved", {
  skip_if_not_installed("yaml12")

  text <- "---\ntitle:   Test   \nspaces:    value    \n---\nBody"
  result <- parse_front_matter(text)

  # YAML parser handles whitespace around values
  expect_equal(result$data$title, "Test")
})

test_that("empty body after front matter", {
  skip_if_not_installed("yaml12")

  text <- "---\ntitle: Test\n---"
  result <- parse_front_matter(text)

  expect_equal(result$body, "")
})

test_that("body with only whitespace becomes empty", {
  skip_if_not_installed("yaml12")

  text <- "---\ntitle: Test\n---\n   \n\t\n  "
  result <- parse_front_matter(text)

  expect_equal(result$body, "")
})

test_that("CRLF in content is preserved", {
  skip_if_not_installed("yaml12")

  text <- "---\r\ntitle: Test\r\nlist:\r\n  - item1\r\n  - item2\r\n---\r\nBody"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(length(result$data$list), 2)
})

test_that("TOML with CRLF works", {
  skip_if_not_installed("toml")

  text <- "+++\r\ntitle = \"Test\"\r\ncount = 42\r\n+++\r\nBody"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$data$count, 42)
})
