{% macro pivot_meta_value(column_name, meta_key_string) -%}
    {%- set alias_name = meta_key_string %}
    {%- if alias_name.startswith('_') %}
        {%- set alias_name = alias_name[1:] %}
    {%- endif -%}
    GROUP_CONCAT(IF(meta_key= '{{ meta_key_string }}', {{ column_name }}, NULL)) AS {{ alias_name }}
{% endmacro %}
--MAX(CASE WHEN meta_key = '{{ meta_key_string }}' THEN {{ column_name }} ELSE NULL END) AS {{ alias_name }}