#!/usr/bin/env Rscript
# Run inside the built Docker image to verify install and tests.
# Working directory in the container is the package root (/code).

# Install this package from source (dependencies already in image)
install.packages(".", repos = NULL, type = "source")

# Run the test suite
source("tests/testthat.R")
