test_that("custom YAML parser works", {
  text <- "---\nkey: value\n---\nBody"

  # Use identity to get raw string
  result <- parse_front_matter(text, parse_yaml = identity)

  expect_equal(result$data, "key: value\n")
  expect_equal(result$body, "Body")
})

test_that("custom TOML parser works", {
  text <- "+++\nkey = \"value\"\n+++\nBody"

  # Use identity to get raw string
  result <- parse_front_matter(text, parse_toml = identity)

  expect_equal(result$data, "key = \"value\"\n")
  expect_equal(result$body, "Body")
})

test_that("both custom parsers can be specified", {
  text_yaml <- "---\nkey: value\n---\nYAML Body"
  text_toml <- "+++\nkey = \"value\"\n+++\nTOML Body"

  result_yaml <- parse_front_matter(text_yaml, parse_yaml = identity)
  expect_equal(result_yaml$data, "key: value\n")

  result_toml <- parse_front_matter(text_toml, parse_toml = identity)
  expect_equal(result_toml$data, "key = \"value\"\n")
})

test_that("custom parser that transforms data works", {
  skip_if_not_installed("yaml12")

  text <- "---\ntitle: Test\n---\nBody"

  # Custom parser that uppercases the title
  custom_yaml <- function(x) {
    parsed <- yaml12::parse_yaml(x)
    if (!is.null(parsed$title)) {
      parsed$title <- toupper(parsed$title)
    }
    parsed
  }

  result <- parse_front_matter(text, parse_yaml = custom_yaml)

  expect_equal(result$data$title, "TEST")
})

test_that("parser errors propagate to user", {
  text <- "---\ninvalid: [unclosed\n---\nBody"

  # Parser that throws on invalid YAML
  failing_parser <- function(x) {
    stop("Parse error: invalid YAML")
  }

  expect_error(
    parse_front_matter(text, parse_yaml = failing_parser),
    "Parse error"
  )
})


test_that("parsers can return NULL for empty front matter", {
  text <- "---\n---\nBody"

  # Parser that returns NULL for empty strings
  null_parser <- function(x) {
    if (nchar(trimws(x)) == 0) NULL else x
  }

  result <- parse_front_matter(text, parse_yaml = null_parser)

  expect_null(result$data)
  expect_equal(result$body, "Body")
})

test_that("parsers can return complex R objects", {
  text <- "---\nkey: value\n---\nBody"

  # Parser that returns a custom S3 object
  custom_parser <- function(x) {
    obj <- list(raw = x, parsed = TRUE)
    class(obj) <- "custom_front_matter"
    obj
  }

  result <- parse_front_matter(text, parse_yaml = custom_parser)

  expect_s3_class(result$data, "custom_front_matter")
  expect_equal(result$data$raw, "key: value\n")
  expect_true(result$data$parsed)
})

test_that("empty YAML front matter gets passed to parser", {
  skip_if_not_installed("yaml12")

  text <- "---\n---\nBody"
  result <- parse_front_matter(text)

  # yaml12 returns NULL for empty YAML
  expect_null(result$data)
  expect_equal(result$body, "Body")
})
