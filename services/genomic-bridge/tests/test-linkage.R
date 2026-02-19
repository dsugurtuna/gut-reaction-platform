library(testthat)
library(dplyr)
library(tibble)
library(checkmate)

# ---------------------------------------------------------------------------
# Test: Linkage join logic
# ---------------------------------------------------------------------------

test_that("inner join correctly links clinical and bridge data", {
  clinical <- tibble::tibble(
    patient_id       = c("P001", "P002", "P003"),
    recruitment_site = c("Site_A", "Site_B", "Site_A")
  )

  bridge <- tibble::tibble(
    patient_id      = c("P001", "P002", "P004"),
    sanger_sample_id = c("SANGER_001", "SANGER_002", "SANGER_004")
  )

  linked <- clinical %>%
    dplyr::inner_join(bridge, by = "patient_id") %>%
    dplyr::filter(!is.na(sanger_sample_id))

  # Only P001 and P002 should match

  expect_equal(nrow(linked), 2)
  expect_setequal(linked$patient_id, c("P001", "P002"))
  expect_true("sanger_sample_id" %in% names(linked))
})

test_that("unmatched patients are dropped after linkage", {
  clinical <- tibble::tibble(
    patient_id       = c("P010", "P020"),
    recruitment_site = c("Site_X", "Site_Y")
  )

  bridge <- tibble::tibble(
    patient_id      = c("P020"),
    sanger_sample_id = c("SANGER_020")
  )

  linked <- clinical %>%
    dplyr::inner_join(bridge, by = "patient_id") %>%
    dplyr::filter(!is.na(sanger_sample_id))

  expect_equal(nrow(linked), 1)
  expect_equal(linked$patient_id, "P020")
})

# ---------------------------------------------------------------------------
# Test: QC filter logic
# ---------------------------------------------------------------------------

test_that("QC filter removes failing samples", {
  samples <- tibble::tibble(
    sanger_sample_id  = c("S1", "S2", "S3", "S4"),
    qc_status         = c("PASS", "PASS", "FAIL", "PASS"),
    contamination_rate = c(0.01, 0.06, 0.02, 0.03),
    has_wes           = c(TRUE, TRUE, TRUE, FALSE),
    has_snp           = c(FALSE, FALSE, FALSE, FALSE)
  )

  valid <- samples %>%
    dplyr::filter(
      qc_status == "PASS" &
      contamination_rate < 0.05 &
      (has_wes | has_snp)
    )

  # S1: PASS, low contam, has_wes  -> valid
  # S2: PASS, high contam          -> invalid
  # S3: FAIL                       -> invalid
  # S4: PASS, low contam, no data  -> invalid
  expect_equal(nrow(valid), 1)
  expect_equal(valid$sanger_sample_id, "S1")
})

# ---------------------------------------------------------------------------
# Test: Input schema validation via checkmate
# ---------------------------------------------------------------------------

test_that("required columns are detected by checkmate", {
  df <- tibble::tibble(patient_id = "P1", recruitment_site = "A")
  expect_true(test_subset(c("patient_id", "recruitment_site"), names(df)))

  df_bad <- tibble::tibble(id = "P1")
  expect_false(test_subset(c("patient_id", "recruitment_site"), names(df_bad)))
})
