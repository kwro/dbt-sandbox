{% set shipping_keys = [
    '_shipping_first_name',
    '_shipping_last_name',
    '_shipping_email',
    '_shipping_phone',
    '_shipping_address_1',
    '_shipping_city',
    '_shipping_postcode',
    '_shipping_country'
] -%}

SELECT
    post_id AS order_id
    {% for key in shipping_keys -%}
        {%- if not loop.first -%}
            {{ "    ," }}
        {%- else -%}
            {{ "," }}
        {%- endif -%}
        {{- pivot_meta_value('meta_value', key) }}
    {%- endfor -%}
FROM {{ source('mydb', 'wp_postmeta') }}
GROUP BY post_id
