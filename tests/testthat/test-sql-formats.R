# SQL line comments ----

test_that("SQL line comment YAML works", {
  text <- "-- ---\n-- title: Test\n-- date: 2024-01-01\n-- ---\n\nSELECT 1"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(result$data$date, "2024-01-01")
  expect_equal(result$body, "SELECT 1")
})

test_that("SQL line comment TOML works", {
  text <- "-- +++\n-- title = \"Test\"\n-- count = 42\n-- +++\n\nSELECT 1"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(result$data$count, 42)
  expect_equal(result$body, "SELECT 1")
})

test_that("SQL line comment front matter only (no body) works", {
  text <- "-- ---\n-- title: Test\n-- ---"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "")
})

test_that("SQL line comment body starting with -- is preserved", {
  text <- "-- ---\n-- title: Test\n-- ---\n\n-- this is a SQL comment\nSELECT 1"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "-- this is a SQL comment\nSELECT 1")
})

test_that("SQL line comment with CRLF works", {
  text <- "-- ---\r\n-- title: Test\r\n-- ---\r\nSELECT 1"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "SELECT 1")
})

test_that("SQL line comment with trailing spaces on fences works", {
  text <- "-- ---   \n-- title: Test\n-- ---   \nSELECT 1"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "SELECT 1")
})

test_that("SQL line comment fence_type attribute is yaml_sql_line", {
  text <- "-- ---\n-- title: Test\n-- ---\n\nSELECT 1"
  result <- parse_front_matter(text)

  expect_equal(attr(result, "fence_type"), "yaml_sql_line")
  expect_equal(attr(result, "format"), "yaml")
})

test_that("SQL line comment TOML fence_type attribute is toml_sql_line", {
  text <- "-- +++\n-- title = \"Test\"\n-- +++\n\nSELECT 1"
  result <- parse_front_matter(text)

  expect_equal(attr(result, "fence_type"), "toml_sql_line")
  expect_equal(attr(result, "format"), "toml")
})

# SQL block comments - compact ----

test_that("SQL block comment compact YAML works", {
  text <- "/* ---\ntitle: Test\n--- */\n\nSELECT 1"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "SELECT 1")
})

test_that("SQL block comment compact TOML works", {
  text <- "/* +++\ntitle = \"Test\"\ncount = 42\n+++ */\n\nSELECT 1"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(result$data$count, 42)
  expect_equal(result$body, "SELECT 1")
})

test_that("SQL block comment compact with empty content works", {
  text <- "/* ---\n--- */\nSELECT 1"
  result <- parse_front_matter(text)

  expect_true(is.null(result$data))
  expect_equal(result$body, "SELECT 1")
})

test_that("SQL block comment compact multiline YAML with list works", {
  text <- "/* ---\ntitle: Test\ntags:\n  - sql\n  - analytics\n--- */\n\nSELECT 1"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(length(result$data$tags), 2)
  expect_equal(result$body, "SELECT 1")
})

test_that("SQL block comment compact front matter only works", {
  text <- "/* ---\ntitle: Test\n--- */"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "")
})

test_that("SQL block comment compact with CRLF works", {
  text <- "/* ---\r\ntitle: Test\r\n--- */\r\nSELECT 1"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "SELECT 1")
})

test_that("SQL block comment compact with trailing spaces on fences works", {
  text <- "/* ---   \ntitle: Test\n--- */   \nSELECT 1"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "SELECT 1")
})

test_that("SQL block comment compact fence_type attribute is yaml_sql_block_compact", {
  text <- "/* ---\ntitle: Test\n--- */\n\nSELECT 1"
  result <- parse_front_matter(text)

  expect_equal(attr(result, "fence_type"), "yaml_sql_block_compact")
  expect_equal(attr(result, "format"), "yaml")
})

test_that("SQL block comment compact TOML fence_type attribute is toml_sql_block_compact", {
  text <- "/* +++\ntitle = \"Test\"\n+++ */\n\nSELECT 1"
  result <- parse_front_matter(text)

  expect_equal(attr(result, "fence_type"), "toml_sql_block_compact")
  expect_equal(attr(result, "format"), "toml")
})

# SQL block comments - expanded ----

test_that("SQL block comment expanded YAML works", {
  text <- "/*\n---\ntitle: Test\n---\n*/\n\nSELECT 1"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "SELECT 1")
})

test_that("SQL block comment expanded TOML works", {
  text <- "/*\n+++\ntitle = \"Test\"\ncount = 42\n+++\n*/\n\nSELECT 1"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "Test")
  expect_equal(result$data$count, 42)
  expect_equal(result$body, "SELECT 1")
})

test_that("SQL block comment expanded with empty content works", {
  text <- "/*\n---\n---\n*/\nSELECT 1"
  result <- parse_front_matter(text)

  expect_true(is.null(result$data))
  expect_equal(result$body, "SELECT 1")
})

test_that("SQL block comment expanded front matter only works", {
  text <- "/*\n---\ntitle: Test\n---\n*/"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "")
})

test_that("SQL block comment expanded with CRLF works", {
  text <- "/*\r\n---\r\ntitle: Test\r\n---\r\n*/\r\nSELECT 1"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "SELECT 1")
})

test_that("SQL block comment expanded with indented */ closer works", {
  text <- "/*\n---\ntitle: Test\n---\n  */\n\nSELECT 1"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "Test")
  expect_equal(result$body, "SELECT 1")
})

test_that("SQL block comment expanded fence_type attribute is yaml_sql_block_expanded", {
  text <- "/*\n---\ntitle: Test\n---\n*/\n\nSELECT 1"
  result <- parse_front_matter(text)

  expect_equal(attr(result, "fence_type"), "yaml_sql_block_expanded")
  expect_equal(attr(result, "format"), "yaml")
})

test_that("SQL block comment expanded TOML fence_type attribute is toml_sql_block_expanded", {
  text <- "/*\n+++\ntitle = \"Test\"\n+++\n*/\n\nSELECT 1"
  result <- parse_front_matter(text)

  expect_equal(attr(result, "fence_type"), "toml_sql_block_expanded")
  expect_equal(attr(result, "format"), "toml")
})

# Symmetry enforcement ----

test_that("compact opener with expanded closer fails", {
  text <- "/* ---\ntitle: Test\n---\n*/\nSELECT 1"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("expanded opener with compact closer fails", {
  text <- "/*\n---\ntitle: Test\n--- */\nSELECT 1"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

# Edge cases ----

test_that("------ at position 0 does not match", {
  text <- "------\ntitle: Test\n------\nSELECT 1"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("/* without fence chars does not match", {
  text <- "/* \ntitle: Test\n*/\nSELECT 1"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("--- inside block comment content does not trigger false close", {
  text <- "/* ---\ntitle: Test\n---\nmore: value\n--- */\n\nSELECT 1"
  result <- parse_front_matter(text)

  expect_false(is.null(result$data))
  expect_equal(result$data$title, "Test")
})

test_that("/* ---- (4 dashes) does not match", {
  text <- "/* ----\ntitle: Test\n---- */\nSELECT 1"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

test_that("prefix mismatch: -- --- opener with # --- closer fails", {
  text <- "-- ---\n-- title: Test\n# ---\nSELECT 1"
  result <- parse_front_matter(text)

  expect_null(result$data)
  expect_equal(result$body, text)
})

# Write + roundtrip tests ----

test_that("write and roundtrip yaml_sql_line format", {
  tmp <- withr::local_tempfile(fileext = ".sql")

  fm <- list(
    data = list(title = "Test", author = "Me"),
    body = "SELECT * FROM sales"
  )

  expect_snapshot(write_front_matter(fm, delimiter = "yaml_sql_line"))

  write_front_matter(fm, tmp, delimiter = "yaml_sql_line")
  result <- read_front_matter(tmp)

  expect_equal(result$data$title, "Test")
  expect_equal(result$data$author, "Me")
  expect_equal(result$body, "SELECT * FROM sales")
})

test_that("write and roundtrip toml_sql_line format", {
  tmp <- withr::local_tempfile(fileext = ".sql")

  fm <- list(
    data = list(title = "Test", author = "Me"),
    body = "SELECT * FROM sales"
  )

  expect_snapshot(write_front_matter(fm, delimiter = "toml_sql_line"))

  write_front_matter(fm, tmp, delimiter = "toml_sql_line")
  result <- read_front_matter(tmp)

  expect_equal(result$data$title, "Test")
  expect_equal(result$data$author, "Me")
  expect_equal(result$body, "SELECT * FROM sales")
})

test_that("write and roundtrip yaml_sql_block_compact format", {
  tmp <- withr::local_tempfile(fileext = ".sql")

  fm <- list(
    data = list(title = "Test", author = "Me"),
    body = "SELECT * FROM sales"
  )

  expect_snapshot(write_front_matter(fm, delimiter = "yaml_sql_block_compact"))

  write_front_matter(fm, tmp, delimiter = "yaml_sql_block_compact")
  result <- read_front_matter(tmp)

  expect_equal(result$data$title, "Test")
  expect_equal(result$data$author, "Me")
  expect_equal(result$body, "SELECT * FROM sales")
})

test_that("write and roundtrip toml_sql_block_compact format", {
  tmp <- withr::local_tempfile(fileext = ".sql")

  fm <- list(
    data = list(title = "Test", author = "Me"),
    body = "SELECT * FROM sales"
  )

  expect_snapshot(write_front_matter(fm, delimiter = "toml_sql_block_compact"))

  write_front_matter(fm, tmp, delimiter = "toml_sql_block_compact")
  result <- read_front_matter(tmp)

  expect_equal(result$data$title, "Test")
  expect_equal(result$data$author, "Me")
  expect_equal(result$body, "SELECT * FROM sales")
})

test_that("write and roundtrip yaml_sql_block_expanded format", {
  tmp <- withr::local_tempfile(fileext = ".sql")

  fm <- list(
    data = list(title = "Test", author = "Me"),
    body = "SELECT * FROM sales"
  )

  expect_snapshot(write_front_matter(fm, delimiter = "yaml_sql_block_expanded"))

  write_front_matter(fm, tmp, delimiter = "yaml_sql_block_expanded")
  result <- read_front_matter(tmp)

  expect_equal(result$data$title, "Test")
  expect_equal(result$data$author, "Me")
  expect_equal(result$body, "SELECT * FROM sales")
})

test_that("write and roundtrip toml_sql_block_expanded format", {
  tmp <- withr::local_tempfile(fileext = ".sql")

  fm <- list(
    data = list(title = "Test", author = "Me"),
    body = "SELECT * FROM sales"
  )

  expect_snapshot(write_front_matter(fm, delimiter = "toml_sql_block_expanded"))

  write_front_matter(fm, tmp, delimiter = "toml_sql_block_expanded")
  result <- read_front_matter(tmp)

  expect_equal(result$data$title, "Test")
  expect_equal(result$data$author, "Me")
  expect_equal(result$body, "SELECT * FROM sales")
})
