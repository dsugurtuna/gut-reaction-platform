library(testthat)
library(dplyr)
library(stringr)
library(checkmate)

# The rules the service uses (trust_data_harmonizer.R sources the same file).
# testthat runs this file with the tests/ directory as the working directory.
source(file.path("..", "harmonizer_rules.R"))

# ---------------------------------------------------------------------------
# Test: Drug-name standardisation regex logic
# ---------------------------------------------------------------------------

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
  # Use base R date parsing to avoid extra dependency
  expect_false(is.na(as.Date("01-06-2021", format = "%d-%m-%Y")))
  expect_false(is.na(as.Date("2021-06-01", format = "%Y-%m-%d")))
  expect_true(is.na(as.Date("not-a-date", format = "%Y-%m-%d")))
})

# ---------------------------------------------------------------------------
# Test: trust_id validation
# ---------------------------------------------------------------------------

test_that("only allowed trust IDs pass checkmate assertion", {
  expect_true(test_choice("CAMBS", VALID_TRUST_IDS))
  expect_true(test_choice("LEEDS", VALID_TRUST_IDS))
  expect_false(test_choice("INVALID", VALID_TRUST_IDS))
})

test_that("column names are normalised", {
  expect_equal(normalise_column_names(c("Patient ID", "Rx Date", "drug")),
               c("patient_id", "rx_date", "drug"))
})

test_that("vectorised drug mapping keeps length and order", {
  expect_equal(standardise_drug(c("Entyvio", "aspirin", "REMICADE")),
               c("Vedolizumab", "Other", "Infliximab"))
})
