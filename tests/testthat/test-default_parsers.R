test_that("YAML 1.1 option uses yaml package", {
  skip_if_not_installed("yaml")

  # YAML 1.1 treats 'yes' as boolean TRUE, YAML 1.2 treats it as string "yes"
  text <- "---\nvalue: yes\n---\nBody"

  withr::with_options(
    list(frontmatter.parse_yaml.spec = "1.1"),
    {
      result <- parse_front_matter(text)
      expect_true(result$data$value)
    }
  )
})

test_that("YAML 1.2 option uses yaml12 package", {
  skip_if_not_installed("yaml12")

  # YAML 1.2 treats 'yes' as string "yes"
  text <- "---\nvalue: yes\n---\nBody"

  withr::with_options(
    list(frontmatter.parse_yaml.spec = "1.2"),
    {
      result <- parse_front_matter(text)
      expect_equal(result$data$value, "yes")
    }
  )
})

test_that("YAML spec envvar works when option not set", {
  skip_if_not_installed("yaml")

  text <- "---\nvalue: yes\n---\nBody"

  withr::with_options(
    list(frontmatter.parse_yaml.spec = NULL),
    withr::with_envvar(
      c(FRONTMATTER_PARSE_YAML_SPEC = "1.1"),
      {
        result <- parse_front_matter(text)
        expect_true(result$data$value)
      }
    )
  )
})

test_that("YAML spec option takes precedence over envvar", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("yaml12")

  text <- "---\nvalue: yes\n---\nBody"

  # Option set to 1.2, envvar set to 1.1 - option should win
  withr::with_options(
    list(frontmatter.parse_yaml.spec = "1.2"),
    withr::with_envvar(
      c(FRONTMATTER_PARSE_YAML_SPEC = "1.1"),
      {
        result <- parse_front_matter(text)
        expect_equal(result$data$value, "yes")
      }
    )
  )
})

test_that("invalid YAML spec value errors", {
  text <- "---\nvalue: test\n---\nBody"

  withr::with_options(
    list(frontmatter.parse_yaml.spec = "invalid"),
    {
      expect_error(parse_front_matter(text), "1.1.*1.2")
    }
  )
})
