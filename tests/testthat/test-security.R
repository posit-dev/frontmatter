test_that("large front matter is parsed correctly", {
  # Create large front matter (previously would have exceeded 1 MB limit)
  large_content <- paste(rep("x: value\n", 50000), collapse = "")
  text <- paste0("---\n", large_content, "---\nBody")

  result <- parse_front_matter(text)

  # Large front matter should be parsed successfully

  expect_false(is.null(result$data))
  expect_equal(result$body, "Body")
})

test_that("front matter with many lines is parsed correctly", {
  # Create front matter with many lines (previously would have exceeded 10K line limit)
  lines <- paste(rep("x: value\n", 11000), collapse = "")
  text <- paste0("---\n", lines, "---\nBody")

  result <- parse_front_matter(text)

  # Should parse successfully
  expect_false(is.null(result$data))
  expect_equal(result$body, "Body")
})

test_that("large comment-wrapped front matter is parsed correctly", {
  # Create large comment-wrapped front matter
  lines <- paste(rep("# x: value\n", 11000), collapse = "")
  text <- paste0("# ---\n", lines, "# ---\nBody")

  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$body, "Body")
})

test_that("large PEP 723 block is parsed correctly", {
  # Create large PEP 723 block with an array (TOML doesn't allow duplicate keys)
  # Each line must start with "# " for valid PEP 723
  array_items <- paste(rep("#   \"value\",\n", 11000), collapse = "")
  text <- paste0(
    "# /// script\n# dependencies = [\n",
    array_items,
    "# ]\n# ///\nBody"
  )

  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$body, "Body")
})

test_that("document without front matter handles large content", {
  # Document without front matter but with many lines
  lines <- paste(rep("Line of content\n", 20000), collapse = "")
  text <- lines

  result <- parse_front_matter(text)

  # No front matter found
  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("empty front matter is parsed correctly", {
  text <- "---\n---\nBody"
  result <- parse_front_matter(text)

  # Empty YAML returns NULL from parser, but front matter was successfully extracted
  expect_null(result$data)
  expect_equal(result$body, "Body")
})
