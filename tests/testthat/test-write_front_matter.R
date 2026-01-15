# Basic YAML tests --------------------------------------------------------

test_that("write_front_matter() writes standard YAML front matter", {
  tmp <- withr::local_tempfile(fileext = ".md")

  fm <- list(
    data = list(title = "Test", author = "Me"),
    body = "Body content"
  )

  expect_snapshot(write_front_matter(fm))

  write_front_matter(fm, tmp)
  result <- read_front_matter(tmp)

  expect_equal(result$data$title, "Test")
  expect_equal(result$data$author, "Me")
  expect_equal(result$body, "Body content")
})

test_that("write_front_matter() writes standard TOML front matter", {
  tmp <- withr::local_tempfile(fileext = ".md")

  fm <- list(
    data = list(title = "Test", count = 42L),
    body = "Body content"
  )

  expect_snapshot(write_front_matter(fm, delimiter = "toml"))

  write_front_matter(fm, tmp, delimiter = "toml")
  result <- read_front_matter(tmp)

  expect_equal(result$data$title, "Test")
  expect_equal(result$data$count, 42L)
  expect_equal(result$body, "Body content")
})

test_that("write_front_matter() writes front matter with NULL data", {
  tmp <- withr::local_tempfile(fileext = ".md")

  fm <- list(
    data = NULL,
    body = "Body only"
  )

  write_front_matter(fm, tmp)
  content <- readLines(tmp, warn = FALSE)

  expect_equal(paste(content, collapse = "\n"), "Body only")
})

test_that("write_front_matter() writes front matter with NULL body", {
  tmp <- withr::local_tempfile(fileext = ".md")

  fm <- list(
    data = list(title = "Test"),
    body = NULL
  )

  write_front_matter(fm, tmp)
  result <- read_front_matter(tmp)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "")
})

test_that("write_front_matter() writes front matter with empty body", {
  tmp <- withr::local_tempfile(fileext = ".md")

  fm <- list(
    data = list(title = "Test"),
    body = ""
  )

  write_front_matter(fm, tmp)
  result <- read_front_matter(tmp)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "")
})

# Comment-wrapped formats -------------------------------------------------

test_that("write_front_matter() writes yaml_comment format", {
  tmp <- withr::local_tempfile(fileext = ".R")

  fm <- list(
    data = list(title = "Test"),
    body = "# R code here"
  )

  expect_snapshot(write_front_matter(fm, delimiter = "yaml_comment"))
  write_front_matter(fm, tmp, delimiter = "yaml_comment")

  # Check file content has correct structure
  content <- readLines(tmp, warn = FALSE)
  expect_equal(content[1], "# ---")
  expect_true(any(grepl("# title: Test", content)))

  # Body is preserved unchanged
  result <- read_front_matter(tmp)
  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "# R code here")
})

test_that("write_front_matter() writes toml_comment format", {
  tmp <- withr::local_tempfile(fileext = ".R")

  fm <- list(
    data = list(title = "Test"),
    body = "# R code here"
  )

  expect_snapshot(write_front_matter(fm, delimiter = "toml_comment"))
  write_front_matter(fm, tmp, delimiter = "toml_comment")

  # Check file content has correct structure
  content <- readLines(tmp, warn = FALSE)
  expect_equal(content[1], "# +++")

  # Body is preserved unchanged
  result <- read_front_matter(tmp)
  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "# R code here")
})

test_that("write_front_matter() writes yaml_roxy format", {
  tmp <- withr::local_tempfile(fileext = ".R")

  fm <- list(
    data = list(title = "Test"),
    body = "#' Roxygen comment"
  )

  expect_snapshot(write_front_matter(fm, delimiter = "yaml_roxy"))
  write_front_matter(fm, tmp, delimiter = "yaml_roxy")

  # Check file content has correct structure
  content <- readLines(tmp, warn = FALSE)
  expect_equal(content[1], "#' ---")

  # Body is preserved unchanged
  result <- read_front_matter(tmp)
  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "#' Roxygen comment")
})

test_that("write_front_matter() writes toml_roxy format", {
  tmp <- withr::local_tempfile(fileext = ".R")

  fm <- list(
    data = list(title = "Test"),
    body = "#' Roxygen comment"
  )

  expect_snapshot(write_front_matter(fm, delimiter = "toml_roxy"))
  write_front_matter(fm, tmp, delimiter = "toml_roxy")

  # Check file content has correct structure
  content <- readLines(tmp, warn = FALSE)
  expect_equal(content[1], "#' +++")

  # Body is preserved unchanged
  result <- read_front_matter(tmp)
  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "#' Roxygen comment")
})

# PEP 723 format ----------------------------------------------------------

test_that("write_front_matter() writes PEP 723 format", {
  tmp <- withr::local_tempfile(fileext = ".py")

  fm <- list(
    data = list(dependencies = c("requests", "numpy")),
    body = "import requests\nprint('hello')"
  )

  expect_snapshot(write_front_matter(fm, delimiter = "toml_pep723"))
  write_front_matter(fm, tmp, delimiter = "toml_pep723")

  # Check file content has correct structure
  content <- readLines(tmp, warn = FALSE)
  expect_equal(content[1], "# /// script")
  expect_true(any(grepl('# dependencies = \\["requests", "numpy"\\]', content)))
  expect_equal(content[3], "# ///")

  result <- read_front_matter(tmp)
  expect_equal(result$data$dependencies, c("requests", "numpy"))
  expect_equal(result$body, "import requests\nprint('hello')")
})

# Custom delimiters -------------------------------------------------------
test_that("write_front_matter() works with custom 1-element delimiter", {
  tmp <- withr::local_tempfile(fileext = ".md")

  fm <- list(
    data = list(title = "Test"),
    body = "Body"
  )

  write_front_matter(fm, tmp, delimiter = "---")
  result <- read_front_matter(tmp)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "Body")
})

test_that("write_front_matter() works with custom 2-element delimiter", {
  tmp <- withr::local_tempfile(fileext = ".R")

  fm <- list(
    data = list(title = "Test"),
    body = "code_here()"
  )

  write_front_matter(fm, tmp, delimiter = c("# ---", "# "))

  # Check file content has correct structure
  content <- readLines(tmp, warn = FALSE)
  expect_equal(content[1], "# ---")
  expect_true(any(grepl("# title: Test", content)))

  # read_front_matter strips comment prefix from body
  result <- read_front_matter(tmp)
  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "code_here()")
})

test_that("write_front_matter() works with custom 3-element delimiter", {
  tmp <- withr::local_tempfile(fileext = ".py")

  fm <- list(
    data = list(dependencies = c("requests")),
    body = "import requests"
  )

  write_front_matter(fm, tmp, delimiter = c("# /// script", "# ", "# ///"))

  # Check file content has correct structure
  content <- readLines(tmp, warn = FALSE)
  expect_equal(content[1], "# /// script")
  expect_equal(content[3], "# ///")

  result <- read_front_matter(tmp)
  expect_equal(result$data$dependencies, c("requests"))
  expect_equal(result$body, "import requests")
})

# Custom formatters -------------------------------------------------------

test_that("write_front_matter() uses custom format_yaml", {
  tmp <- withr::local_tempfile(fileext = ".md")

  fm <- list(
    data = list(title = "Test"),
    body = "Body"
  )

  custom_formatter <- function(x) {
    paste0("# custom\n", yaml12::format_yaml(x))
  }

  write_front_matter(fm, tmp, format_yaml = custom_formatter)
  content <- readLines(tmp, warn = FALSE)

  expect_true("# custom" %in% content)
})

test_that("write_front_matter() uses custom format_toml", {
  tmp <- withr::local_tempfile(fileext = ".md")

  fm <- list(
    data = list(title = "Test"),
    body = "Body"
  )

  custom_formatter <- function(x) {
    paste0("# custom\n", tomledit::to_toml(tomledit::as_toml(x)))
  }

  write_front_matter(
    fm,
    tmp,
    delimiter = "toml",
    format_toml = custom_formatter
  )
  content <- readLines(tmp, warn = FALSE)

  expect_true("# custom" %in% content)
})

# Format argument ---------------------------------------------------------

test_that("write_front_matter() respects format = 'yaml'", {
  tmp <- withr::local_tempfile(fileext = ".md")

  fm <- list(
    data = list(title = "Test"),
    body = "Body"
  )

  write_front_matter(fm, tmp, delimiter = "---", format = "yaml")
  content <- paste(readLines(tmp, warn = FALSE), collapse = "\n")

  expect_true(grepl("title: Test", content))
})

test_that("write_front_matter() respects format = 'toml'", {
  tmp <- withr::local_tempfile(fileext = ".md")

  fm <- list(
    data = list(title = "Test"),
    body = "Body"
  )

  write_front_matter(fm, tmp, delimiter = "+++", format = "toml")
  content <- paste(readLines(tmp, warn = FALSE), collapse = "\n")

  expect_true(grepl('title = "Test"', content))
})

# Roundtrip tests ---------------------------------------------------------

test_that("roundtrip: YAML front matter preserves data", {
  tmp <- withr::local_tempfile(fileext = ".md")

  original <- list(
    data = list(
      title = "My Document",
      author = "Test Author",
      tags = c("r", "testing")
    ),
    body = "This is the body content.\n\nWith multiple paragraphs."
  )

  write_front_matter(original, tmp)
  result <- read_front_matter(tmp)

  expect_equal(result$data$title, original$data$title)
  expect_equal(result$data$author, original$data$author)
  expect_equal(result$data$tags, original$data$tags)
  expect_equal(result$body, original$body)
})

test_that("roundtrip: TOML front matter preserves data", {
  tmp <- withr::local_tempfile(fileext = ".md")

  original <- list(
    data = list(
      title = "My Document",
      count = 42L,
      enabled = TRUE
    ),
    body = "Body content"
  )

  write_front_matter(original, tmp, delimiter = "toml")
  result <- read_front_matter(tmp)

  expect_equal(result$data$title, original$data$title)
  expect_equal(result$data$count, original$data$count)
  expect_equal(result$data$enabled, original$data$enabled)
  expect_equal(result$body, original$body)
})

test_that("roundtrip: comment-wrapped format preserves data", {
  tmp <- withr::local_tempfile(fileext = ".R")

  original <- list(
    data = list(title = "R Script"),
    body = "code_here()\nprint('hello')"
  )

  write_front_matter(original, tmp, delimiter = "yaml_comment")
  result <- read_front_matter(tmp)

  expect_equal(result$data$title, original$data$title)
  # Body is preserved (no comment prefix to strip)
  expect_equal(result$body, original$body)
})

# Input validation --------------------------------------------------------

test_that("write_front_matter() errors on non-list input", {
  tmp <- withr::local_tempfile(fileext = ".md")

  expect_error(
    write_front_matter("not a list", tmp),
    "must be a list"
  )
})

test_that("write_front_matter() errors on invalid format_yaml", {
  tmp <- withr::local_tempfile(fileext = ".md")
  fm <- list(data = list(title = "Test"), body = "Body")

  expect_error(
    write_front_matter(fm, tmp, format_yaml = "not a function"),
    "must be a function"
  )
})

test_that("write_front_matter() errors on invalid format_toml", {
  tmp <- withr::local_tempfile(fileext = ".md")
  fm <- list(data = list(title = "Test"), body = "Body")

  expect_error(
    write_front_matter(fm, tmp, format_toml = "not a function"),
    "must be a function"
  )
})

test_that("write_front_matter() errors on invalid delimiter length", {
  tmp <- withr::local_tempfile(fileext = ".md")
  fm <- list(data = list(title = "Test"), body = "Body")

  expect_error(
    write_front_matter(fm, tmp, delimiter = c("a", "b", "c", "d")),
    "length 1, 2, or 3"
  )
})

test_that("write_front_matter() errors when format cannot be auto-detected", {
  tmp <- withr::local_tempfile(fileext = ".md")
  fm <- list(data = list(title = "Test"), body = "Body")

  expect_error(
    write_front_matter(fm, tmp, delimiter = "???"),
    "Could not auto-detect format"
  )
})

test_that("write_front_matter() errors on invalid format argument", {
  tmp <- withr::local_tempfile(fileext = ".md")
  fm <- list(data = list(title = "Test"), body = "Body")

  expect_error(
    write_front_matter(fm, tmp, format = "invalid"),
    "must be one of"
  )
})

test_that("write_front_matter() errors when formatter returns non-character", {
  tmp <- withr::local_tempfile(fileext = ".md")
  fm <- list(data = list(title = "Test"), body = "Body")

  bad_formatter <- function(x) 123

  expect_error(
    write_front_matter(fm, tmp, format_yaml = bad_formatter),
    "must return a character vector"
  )
})

# YAML serialization spec options ------------------------------------------

test_that("frontmatter.serialize_yaml.spec = '1.1' option uses yaml package", {
  withr::local_options(frontmatter.serialize_yaml.spec = "1.1")

  fm <- list(
    data = list(title = "Test", count = 42L),
    body = "Body content"
  )

  formatted <- format_front_matter(fm, delimiter = "yaml")
  result <- parse_front_matter(formatted)

  expect_equal(result$data$title, "Test")
  expect_equal(result$data$count, 42L)
  expect_equal(result$body, "Body content")
})

test_that("FRONTMATTER_SERIALIZE_YAML_SPEC = '1.1' envvar uses yaml package", {
  withr::local_envvar(FRONTMATTER_SERIALIZE_YAML_SPEC = "1.1")

  fm <- list(
    data = list(title = "Test", count = 42L),
    body = "Body content"
  )

  formatted <- format_front_matter(fm, delimiter = "yaml")
  result <- parse_front_matter(formatted)

  expect_equal(result$data$title, "Test")
  expect_equal(result$data$count, 42L)
  expect_equal(result$body, "Body content")
})

test_that("frontmatter.serialize_yaml.spec option takes precedence over envvar", {
  withr::local_envvar(FRONTMATTER_SERIALIZE_YAML_SPEC = "1.2")
  withr::local_options(frontmatter.serialize_yaml.spec = "1.1")

  fm <- list(
    data = list(title = "Test", tags = c("a", "b")),
    body = "Body content"
  )

  formatted <- format_front_matter(fm, delimiter = "yaml")
  result <- parse_front_matter(formatted)

  expect_equal(result$data$title, "Test")
  expect_equal(result$data$tags, c("a", "b"))
  expect_equal(result$body, "Body content")
})
