parse_spss <- function(sps_name, keep_columns = NULL) {

  codebook <- parse_codebook(sps_name)

  # Get the column names
  variables <- codebook[grep2("^variable labels$", codebook):
                          grep2("^value labels$|missing values",
                                codebook)[1]]
  variables <- gsub("\\'\\'", "\\'", variables)
  variables <- gsub("( \\'[[:alnum:]])\\'([[:alnum:]])", "\\1\\2",
                    variables)
  variables <- gsub("\'", "\"", variables)
  variables <- data.frame(column_name = fix_names(variables),
                          column_number = gsub(" .*", "",
                                               variables),
                          stringsAsFactors = FALSE)

  setup <- codebook[grep2("DATA LIST", codebook):
                      grep2("^variable labels$", codebook)]
  setup <- gsub("([[:alpha:]]+[0-9]*)\\s+", "\\1 ",
                setup)
  setup <- get_column_spaces(setup, variables)
  setup <- selected_columns(keep_columns, setup)

  if (any(grepl("MISSING VALUES", codebook))) {
    missing <- parse_missing(codebook)
    missing <- missing[missing$variable %in% setup$column_number, ]
  } else missing <- NULL

  value_labels <- get_value_labels(codebook, setup)


  setup <- setNames(list(setup, value_labels, missing), c("setup",
                                            "value_labels",
                                            "missing"))

  return(setup)

}


parse_missing <- function(codebook) {

  missing <- codebook[grep("MISSING VALUES$", codebook):length(codebook)]
  missing <- unlist(strsplit(missing, ",|\\s{2,}"))

  missing <- data.frame(variable = gsub(" .*", "", missing),
                        values = gsub(".*\\(|\\).*", "", missing),
                        stringsAsFactors = FALSE)
  missing$variable[missing$variable == ""] <- NA
  missing$variable <- zoo::na.locf(missing$variable, na.rm = FALSE)
  missing$values <- gsub("\\.$", "", missing$values)
  missing$values <- gsub('\\"', "\\'", missing$values)
  return(missing)
}

parse_codebook <- function(sps_name) {
  codebook <- readr::read_lines(sps_name)
  codebook <- stringr::str_trim(codebook)
  codebook <- codebook[-c(1:(grep2("^DATA LIST", codebook) - 1))]
  return(codebook)
}