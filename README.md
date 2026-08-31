# CMS HCC

dbt package for the Tuva Project CMS HCC, HCC recapture, and HCC suspecting data marts.

## Open-ended eligibility spans

Tuva Core represents an enrollment span with no known end date using a null
`enrollment_end_date`. CMS HCC treats that span as active and caps it to the
applicable payment-year boundary when calculating coverage months. Fully
refresh the CMS HCC models when upgrading so active enrollment spans are
included in member and enrollment-status calculations.

## Data assets

Released seed contents are stored as an immutable snapshot under
`s3://tuva-public-resources/cms-hcc/<package-version>/`. The checked-in CSV
files define the dbt loader headers, and `data_assets.yml` is the publisher
inventory. Dataset changes are released with a new package version.

On a version-changing push to `main`, or a manual recovery from current
`main`, release automation verifies that every path in `data_assets.yml`
exists under the package-version folder in S3, GCS, and Azure before creating
the `v<package-version>` tag and draft GitHub release. Each package version
maps directly to its public data-asset folder.
