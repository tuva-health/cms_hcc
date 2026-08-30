# CMS HCC

dbt package for the Tuva Project CMS HCC, HCC recapture, and HCC suspecting data marts.

## Dependencies

`packages.yml` declares the two packages this one calls into:

- `the_tuva_project` (tuva-core) — cross-database macros (`concat_custom`,
  `date_part`, `is_numeric_string`, `limit_zero`, `load_package_seed`,
  `substring`, `try_to_cast_date`, `try_to_cast_datetime`) plus the `core__*`
  models and `terminology__*` seeds these marts read from.
- `dbt-labs/dbt_utils` — the `dbt_utils.unique_combination_of_columns`
  generic test used across the model and seed schema files.

## Enablement

Every model in this package is disabled by default and is gated on Tuva Core's
domain flags:

| Mart | Gating var |
| --- | --- |
| `cms_hcc` | `claims_enabled` |
| `hcc_recapture` | `claims_enabled` |
| `hcc_suspecting` | `claims_enabled` **or** `clinical_enabled` |

Set the relevant flag in your root `dbt_project.yml`:

```yaml
vars:
  claims_enabled: true
  clinical_enabled: true
```

If the package is installed but every one of its models is disabled, the
`on-run-start` hook `cms_hcc.assert_cms_hcc_enabled()` fails the run rather
than letting it finish having built nothing. It reports the resolved value of
each flag. The hook does not fire during `dbt parse` or `dbt deps`. To install
the package without building it, set
`vars: {cms_hcc_suppress_enablement_check: true}`.

## Optional consumer-supplied models

Two `hcc_recapture` staging models are override hooks. They are disabled by
default; enabling the corresponding var means **you must supply a model (or
seed) of the named name in your own project**, because this package does not
ship one.

| Var (default `false`) | Model you must supply | Consumed by |
| --- | --- | --- |
| `hcc_recapture_chronic_hccs` | `chronic_hccs` | `hcc_recapture__stg_chronic_hccs` |
| `hcc_recapture_suspect_list` | `suspect_hccs` | `hcc_recapture__stg_suspect_hccs` |

- `hcc_recapture_chronic_hccs` — when `false` (the default),
  `hcc_recapture__stg_chronic_hccs` reads the package-owned seed
  `hcc_recapture__chronic_hccs`. When `true` it reads `ref('chronic_hccs')`
  instead. Required columns: `hcc_code`, `model_version`, `chronic_flag`.
- `hcc_recapture_suspect_list` — when `false` (the default),
  `hcc_recapture__stg_suspect_hccs` is disabled entirely and
  `hcc_recapture__int_suspect_hccs` omits the union against it. When `true`,
  `hcc_recapture__stg_suspect_hccs` is enabled and reads
  `ref('suspect_hccs')`. Required columns: `person_id`, `payer`,
  `data_source`, `recorded_date`, `model_version`, `claim_id`, `hcc_code`,
  `hcc_description`, `suspect_hcc_flag`, `eligible_claim_flag`, `reason`,
  `hcc_type`, `hcc_source`.

Neither `ref()` is reachable with the default variable values, so leaving both
vars unset requires no extra models.

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
`main`, release automation verifies the exact, commit-bound, byte-identical
`_release.json` receipt in S3, GCS, and Azure before creating the
`v<package-version>` tag and draft GitHub release.
