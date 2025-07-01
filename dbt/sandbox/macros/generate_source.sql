{% macro generate_source(database_name, schema_name, source_name, include_tables=[]) %}

{% set tables_filter %}
    {% if include_tables | length > 0 %}
        AND table_name IN (
            {% for table in include_tables %}
                '{{ table }}'{% if not loop.last %}, {% endif %}
            {% endfor %}
        )
    {% else %}
        ''
    {% endif %}
{% endset %}

{% set sql %}
    WITH columns AS (
        SELECT
            CONCAT('- name: ', LOWER(column_name),
                   '\n            description: "', LOWER(column_name),
                   ' (mysql data type: ', LOWER(data_type), ')"') AS column_statement,
            table_name,
            column_name
        FROM information_schema.columns
        WHERE table_schema = '{{ schema_name }}'
        {{ tables_filter }}
          AND LOWER(column_name) NOT IN ('_fivetran_deleted', '_fivetran_synced')
    ),
    tables AS (
        SELECT
            table_name,
            CONCAT('\n      - name: ', LOWER(table_name),
                   '\n        columns:\n          ',
                   GROUP_CONCAT(column_statement ORDER BY column_name SEPARATOR '\n          ')
            ) AS table_desc
        FROM columns
        GROUP BY table_name
    )
    SELECT GROUP_CONCAT(table_desc ORDER BY table_name SEPARATOR '\n') AS result
    FROM tables;
{% endset %}

{% call statement('generator', fetch_result=True) %}
{{ sql }}
{% endcall %}

{% set result = load_result('generator')['data'] %}

{% set sources_yaml = [] %}
{% do sources_yaml.append('version: 2') %}
{% do sources_yaml.append('') %}
{% do sources_yaml.append('sources:') %}
{% do sources_yaml.append('  - name: ' ~ source_name) %}
{% do sources_yaml.append('    description: ""') %}
{% do sources_yaml.append('    database: ' ~ database_name) %}
{% do sources_yaml.append('    schema: ' ~ schema_name) %}
{% do sources_yaml.append('    loader: fivetran') %}
{% do sources_yaml.append('    loaded_at_field: _FIVETRAN_SYNCED') %}
{% do sources_yaml.append('    meta:') %}
{% do sources_yaml.append('      owner: ""') %}
{% do sources_yaml.append('      tags: [""]') %}
{% do sources_yaml.append('      subscribers: ["@data-team"]') %}

{% do sources_yaml.append('    tables:' ~ result[0][0]) %}

{% if execute %}
  {% set output = sources_yaml | join('\n') %}
--  {{ log(output, info=True) }}
  {% do return(output) %}
{% endif %}

{% endmacro %}
