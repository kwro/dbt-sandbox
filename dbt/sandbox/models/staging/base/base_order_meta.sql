{% set order_keys = [
    'delivery_date',
    'delivery_time',
    '_payment_method_title',
    '_order_shipping',
    '_order_shipping_tax',
    '_order_total',
    '_order_tax',
    '_cart_discount',
    '_cart_discount_tax'
] -%}

SELECT
    post_id AS order_id
    {% for key in order_keys -%}
        {%- if not loop.first -%}
            {{ "    ," }}
        {%- else -%}
            {{ "," }}
        {%- endif -%}
        {{ pivot_meta_value('meta_value', key) }}
    {%- endfor -%}
FROM {{ source('mydb', 'wp_postmeta') }}
GROUP BY post_id
