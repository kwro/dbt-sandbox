{% set billing_keys = [
    '_billing_first_name',
    '_billing_last_name',
    'billing_company',
    '_billing_nip',
    '_billing_faktura',
    '_billing_email',
    '_billing_phone',
    '_billing_address_1',
    '_billing_city',
    '_billing_postcode',
    '_billing_country'
] -%}

SELECT
    post_id AS order_id
    {% for key in billing_keys -%}
        {%- if not loop.first -%}
            {{ "    ," }}
        {%- else -%}
            {{ "," }}
        {%- endif -%}
        {{- pivot_meta_value('meta_value', key) }}
    {%- endfor -%}
FROM {{ source('mydb', 'wp_postmeta') }}
WHERE meta_key IN (
    {%- for key in billing_keys -%}
        '{{ key }}'{%- if not loop.last -%}, {% endif %}
    {%- endfor -%}
)
GROUP BY post_id
