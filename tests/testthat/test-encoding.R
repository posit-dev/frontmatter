test_that("read_front_matter handles UTF-8 with multibyte characters", {
  skip_if_not_installed("yaml12")

  path <- test_path("fixtures", "yaml-utf8.md")
  result <- read_front_matter(path)

  expect_equal(result$data$title, "Test mit Umlauten: äöü")
  expect_equal(result$data$author, "日本語テスト")
  expect_true(grepl("Héllo Wörld 你好", result$body))
})

test_that("read_front_matter strips UTF-8 BOM", {
  skip_if_not_installed("yaml12")

  path <- test_path("fixtures", "yaml-utf8-bom.md")
  result <- read_front_matter(path)

  # BOM should be stripped, allowing front matter detection

  expect_equal(result$data$title, "BOM Test")
  expect_equal(result$body, "Content after BOM")
})

test_that("read_front_matter handles CRLF line endings", {
  skip_if_not_installed("yaml12")

  path <- test_path("fixtures", "yaml-crlf.md")
  result <- read_front_matter(path)

  expect_equal(result$data$title, "CRLF Test")
  expect_equal(result$body, "Content with CRLF")
})

test_that("read_front_matter handles file without front matter", {
  path <- test_path("fixtures", "no-frontmatter.txt")
  result <- read_front_matter(path)

  expect_null(result$data)
  expect_true(grepl("plain text file", result$body))
})

test_that("read_front_matter handles empty file", {
  path <- test_path("fixtures", "empty.txt")
  result <- read_front_matter(path)

  expect_null(result$data)
  expect_equal(result$body, "")
})

test_that("parse_front_matter handles UTF-8 multibyte in content", {
  skip_if_not_installed("yaml12")

  text <- "---\ntitle: \"日本語\"\n---\n\nBody: 中文内容"
  result <- parse_front_matter(text)

  expect_equal(result$data$title, "日本語")
  expect_equal(result$body, "Body: 中文内容")
})
