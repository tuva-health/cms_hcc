# CMS HCC

dbt package for the Tuva Project CMS HCC, HCC recapture, and HCC suspecting data marts.

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
