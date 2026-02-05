# Skip all tests in these files if omock is not installed
if (!requireNamespace("omock", quietly = TRUE)) {
  skip("omock is not installed")
}
