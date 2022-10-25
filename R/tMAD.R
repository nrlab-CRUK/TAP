#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(optparse))

option_list <- list(

  make_option(c("--input"), dest = "input_file",
              help = "Input tab-delimited file containing segmented copy number data for one or more samples"),

  make_option(c("--output"), dest = "output_file",
              help = "Output file to which tMAD score(s) will be written"),

  make_option(c("--max_log_ratio"), dest = "max_log_ratio", type = "double",
              help = "The maximum absolute log ratio to include in the tMAD calculation (optional)"),

  make_option(c("--sample_column"), dest = "sample_column", default = "sample",
              help = "The column containing the sample identifier"),

  make_option(c("--segmented_column"), dest = "segmented_column", default = "segmented",
              help = "The column containing segmented log ratio values"),

  make_option(c("--bin_count_column"), dest = "bin_count_column",
              help = "The column containing the number of bins for each segment (optional)"
  )
)

option_parser <- OptionParser(usage = "usage: %prog [options]", option_list = option_list, add_help_option = TRUE)
opt <- parse_args(option_parser)

input_file <- opt$input_file
output_file <- opt$output_file
max_log_ratio <- opt$max_log_ratio
sample_column <- opt$sample_column
segmented_column <- opt$segmented_column
bin_count_column <- opt$bin_count_column

if (is.null(input_file)) stop("Input copy number file must be specified")
if (is.null(output_file)) stop("Output copy number file must be specified")

suppressPackageStartupMessages(library(tidyverse))

copy_number_data <- read_tsv(input_file, show_col_types = FALSE)

if (!sample_column %in% colnames(copy_number_data)) {
  stop("Input file does not contain the sample column: ", sample_column)
}
if (!segmented_column %in% colnames(copy_number_data)) {
  stop("Input file does not contain the segmented log ratio column: ", segmented_column)
}

if (is.null(bin_count_column)) {
  copy_number_data <- select(copy_number_data, all_of(c(sample_column, segmented_column)))
  colnames(copy_number_data) <- c("sample", "segmented")
  copy_number_data <- mutate(copy_number_data, bins = 1)
} else {
  if (!bin_count_column %in% colnames(copy_number_data)) {
    stop("Input file does not contain the bin count column: ", bin_count_column)
  }
  copy_number_data <- select(copy_number_data, all_of(c(sample_column, segmented_column, bin_count_column)))
  colnames(copy_number_data) <- c("sample", "segmented", "bins")
}

if (!is.numeric(copy_number_data$segmented)) {
  stop("Segmented log ratio column contains non-numeric values")
}

if (!is.numeric(copy_number_data$bins)) {
  stop("Bin count column contains non-numeric values")
}

copy_number_data <- mutate(copy_number_data, sample = as_factor(sample))

if (!is.null(max_log_ratio)) {
  copy_number_data <- mutate(copy_number_data, segmented = ifelse(abs(segmented) > max_log_ratio, NA, segmented))
}

tmad_scores <- copy_number_data %>%
  group_by(sample) %>%
  summarize(tmad = mad(rep.int(segmented, bins), center = 0, na.rm = TRUE))

tmad_scores %>%
  mutate(tmad = round(tmad, digits = 4)) %>%
  mutate(tmad = ifelse(is.na(tmad), NA, format(tmad, scientific = FALSE))) %>%
  rename(Sample = sample, tMAD = tmad) %>%
  write_tsv(output_file, na = "")

