# Official CMS 2026 V28 golden fixture

The three CSVs in this directory are a minimal fixture for the official
Medicare CMS-HCC V28 model. They were run through the **2026 midyear/final
model software, Python package v3**, downloaded from the CMS Medicare risk
adjustment model software page:

- Page: <https://www.cms.gov/medicare/payment/medicare-advantage-rates-statistics/risk-adjustment/2026-model-software-icd-10-mappings>
- Archive: <https://www.cms.gov/files/zip/2026-midyear-final-model-software-python.zip>
- Archive SHA-256: `b47ed086d8a1cae0bf860526168ecffee07cb8d46766825a72fc21d57dbd47be`
- Archive bytes: `332632`
- Package: `CMS_HCC_v28_2026_T_package_v3`
- Payment year: `2026`
- MCE age edits: enabled (`switch_edits = True`)
- Date-of-birth format: `%m/%d/%Y`

The CMS command was:

```shell
python ./software/CMS_HCC_v28/transform.py
```

`official_cms_2026_v28_expected_scores.csv` retains the demographic flags,
HCCs, interactions, count flag, and raw scores needed to validate the Tuva
pipeline. `P_CE` is compared to `SCORE_COMMUNITY_NA`; `P_NE` is compared to
`SCORE_NE`. The other official segment scores are intentionally omitted.
