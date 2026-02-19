library(testthat)
library(tidyverse)
library(checkmate)

# ---------------------------------------------------------------------------
# Test: Drug-name standardisation regex logic
# ---------------------------------------------------------------------------

# Replicate the regex mapping from trust_data_harmonizer.R so we can
# validate it without sourcing the whole file (which depends on readxl).

standardise_drug <- function(drug) {
  dplyr::case_when(
    stringr::str_detect(drug, stringr::regex("inflix|remicade", ignore_case = TRUE)) ~ "Infliximab",
    stringr::str_detect(drug, stringr::regex("adali|humira",   ignore_case = TRUE)) ~ "Adalimumab",
    stringr::str_detect(drug, stringr::regex("vedo|entyvio",   ignore_case = TRUE)) ~ "Vedolizumab",
    stringr::str_detect(drug, stringr::regex("uste|stelara",   ignore_case = TRUE)) ~ "Ustekinumab",
    TRUE ~ "Other"
  )
}

test_that("drug names are correctly standardised", {
  expect_equal(standardise_drug("Infliximab 100mg"),  "Infliximab")
  expect_equal(standardise_drug("Remicade IV"),       "Infliximab")
  expect_equal(standardise_drug("Adalimumab SC"),     "Adalimumab")
  expect_equal(standardise_drug("Humira Pen"),        "Adalimumab")
  expect_equal(standardise_drug("Vedolizumab 300mg"), "Vedolizumab")
  expect_equal(standardise_drug("Entyvio Infusion"),  "Vedolizumab")
  expect_equal(standardise_drug("Ustekinumab"),       "Ustekinumab")
  expect_equal(standardise_drug("Stelara 45mg"),      "Ustekinumab")
  expect_equal(standardise_drug("Paracetamol"),       "Other")
})

test_that("drug matching is case-insensitive", {
  expect_equal(standardise_drug("INFLIXIMAB"),  "Infliximab")
  expect_equal(standardise_drug("humira"),      "Adalimumab")
  expect_equal(standardise_drug("ENTYVIO"),     "Vedolizumab")
  expect_equal(standardise_drug("stelara"),     "Ustekinumab")
})

# ---------------------------------------------------------------------------
# Test: Data-quality flags
# ---------------------------------------------------------------------------

test_that("date parsing succeeds for expected formats", {
  expect_false(is.na(lubridate::parse_date_time("01-06-2021", orders = c("dmy", "ymd", "mdy"))))
  expect_false(is.na(lubridate::parse_date_time("2021-06-01", orders = c("dmy", "ymd", "mdy"))))
  expect_true(is.na(lubridate::parse_date_time("not-a-date",  orders = c("dmy", "ymd", "mdy"), quiet = TRUE)))
})

# ---------------------------------------------------------------------------
# Test: trust_id validation
# ---------------------------------------------------------------------------

test_that("only allowed trust IDs pass checkmate assertion", {
  valid_trusts <- c("CAMBS", "LEEDS", "MANCH", "LPOOL")
  expect_true(test_choice("CAMBS", valid_trusts))
  expect_true(test_choice("LEEDS", valid_trusts))
  expect_false(test_choice("INVALID", valid_trusts))
})
