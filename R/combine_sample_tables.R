#!/usr/bin/env Rscript

args <- commandArgs(trailing=TRUE)
if (length(args) < 2)
{
  stop('Usage: Rscript combine_sample_tables.R file1 file2 ...')
}

suppressPackageStartupMessages(library(tidyverse))

combined <- NULL

for (file in args) {
  data <- read_tsv(file, col_types = cols(.default = col_character()))
  if (!"Sample" %in% colnames(data)) {
    stop(file, " does not contain a column named 'Sample'")
  }
  if (is.null(combined)) {
    combined <- data
  } else {
    combined <- left_join(combined, data, by = "Sample")
  }
}

combined %>%
  arrange(Sample) %>%
  format_tsv(na = "") %>%
  cat()

