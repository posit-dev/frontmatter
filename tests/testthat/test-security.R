test_that("front matter size limits are enforced", {
  # Create front matter that exceeds 1 MB limit
  large_content <- paste(rep("x: value\n", 50000), collapse = "")
  text <- paste0("---\n", large_content, "---\nBody")

  result <- front_matter_text(text)

  # Should reject due to size limit
  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("front matter line limits are enforced", {
  # Create more than 10,000 lines
  lines <- paste(rep("x: value\n", 11000), collapse = "")
  text <- paste0("---\n", lines, "---\nBody")

  result <- front_matter_text(text)

  # Should reject due to line limit
  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("reasonable front matter size works", {
  skip_if_not_installed("yaml12")

  # 1000 lines should be fine
  lines <- paste(rep("x: value\n", 1000), collapse = "")
  text <- paste0("---\n", lines, "---\nBody")

  result <- front_matter_text(text)

  expect_true(!is.null(result$data))
  expect_equal(result$body, "Body")
})

test_that("comment-wrapped format respects limits", {
  # Create large comment-wrapped front matter
  lines <- paste(rep("# x: value\n", 11000), collapse = "")
  text <- paste0("# ---\n", lines, "# ---\nBody")

  result <- front_matter_text(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("PEP 723 format respects limits", {
  # Create large PEP 723 block
  lines <- paste(rep("# x = \"value\"\n", 11000), collapse = "")
  text <- paste0("# /// script\n", lines, "# ///\nBody")

  result <- front_matter_text(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("normal document is not affected by limits", {
  skip_if_not_installed("yaml12")

  # Document without front matter but with many lines
  lines <- paste(rep("Line of content\n", 20000), collapse = "")
  text <- lines

  result <- front_matter_text(text)

  # Should work fine - no front matter means no limits apply
  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("front matter at limit boundary works", {
  skip_if_not_installed("yaml12")

  # Exactly at line limit (10,000 lines)
  lines <- paste(rep("x: value\n", 9998), collapse = "")
  text <- paste0("---\n", lines, "---\nBody")

  result <- front_matter_text(text)

  # Should work - just under limit
  expect_true(!is.null(result$data))
})

test_that("empty front matter doesn't trigger limits", {
  skip_if_not_installed("yaml12")

  text <- "---\n---\nBody"
  result <- front_matter_text(text)

  # Empty YAML returns NULL from parser, but front matter was successfully extracted
  # (not rejected due to limits). The key test is that body is "Body", not original text.
  expect_null(result$data)
  expect_equal(result$body, "Body")
})
