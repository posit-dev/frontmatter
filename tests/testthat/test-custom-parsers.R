test_that("front_matter_parsers creates parser list", {
  skip_if_not_installed("yaml12")
  skip_if_not_installed("toml")

  parsers <- front_matter_parsers()

  expect_type(parsers, "list")
  expect_named(parsers, c("yaml", "toml"))
  expect_type(parsers$yaml, "closure")
  expect_type(parsers$toml, "closure")
})

test_that("custom YAML parser works", {
  text <- "---\nkey: value\n---\nBody"

  # Use identity to get raw string
  parsers <- front_matter_parsers(yaml = identity)
  result <- front_matter_text(text, parsers = parsers)

  expect_equal(result$data, "key: value\n")
  expect_equal(result$body, "Body")
})

test_that("custom TOML parser works", {
  text <- "+++\nkey = \"value\"\n+++\nBody"

  # Use identity to get raw string
  parsers <- front_matter_parsers(toml = identity)
  result <- front_matter_text(text, parsers = parsers)

  expect_equal(result$data, "key = \"value\"\n")
  expect_equal(result$body, "Body")
})

test_that("both custom parsers can be specified", {
  text_yaml <- "---\nkey: value\n---\nYAML Body"
  text_toml <- "+++\nkey = \"value\"\n+++\nTOML Body"

  parsers <- front_matter_parsers(yaml = identity, toml = identity)

  result_yaml <- front_matter_text(text_yaml, parsers = parsers)
  expect_equal(result_yaml$data, "key: value\n")

  result_toml <- front_matter_text(text_toml, parsers = parsers)
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

  parsers <- front_matter_parsers(yaml = custom_yaml)
  result <- front_matter_text(text, parsers = parsers)

  expect_equal(result$data$title, "TEST")
})

test_that("parser errors propagate to user", {
  text <- "---\ninvalid: [unclosed\n---\nBody"

  # Parser that throws on invalid YAML
  failing_parser <- function(x) {
    stop("Parse error: invalid YAML")
  }

  parsers <- front_matter_parsers(yaml = failing_parser)

  expect_error(
    front_matter_text(text, parsers = parsers),
    "Parse error"
  )
})


test_that("parsers can return NULL for empty front matter", {
  text <- "---\n---\nBody"

  # Parser that returns NULL for empty strings
  null_parser <- function(x) {
    if (nchar(trimws(x)) == 0) NULL else x
  }

  parsers <- front_matter_parsers(yaml = null_parser)
  result <- front_matter_text(text, parsers = parsers)

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

  parsers <- front_matter_parsers(yaml = custom_parser)
  result <- front_matter_text(text, parsers = parsers)

  expect_s3_class(result$data, "custom_front_matter")
  expect_equal(result$data$raw, "key: value\n")
  expect_true(result$data$parsed)
})

test_that("empty YAML front matter gets passed to parser", {
  skip_if_not_installed("yaml12")

  text <- "---\n---\nBody"
  result <- front_matter_text(text)

  # yaml12 returns NULL for empty YAML
  expect_null(result$data)
  expect_equal(result$body, "Body")
})
