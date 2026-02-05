#!/usr/bin/env Rscript
# Run inside the built Docker image to verify install and tests.
# Ensure we are in the package root (script lives at tests/build_test.R).
this_file <- sub("^--file=", "", commandArgs(trailingOnly = FALSE)[grep("^--file=", commandArgs(trailingOnly = FALSE))])
if (length(this_file)) setwd(dirname(dirname(normalizePath(this_file))))

# Install this package from source (dependencies already in image)
install.packages(".", repos = NULL, type = "source")

# Run tests from source tree (test_check() looks in installed pkg, which has no tests/)
testthat::test_local()
