test_that("shebang + # comment-wrapped YAML (0 blank lines)", {
  text <- "#!/usr/bin/env bash\n# ---\n# title: My Script\n# author: Garrick\n# ---\nscript content"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "My Script")
  expect_equal(result$data$author, "Garrick")
  expect_equal(result$body, "#!/usr/bin/env bash\nscript content")
})

test_that("shebang + # comment-wrapped YAML (1 blank line)", {
  text <- "#!/usr/bin/env bash\n\n# ---\n# title: My Script\n# ---\nscript content"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "My Script")
  expect_equal(result$body, "#!/usr/bin/env bash\nscript content")
})

test_that("shebang + 2 blank lines does not parse", {
  text <- "#!/usr/bin/env bash\n\n\n# ---\n# title: My Script\n# ---\nscript content"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("shebang + Roxygen #' comment-wrapped YAML", {
  text <- "#!/usr/bin/env Rscript\n#' ---\n#' title: My R Script\n#' ---\n#'\n#' body"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "My R Script")
  expect_equal(result$body, "#!/usr/bin/env Rscript\n#' body")
})

test_that("shebang + PEP 723 Python script", {
  text <- "#!/usr/bin/env python3\n# /// script\n# requires-python = \">=3.11\"\n# dependencies = [\"httpx\"]\n# ///\nimport httpx"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$`requires-python`, ">=3.11")
  expect_equal(result$body, "#!/usr/bin/env python3\nimport httpx")
})

test_that("shebang + PEP 723 Python script (1 blank line)", {
  text <- "#!/usr/bin/env python3\n\n# /// script\n# requires-python = \">=3.11\"\n# ///\nimport httpx"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$`requires-python`, ">=3.11")
  expect_equal(result$body, "#!/usr/bin/env python3\nimport httpx")
})

test_that("shebang + standard YAML fence does not parse", {
  text <- "#!/usr/bin/env bash\n---\ntitle: My Script\n---\nscript content"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("shebang + standard TOML fence does not parse", {
  text <- "#!/usr/bin/env bash\n+++\ntitle = \"My Script\"\n+++\nscript content"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("#! on non-first line does not trigger shebang logic", {
  text <- "# ---\n# title: Test\n# ---\n#!/usr/bin/env bash\nscript content"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "#!/usr/bin/env bash\nscript content")
})

test_that("shebang only with no front matter returns NULL", {
  text <- "#!/usr/bin/env bash\nscript content"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("shebang is included in returned body", {
  text <- "#!/usr/bin/env Rscript\n# ---\n# title: Test\n# ---\nx <- 1"
  result <- parse_front_matter(text)

  expect_true(startsWith(result$body, "#!/usr/bin/env Rscript"))
})

test_that("format_front_matter moves shebang to top for comment-prefixed delimiters", {
  doc <- list(
    data = list(title = "My Script"),
    body = "#!/usr/bin/env bash\nscript content"
  )
  out <- format_front_matter(doc, delimiter = "yaml_comment")

  expect_true(startsWith(out, "#!/usr/bin/env bash\n"))
  expect_true(grepl("# ---", out))
  expect_true(grepl("title: My Script", out))
  expect_true(grepl("script content", out))
})

test_that("format_front_matter tight spacing: no blank line between shebang and opener", {
  doc <- list(
    data = list(title = "My Script"),
    body = "#!/usr/bin/env bash\nscript content"
  )
  out <- format_front_matter(doc, delimiter = "yaml_comment")

  expect_equal(
    out,
    "#!/usr/bin/env bash\n# ---\n# title: My Script\n# ---\n\nscript content\n"
  )
})

test_that("format_front_matter does NOT move shebang for standard YAML delimiter", {
  doc <- list(
    data = list(title = "Test"),
    body = "#!/usr/bin/env bash\nscript content"
  )
  out <- format_front_matter(doc, delimiter = "yaml")

  expect_true(startsWith(out, "---\n"))
})

test_that("roundtrip: parse shebang file then reformat produces valid output", {
  text <- "#!/usr/bin/env bash\n# ---\n# title: My Script\n# ---\nscript content"
  result <- parse_front_matter(text)
  out <- format_front_matter(result, delimiter = attr(result, "fence_type"))

  expect_true(startsWith(out, "#!/usr/bin/env bash\n"))
  re_parsed <- parse_front_matter(out)
  expect_equal(re_parsed$data$title, "My Script")
  expect_equal(re_parsed$body, "#!/usr/bin/env bash\nscript content")
})

test_that("shebang + # comment-wrapped TOML", {
  text <- "#!/usr/bin/env bash\n# +++\n# title = \"My Script\"\n# +++\nscript content"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "My Script")
  expect_equal(result$body, "#!/usr/bin/env bash\nscript content")
})

test_that("shebang body starting with comment prefix gets correct separator on format", {
  doc <- list(
    data = list(title = "My Script"),
    body = "#!/usr/bin/env bash\n# This is a comment\nscript content"
  )
  out <- format_front_matter(doc, delimiter = "yaml_comment")

  # Body after shebang starts with "# ", so space_line should be bare "#"
  expect_true(grepl("# ---\n#\n# This is a comment", out))
})
