#' Read ASCII file using SPSS Setup file.
#'
#' spss_ascii_reader() and sas_ascii_reader() are used when you need to
#' read an fixed-width ASCII (text) file that comes with a setup file.
#' The setup file provides instructions on how to create and name the columns,
#' and fix the key-value pairs (sometimes called value labels). This is common
#' in government data, particular data produced before 2010.
#'
#' @family ASCII Reader functions
#' @seealso \code{\link{sas_ascii_reader}} For using an SAS setup file
#'
#' @param dataset_name Name of the ASCII (.txt) file that contains the data.
#'   This file may be zipped with a file extention of .zip.
#' @param sps_name Name of the SPSS Setup file - should be a .sps or .txt
#'   (zipped text files also work) file.
#' @param value_label_fix If TRUE, fixes value labels of the data. e.g. If a
#'   column is "sex" and has values of 0 or 1, and the setup file says 0 = male
#'   and 1 = female, it will make that change. The reader is much faster is this
#'    parameter is FALSE.
#' @param real_names If TRUE fixes column names from default column name in the
#'   SPSS setup file (e.g. V1, V2) to the name is says the column is called
#'   (e.g. age, sex, etc.).
#' @param keep_columns Specify which columns from the dataset you want. If
#'   NULL, will return all columns. Accepts the column number (e.g. 1:5),
#'   column name (e.g. V1, V2, etc.) or column label (e.g. VICTIM_NAME, CITY,
#'   etc.).
#' @param ...
#' further arguments passed to readr
#' @return Data.frame of the data from the ASCII file
#' @export
#' @examples
#' # Text file is zipped to save space.
#' dataset_name <- system.file("extdata", "example_data.zip",
#'   package = "asciiSetupReader")
#' sps_name <- system.file("extdata", "example_setup.sps",
#'   package = "asciiSetupReader")
#'
#' \dontrun{
#' example <- spss_ascii_reader(dataset_name = dataset_name,
#'   sps_name = sps_name)
#' }
#'
#' # Does not fix value labels
#' example2 <- spss_ascii_reader(dataset_name = dataset_name,
#'   sps_name = sps_name, value_label_fix = FALSE)
#'
#' # Keeps original column names
#' example3 <- spss_ascii_reader(dataset_name = dataset_name,
#'   sps_name = sps_name, real_names = FALSE)
#'
#' # Only returns the first 5 columns
#' example4 <- spss_ascii_reader(dataset_name = dataset_name,
#'   sps_name = sps_name, keep_columns = 1:5)
spss_ascii_reader <- function(dataset_name,
                              sps_name,
                              value_label_fix = TRUE,
                              real_names = TRUE,
                              keep_columns = NULL,
                              ...) {

    stopifnot(is.character(dataset_name), length(dataset_name) == 1,
              is.character(sps_name), length(sps_name) == 1,
              is.logical(value_label_fix), length(value_label_fix) == 1,
              is.logical(real_names), length(real_names) == 1)

  setup <- parse_spss(sps_name,
                      keep_columns = keep_columns,
                      value_label_fix = value_label_fix)

  dataset <- read_data(dataset_name, setup, ...)
  dataset <- data.table::as.data.table(dataset)
  column_order <- names(dataset)

  # Value Labels ------------------------------------------------------------
      # Removes columns not asked for
    value_labels <- parse_value_labels(setup)

    if (value_label_fix && length(value_labels) > 0) {
      for (i in seq_along(value_labels)) {
        dataset <- fix_variable_values(dataset,
                                       value_labels[[i]],
                                       names(value_labels)[i])
      }
      data.table::setcolorder(dataset, column_order)
    }


    # Fixes missing values ----------------------------------------------------
    missing <- setup$missing
    if (!is.null(missing)) {
      dataset <- fix_missing(dataset, missing)
    }

    if (real_names) {
      # Fixes column names to real names
      codebook_variables <- setup$setup[setup$setup$column_number
                                               %in% names(dataset), ]
      data.table::setnames(dataset, old = codebook_variables$column_number,
                           new = codebook_variables$column_name)

    }


    # Makes columns that should be numeric numeric
    dataset <- make_cols_numeric(dataset)
    attributes(dataset)$spec <- NULL
    dataset <- as.data.frame(dataset)
  return(dataset)
}
