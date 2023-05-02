[![Apache License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) ![dbt logo and version](https://img.shields.io/static/v1?logo=dbt&label=dbt-version&message=1.3.x&color=orange)

# CMS HCC Risk Adjustment

## 🔗 Quick Links
- [Docs](https://tuva-health.github.io/the_tuva_project/#!/overview/cms_hcc): Learn about the Tuva Project data model
- [Knowledge Base](https://thetuvaproject.com/docs/intro): Learn about claims data fundamentals and how to do claims data analytics
<br/><br/>

## 🧰 What does this project do?

The Tuva Project's CMS HCC package calculates risk scores based on version V24 of the CMS-HCC risk adjustment model (payment years 2020-2023). 
Future releases will include the ability to run other model versions.

*Note: This package does not include CMS models ESRD, PACE, or RxHCC.*

## 🔌 What databases are supported?

This package has been tested on **Snowflake**.

## 📚 What versions of dbt are supported?

This package requires you to have dbt installed and a functional dbt project running on dbt version `1.3.x`.

## ✅ How do I use this dbt package?

This is an early preview of the CMS HCC package. It has not been added to the main [Tuva Project package](https://github.com/tuva-health/the_tuva_project#readme) yet. 
To run this package, you can update your packages.yml with the GitHub URL. See example below.

```
packages:
  - package: tuva-health/the_tuva_project
    version: [">=0.3.0","<1.0.0"]

  - git: https://github.com/tuva-health/cms_hcc.git
    warn-unpinned: false
```

This package uses a variable called `cms_hcc_payment_year` to calculate risk scores. 
The default is the current year.
You can override this by adding the var to your `dbt_project.yml` file with the year you would like to calculate: 

```
vars:
  cms_hcc_payment_year: 2022
```

Or, via the command line:

```
dbt build --select cms_hcc --vars '{cms_hcc_payment_year: 2022}'
```

## 🙋🏻‍♀ ️****How is this package maintained and how do I contribute?****

The Tuva Project team maintaining this package **only** maintains the latest version of the package. We highly recommend you stay consistent with the latest version.

Have an opinion on the mappings? Notice any bugs when installing and running the package? If so, we highly encourage and welcome feedback! While we work on a formal process in Github, we can be easily reached in our Slack community.

## 🤝 Join our community!

Join our growing community of healthcare data practitioners in [Slack](https://join.slack.com/t/thetuvaproject/shared_invite/zt-16iz61187-G522Mc2WGA2mHF57e0il0Q)!
