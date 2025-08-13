{% macro listentime_mins_to_hrs(listening_time_column) %}
    {{ listening_time_column }} / 60
{% endmacro %}