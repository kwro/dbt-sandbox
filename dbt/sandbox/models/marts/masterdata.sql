{{ config(
    enabled = true,
    materialized = 'ephemeral'
) }}

WITH
order_meta AS (
    SELECT
        order_id,
        delivery_date,
        delivery_time,
        payment_method_title AS payment_method,
        order_shipping,
        order_shipping_tax,
        order_total,
        order_tax,
        art_discount,
        cart_discount_tax
    FROM {{ ref('base_order_meta') }}
),

orders AS (
    SELECT
        order_id,
        parent_id,
        num_items_sold,
        total_sales,
        tax_total,
        shipping_total,
        net_total,
        returning_customer,
        status,
        customer_id,
        CAST(date_created AS TIMESTAMP) AS date_created
    FROM {{ source('mydb', 'wp_wc_order_stats') }}
),

comments AS (
    SELECT
        id,
        post_excerpt AS user_comment
    FROM {{ source('mydb', 'wp_posts') }}
    WHERE post_type = 'shop_order'
),

shipping_meta AS (
    SELECT
        order_id,
        shipping_first_name,
        shipping_last_name,
        shipping_email,
        shipping_phone,
        shipping_address_1,
        shipping_city,
        shipping_postcode,
        shipping_country
    FROM {{ ref('base_shipping_meta') }}
),

billing_meta AS (
    SELECT
        order_id,
        billing_first_name,
        billing_last_name,
        billing_email,
        billing_phone,
        billing_address_1,
        billing_city,
        billing_postcode,
        billing_country,
        billing_nip,
        billing_faktura
    FROM {{ ref('base_billing_meta') }}
),

tip AS (
    SELECT
        order_item_id AS order_id,
        meta_value AS napiwek
    FROM {{ source('mydb', 'wp_woocommerce_order_itemmeta') }}
    WHERE meta_key = '_fee_amount'
),

coupon AS (
    SELECT
        order_id,
        order_item_name AS discount_code
    FROM {{ source('mydb', 'wp_woocommerce_order_items') }}
    WHERE order_item_type = 'coupon'
),

newsletter AS (
    SELECT
        post_id,
        meta_value AS mailchimp_subscribed
    FROM {{ source('mydb', 'wp_postmeta') }}
    WHERE meta_key = 'mailchimp_woocommerce_is_subscribed'
)

SELECT
    orders.order_id,
    orders.date_created,
    orders.status,

    ometa.delivery_date,
    ometa.delivery_time,
    ometa.payment_method,

    orders.customer_id,
    orders.returning_customer,
    ship.shipping_postcode,
    bill.billing_nip,
    bill.billing_faktura,
    newsletter.mailchimp_subscribed,

    ometa.order_shipping,
    ometa.order_shipping_tax,
    napiwek.napiwek,

    orders.num_items_sold,
    orders.total_sales,
    orders.tax_total,
    orders.shipping_total,
    orders.net_total,

    coupon.discount_code,
    ometa.cart_discount,
    ometa.cart_discount_tax,

    comments.user_comment

FROM orders
LEFT JOIN comments         ON orders.order_id = comments.id
LEFT JOIN shipping_meta   AS ship     ON orders.order_id = ship.order_id
LEFT JOIN billing_meta    AS bill     ON orders.order_id = bill.order_id
LEFT JOIN order_meta      AS ometa    ON orders.order_id = ometa.order_id
LEFT JOIN tip             AS napiwek  ON orders.order_id = napiwek.order_id
LEFT JOIN coupon                      ON orders.order_id = coupon.order_id
LEFT JOIN newsletter                  ON orders.order_id = newsletter.post_id
