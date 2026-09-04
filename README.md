# CMS HCC

`cms_hcc` is the Tuva Project dbt package for CMS Hierarchical Condition
Category risk adjustment, HCC recapture, and HCC suspecting. It runs on the
standardized relations produced by Tuva Core and keeps patient and payer
identities scoped by `data_source`.

## What this package produces

The package contains three related marts:

- `cms_hcc` calculates annual and monthly patient risk factors and risk scores,
  including demographic, disease, interaction, and HCC-count factors.
- `hcc_recapture` identifies open and closed HCC gaps and calculates annual,
  monthly, and year-to-date recapture rates.
- `hcc_suspecting` produces patient-level suspect lists and summaries from
  diagnoses, medications, labs, observations, and prior coding history.

The principal public outputs include `patient_risk_factors`,
`patient_risk_scores`, `gap_status`, `hcc_status`, `recapture_rates`, `list`,
`list_rollup`, and `summary`. Complete model and column definitions live in
the YAML files beside the models.

## Prerequisites and dependency ownership

This package requires dbt `>=1.10.5,<3.0.0` and a Tuva connector or other root
dbt project that installs a compatible Tuva Core revision and produces the
required Core relations. The root project owns the Tuva Core version so that one
dependency graph controls the shared Core installation. For that reason, this
package intentionally does not declare Tuva Core in its own `packages.yml`.

`dbt_utils` is a direct package dependency because CMS HCC models and tests use
its macros. It is declared here and will be resolved automatically by
`dbt deps`.

## Installation

Once this package is available on the dbt Package Hub, add it to the root
project's `packages.yml` alongside the connector-managed Core dependency:

```yaml
packages:
  - package: tuva-health/cms_hcc
    version: 0.1.0
```

Before Hub registration is complete, or when testing an exact source release,
use the immutable Git tag instead:

```yaml
packages:
  - git: "https://github.com/tuva-health/cms_hcc.git"
    revision: v0.1.0
```

Then install dependencies:

```shell
dbt deps
```

## Configuration and usage

CMS HCC risk adjustment and recapture require claims data. HCC suspecting can
use claims data, clinical data, or both. Configure the native boolean Tuva
feature variables in the root project's `dbt_project.yml` and choose the
payment year explicitly when reproducibility matters:

```yaml
vars:
  claims_enabled: true
  clinical_enabled: false
  cms_hcc_payment_year: 2026
```

Run the complete package, including its package-owned seed ancestors, with:

```shell
dbt build --select package:cms_hcc
```

Useful optional configuration:

- `tuva_schema_prefix` prefixes the default `cms_hcc`, `hcc_recapture`, and
  `hcc_suspecting` schemas.
- `hcc_recapture_chronic_hccs: true` uses a root-project model named
  `chronic_hccs` instead of the package-owned chronic-HCC seed.
- `hcc_recapture_suspect_list: true` adds a root-project model named
  `suspect_hccs` to the recapture inputs.
- `cms_hcc_data_asset_version` selects the external seed snapshot. Most users
  should leave its package default unchanged.

Open eligibility spans use a null `enrollment_end_date`. The package treats
them as active and caps them to the applicable payment-year boundary. Fully
refresh the package when upgrading from an implementation that capped open
spans or used older identifier contracts.

## Data assets

Seed contents are stored under
`s3://tuva-public-resources/data-marts/cms-hcc/<asset-version>/` and mirrored
to GCS and Azure. Checked-in CSV files contain only the headers required by
dbt. `cms_hcc_data_asset_version` defaults to `1.0.0`; the data-asset version
is intentionally independent of this package's code version.

## Supported warehouses

The package is designed for the Tuva-supported warehouse set: Snowflake,
BigQuery, Databricks, Microsoft Fabric, Redshift, and DuckDB. Its SQL Server
compatibility path has also been exercised with dbt-sqlserver. Amazon Athena
compatibility branches are present, but the complete package has not yet been
validated end to end on Athena.

Pull requests run a credential-free DuckDB build against an official CMS 2026
V28 beneficiary-and-diagnosis fixture. The fixture source and checksum are in
`integration_tests/fixtures/official_cms_2026_v28`.

## Documentation and contributing

- [CMS HCC documentation](https://thetuvaproject.com/data-marts/cms-hccs)
- [Tuva Project documentation](https://thetuvaproject.com/)
- [Issues and feature requests](https://github.com/tuva-health/cms_hcc/issues)
- [Tuva community Slack](https://join.slack.com/t/thetuvaproject/shared_invite/zt-16iz61187-G522Mc2WGA2mHF57e0il0Q)

Contributions are welcome through GitHub issues and pull requests. This
project is licensed under the [Apache License 2.0](LICENSE).
