{{ config(
     enabled = (var('claims_enabled', false) | as_bool)
            or (var('clinical_enabled', false) | as_bool),
     tags = ['hcc_suspecting']
   )
}}

{% set expected_models = [
    'hcc_suspecting__int_all_conditions',
    'hcc_suspecting__int_all_medications',
    'hcc_suspecting__int_comorbidity_suspects',
    'hcc_suspecting__int_lab_suspects',
    'hcc_suspecting__int_medication_suspects',
    'hcc_suspecting__int_observation_suspects',
    'hcc_suspecting__int_patient_hcc_history',
    'hcc_suspecting__int_prep_conditions',
    'hcc_suspecting__int_prep_egfr_labs',
    'hcc_suspecting__list',
    'hcc_suspecting__list_all',
    'hcc_suspecting__list_rollup',
    'hcc_suspecting__stg_core__condition',
    'hcc_suspecting__stg_core__lab_result',
    'hcc_suspecting__stg_core__medication',
    'hcc_suspecting__stg_core__observation',
    'hcc_suspecting__stg_core__patient',
    'hcc_suspecting__stg_core__pharmacy_claim',
    'hcc_suspecting__summary'
] %}

{% if execute %}
    {% set enabled_models = [] %}
    {% for node in graph.nodes.values() %}
        {% if node.resource_type == 'model'
              and node.package_name == 'cms_hcc'
              and 'hcc_suspecting' in node.tags %}
            {% do enabled_models.append(node.name) %}
        {% endif %}
    {% endfor %}

    {% set missing_models = [] %}
    {% for model_name in expected_models %}
        {% if model_name not in enabled_models %}
            {% do missing_models.append(model_name) %}
        {% endif %}
    {% endfor %}

    {% set unexpected_models = [] %}
    {% for model_name in enabled_models %}
        {% if model_name not in expected_models %}
            {% do unexpected_models.append(model_name) %}
        {% endif %}
    {% endfor %}

    {% if missing_models | length > 0 or unexpected_models | length > 0 %}
        {{ exceptions.raise_compiler_error(
            'HCC Suspecting enabled model set does not match the expected contract. Missing: '
            ~ (missing_models | sort | join(', '))
            ~ '; unexpected: '
            ~ (unexpected_models | sort | join(', '))
        ) }}
    {% endif %}
{% endif %}

select 1 as failure
where 1 = 0
