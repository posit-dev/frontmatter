test_that("valid PEP 723 block parses correctly", {
  skip_if_not_installed("toml")

  text <- "# /// script
# requires-python = \">=3.11\"
# dependencies = [
#     \"requests<3\",
#     \"rich\",
# ]
# ///

import requests"

  result <- parse_front_matter(text)

  expect_true(!is.null(result$data))
  expect_equal(result$data$`requires-python`, ">=3.11")
  expect_equal(length(result$data$dependencies), 2)
  expect_equal(result$body, "import requests")
})

test_that("PEP 723 with bare # lines works", {
  skip_if_not_installed("toml")

  text <- "# /// script
# requires-python = \">=3.11\"
#
# dependencies = [\"requests\"]
# ///

import requests"

  result <- parse_front_matter(text)

  expect_true(!is.null(result$data))
  expect_equal(result$data$`requires-python`, ">=3.11")
})

test_that("PEP 723 with CRLF works", {
  skip_if_not_installed("toml")

  text <- "# /// script\r\n# name = \"test\"\r\n# ///\r\nimport sys"
  result <- parse_front_matter(text)

  expect_equal(result$data$name, "test")
  expect_equal(result$body, "import sys")
})

test_that("invalid PEP 723 opening is rejected", {
  # Missing space after ///
  text <- "# ///script\n# content\n# ///\nbody"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("invalid PEP 723 content line is rejected", {
  skip_if_not_installed("toml")

  # Line without # prefix
  text <- "# /// script\nrequires-python = \">=3.11\"\n# ///\nbody"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("PEP 723 missing closing delimiter", {
  text <- "# /// script\n# requires-python = \">=3.11\"\nimport requests"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("PEP 723 with tool sections works", {
  skip_if_not_installed("toml")

  text <- "# /// script
# requires-python = \">=3.11\"
# [tool.my-runner]
# mode = \"isolated\"
# ///

import sys"

  result <- parse_front_matter(text)

  expect_equal(result$data$`requires-python`, ">=3.11")
  expect_equal(result$data$tool$`my-runner`$mode, "isolated")
})

test_that("PEP 723 empty block works", {
  skip_if_not_installed("toml")

  text <- "# /// script\n# ///\nimport sys"
  result <- parse_front_matter(text)

  # Empty TOML should return empty list or NULL
  expect_true(is.null(result$data) || length(result$data) == 0)
  expect_equal(result$body, "import sys")
})

test_that("PEP 723 ending without newline works", {
  skip_if_not_installed("toml")

  text <- "# /// script\n# name = \"test\"\n# ///"
  result <- parse_front_matter(text)

  expect_equal(result$data$name, "test")
  expect_equal(result$body, "")
})

test_that("PEP 723 with trailing whitespace on delimiters", {
  skip_if_not_installed("toml")

  text <- "# /// script   \n# name = \"test\"\n# ///   \nimport sys"
  result <- parse_front_matter(text)

  expect_equal(result$data$name, "test")
  expect_equal(result$body, "import sys")
})

test_that("PEP 723 distinguishes from standard # comments", {
  # Just "# ---" should not be treated as PEP 723
  text <- "# /// not-script\n# content\n# ///\nbody"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("PEP 723 requires exact closing format", {
  # Closing with extra text
  text <- "# /// script\n# name = \"test\"\n# /// end\nbody"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("PEP 723 line must start with # followed by space", {
  skip_if_not_installed("toml")

  # Missing space after #
  text <- "# /// script\n#name = \"test\"\n# ///\nbody"
  result <- parse_front_matter(text)

  # This should fail validation
  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("PEP 723 doesn't conflict with standard formats", {
  skip_if_not_installed("yaml12")

  # Standard YAML should still work
  text <- "---\ntitle: Test\n---\nBody"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
})
