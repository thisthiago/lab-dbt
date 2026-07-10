
    
    

with all_values as (

    select
        tipo as value_field,
        count(*) as n_records

    from "db_dw"."staging"."stg_admin__apontamentos"
    group by tipo

)

select *
from all_values
where value_field not in (
    'Entrada','Saída'
)


