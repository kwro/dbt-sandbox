{% test no_empty_string(model, column_name) %}
    select *
    from {{ model }}
    where {{ column_name }} = ''
{% endtest %}