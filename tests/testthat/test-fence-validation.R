test_that("YAML fence detection works", {
  result <- extract_front_matter_cpp("---\nyaml\n---\nBody")
  expect_true(result$found)
  expect_equal(result$fence_type, "yaml")
  expect_equal(result$content, "yaml\n")
  expect_equal(result$body, "Body")
})

test_that("TOML fence detection works", {
  result <- extract_front_matter_cpp("+++\ntoml\n+++\nBody")
  expect_true(result$found)
  expect_equal(result$fence_type, "toml")
  expect_equal(result$content, "toml\n")
  expect_equal(result$body, "Body")
})

test_that("no front matter returns original content", {
  input <- "Just content\n"
  result <- extract_front_matter_cpp(input)
  expect_false(result$found)
  expect_equal(result$fence_type, "none")
  expect_equal(result$content, "")
  expect_equal(result$body, input)
})

test_that("invalid opening fence character returns no front matter", {
  input <- ">>>\ninvalid\n>>>\nRest of document\n"
  result <- extract_front_matter_cpp(input)
  expect_false(result$found)
  expect_equal(result$body, input)
})

test_that("trailing characters after opening fence invalidates it", {
  input <- "---invalid\ninvalid\n---\nRest of document\n"
  result <- extract_front_matter_cpp(input)
  expect_false(result$found)
  expect_equal(result$body, input)
})

test_that("indented opening fence is invalid", {
  input <- " ---\nyaml\n---\nRest of document\n"
  result <- extract_front_matter_cpp(input)
  expect_false(result$found)
  expect_equal(result$body, input)
})

test_that("opening fence on second line is invalid", {
  input <- "\n---\nyaml\n---\nRest of document\n"
  result <- extract_front_matter_cpp(input)
  expect_false(result$found)
  expect_equal(result$body, input)
})

test_that("indented closing fence is invalid", {
  input <- "---\nyaml\n ---\nRest of document\n"
  result <- extract_front_matter_cpp(input)
  expect_false(result$found)
  expect_equal(result$body, input)
})

test_that("4-character closing fence is invalid", {
  input <- "---\nyaml\n----\nRest of document\n"
  result <- extract_front_matter_cpp(input)
  expect_false(result$found)
  expect_equal(result$body, input)
})

test_that("5-character closing fence is invalid", {
  input <- "---\nyaml\n-----\nRest of document\n"
  result <- extract_front_matter_cpp(input)
  expect_false(result$found)
  expect_equal(result$body, input)
})

test_that("6-character closing fence is invalid", {
  input <- "---\nyaml\n------\nRest of document\n"
  result <- extract_front_matter_cpp(input)
  expect_false(result$found)
  expect_equal(result$body, input)
})

test_that("CRLF line endings work", {
  input <- "---\r\nyaml\r\n---\r\nRest of document\r\n"
  result <- extract_front_matter_cpp(input)
  expect_true(result$found)
  expect_equal(result$fence_type, "yaml")
  expect_equal(result$content, "yaml\r\n")
  expect_equal(result$body, "Rest of document\r\n")
})

test_that("trailing space on opening fence is allowed", {
  input <- "---    \nyaml\n---\nRest of document\n"
  result <- extract_front_matter_cpp(input)
  expect_true(result$found)
  expect_equal(result$content, "yaml\n")
})

test_that("trailing space on closing fence is allowed", {
  input <- "---\nyaml\n---      \nRest of document\n"
  result <- extract_front_matter_cpp(input)
  expect_true(result$found)
  expect_equal(result$content, "yaml\n")
})

test_that("document ends after opening fence", {
  input <- "---"
  result <- extract_front_matter_cpp(input)
  expect_false(result$found)
  expect_equal(result$body, input)
})

test_that("document ends after closing fence with no newline", {
  input <- "---\nyaml\n---"
  result <- extract_front_matter_cpp(input)
  expect_true(result$found)
  expect_equal(result$content, "yaml\n")
  expect_equal(result$body, "")
})

test_that("missing closing fence", {
  input <- "---\nRest of document\n"
  result <- extract_front_matter_cpp(input)
  expect_false(result$found)
  expect_equal(result$body, input)
})

test_that("empty front matter section", {
  input <- "---\n---\nContent"
  result <- extract_front_matter_cpp(input)
  expect_true(result$found)
  expect_equal(result$content, "")
  expect_equal(result$body, "Content")
})

test_that("multiple potential closing fences uses first valid one", {
  input <- "---\nyaml\n----\n---\nContent"
  result <- extract_front_matter_cpp(input)
  expect_true(result$found)
  expect_equal(result$content, "yaml\n----\n")
  expect_equal(result$body, "Content")
})

test_that("leading empty lines in body are trimmed", {
  input <- "---\nyaml\n---\n\n   Content with leading whitespace"
  result <- extract_front_matter_cpp(input)
  expect_true(result$found)
  expect_equal(result$body, "   Content with leading whitespace")
})

test_that("empty string returns no front matter", {
  result <- extract_front_matter_cpp("")
  expect_false(result$found)
  expect_equal(result$body, "")
})

test_that("mismatched fence types don't match", {
  input <- "---\ncontent\n+++\nBody"
  result <- extract_front_matter_cpp(input)
  expect_false(result$found)
  expect_equal(result$body, input)
})

test_that("TOML fence doesn't close YAML and vice versa", {
  input <- "+++\ncontent\n---\nBody"
  result <- extract_front_matter_cpp(input)
  expect_false(result$found)
  expect_equal(result$body, input)
})
