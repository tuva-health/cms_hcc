{#
    Fail fast when cms_hcc is installed but every one of its models is
    disabled. Without this, a run finishes "successfully" having silently
    built nothing.

    Domain gating (see README.md):
      cms_hcc          -> claims_enabled                    (21 models)
      hcc_recapture    -> claims_enabled                    (15 models)
      hcc_suspecting   -> claims_enabled OR clinical_enabled (19 models)

    The check fires only when ALL of the following hold, so that it flags a
    genuinely empty run and never a deliberately narrowed one:

      1. `cms_hcc_suppress_enablement_check` is unset (escape hatch first).
      2. flags.WHICH is 'run' or 'build'. `dbt seed`, `dbt test` and
         `dbt compile` legitimately do useful work with the models disabled,
         and `dbt parse` never fires on-run-start at all, so CI parse gates
         stay green.
      3. The invocation either passes no --select at all, or passes one that
         names this package. Read from `invocation_args_dict['select']`,
         which holds the raw CLI selection as a tuple of strings: ()
         when bare, ('cms_hcc',), ('tag:cms_hcc', 'input_stubs'), etc.
         "Names this package" is matched against the package name and its
         three mart namespaces, because a selector like `tag:hcc_recapture`
         or `path:models/hcc_suspecting` targets this package without ever
         containing the string "cms_hcc".

         Do NOT use `flags.SELECT` here. On dbt 1.11.14 the Jinja `flags`
         object is built by dbt.flags.get_flag_obj(), which exposes only a
         fixed whitelist plus FULL_REFRESH/STORE_FAILURES/WHICH. `SELECT` is
         absent, so `flags.SELECT` is an Undefined that reports length 0 even
         when --select was passed, and any selector branch built on it would
         silently never fire.

         Reading the raw CLI selection rather than the resolved
         `selected_resources` is what lets `--select cms_hcc` fire while
         every model is disabled: a package with zero enabled nodes can never
         appear in `selected_resources`, so a resolved-selection rule is
         blind to exactly the case this assertion exists to catch.

      4. cms_hcc contributes zero enabled models. Disabled nodes are excluded
         from `graph.nodes`, so counting this package's surviving models
         detects exactly the all-disabled case.

    KNOWN GAP (deliberately not worked around): dbt resolves this operation
    node's config out of the `models:` tree under the package name, so a
    consumer who writes

        models:
          cms_hcc:
            +enabled: false

    puts the on-run-start operation itself into manifest['disabled'] and the
    assertion silently disables itself -- one of the very cases it exists to
    catch. Verified on dbt 1.11.14. Disabling the model subtrees instead
    (models: {cms_hcc: {cms_hcc: ..., hcc_recapture: ..., hcc_suspecting: ...}})
    leaves the operation enabled and the assertion still fires.
#}

{% macro assert_cms_hcc_enabled() %}
    {%- if not execute -%}
        {{ return('') }}
    {%- endif -%}

    {%- if var('cms_hcc_suppress_enablement_check', false) | as_bool -%}
        {{ return('') }}
    {%- endif -%}

    {%- if flags.WHICH not in ('run', 'build') -%}
        {{ return('') }}
    {%- endif -%}

    {#- A --selector names a YAML selector whose contents are not visible
        here, so treat it as a deliberate narrowing and stay quiet. -#}
    {%- if invocation_args_dict.get('selector') -%}
        {{ return('') }}
    {%- endif -%}

    {#- Raw CLI selection: () when bare, ('cms_hcc',), ('tag:cms_hcc',) ... -#}
    {%- set selection = (invocation_args_dict.get('select') or []) | join(' ') -%}
    {%- set own_names = ['cms_hcc', 'hcc_recapture', 'hcc_suspecting'] -%}
    {%- set ns_sel = namespace(names_us=false) -%}
    {%- for name in own_names -%}
        {%- if name in selection -%}
            {%- set ns_sel.names_us = true -%}
        {%- endif -%}
    {%- endfor -%}
    {%- if selection and not ns_sel.names_us -%}
        {{ return('') }}
    {%- endif -%}

    {%- set ns = namespace(cms_hcc_models=0) -%}
    {%- for node in graph.nodes.values() -%}
        {%- if node.resource_type == 'model' and node.package_name == 'cms_hcc' -%}
            {%- set ns.cms_hcc_models = ns.cms_hcc_models + 1 -%}
        {%- endif -%}
    {%- endfor -%}

    {%- if ns.cms_hcc_models == 0 -%}
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
