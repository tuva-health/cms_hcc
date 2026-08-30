{#
    Fail fast when cms_hcc is installed but every one of its models is
    disabled. Without this, a run finishes "successfully" having silently
    built nothing.

    Domain gating (see README.md):
      cms_hcc          -> claims_enabled
      hcc_recapture    -> claims_enabled
      hcc_suspecting   -> claims_enabled OR clinical_enabled

    Disabled nodes are excluded from `graph.nodes`, so counting this
    package's surviving models detects exactly the all-disabled case.
    `graph.nodes` is only populated at run time, hence the `execute` guard;
    on-run-start does not fire during `dbt parse`, so CI parse gates are
    unaffected.

    Escape hatch: set `vars: {cms_hcc_suppress_enablement_check: true}` to
    install the package without building it.
#}

{% macro assert_cms_hcc_enabled() %}
    {%- if not execute -%}
        {{ return('') }}
    {%- endif -%}

    {%- if var('cms_hcc_suppress_enablement_check', false) | as_bool -%}
        {{ return('') }}
    {%- endif -%}

    {%- set ns = namespace(count=0) -%}
    {%- for node in graph.nodes.values() -%}
        {%- if node.package_name == 'cms_hcc' and node.resource_type == 'model' -%}
            {%- set ns.count = ns.count + 1 -%}
        {%- endif -%}
    {%- endfor -%}

    {%- if ns.count == 0 -%}
        {{ exceptions.raise_compiler_error(
            "cms_hcc is installed but every one of its models is disabled, so this run would build nothing."
            ~ " Current values: claims_enabled = " ~ var('claims_enabled', false)
            ~ ", clinical_enabled = " ~ var('clinical_enabled', false) ~ "."
            ~ " Set `vars: {claims_enabled: true}` in your dbt_project.yml to build the cms_hcc and"
            ~ " hcc_recapture marts, and/or `vars: {clinical_enabled: true}` to build the hcc_suspecting"
            ~ " mart (hcc_suspecting builds when either flag is true)."
            ~ " To install cms_hcc without building it, set"
            ~ " `vars: {cms_hcc_suppress_enablement_check: true}`.") }}
    {%- endif -%}

    {{ return('') }}
{% endmacro %}
