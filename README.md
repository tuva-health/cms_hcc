# CMS HCC

dbt package for the Tuva Project CMS HCC, HCC recapture, and HCC suspecting data marts.

## Dependencies

`packages.yml` declares Tuva Core at an immutable pre-1.0 commit and
`dbt_utils` for the package's generic tests. Run `dbt deps` before parsing or
building this package. The Core pin will move to the released 1.0 version
range as part of release preparation.

## Official-reference validation

Pull requests run a credential-free DuckDB build of a beneficiary-and-
diagnosis fixture through the real CMS HCC graph. Expected V28 factors and raw
scores were generated with CMS's 2026 midyear/final Python model software and
are recorded with the source URL and archive checksum under
`integration_tests/fixtures/official_cms_2026_v28`.

## Open-ended eligibility spans

Tuva Core represents an enrollment span with no known end date using a null
`enrollment_end_date`. CMS HCC treats that span as active and caps it to the
applicable payment-year boundary when calculating coverage months. Fully
refresh the CMS HCC models when upgrading so active enrollment spans are
included in member and enrollment-status calculations.

## Data assets

Seed contents are stored under
`s3://tuva-public-resources/data-marts/cms-hcc/<asset-version>/` and mirrored
to GCS and Azure. The checked-in CSV files contain only the headers required
by dbt.

`cms_hcc_data_asset_version` selects the folder and defaults to `1.0.0`.
Package code and data assets are versioned independently and are coordinated
manually. Cloud manifests record the asset inventory, provenance, and release
status; dbt loads the configured path without reading them.
