
    
    

with all_values as (

    select
        tipo as value_field,
        count(*) as n_records

    from "db_dw"."raw_admin"."apontamento"
    group by tipo

)

select *
from all_values
where value_field not in (
    'Entrada','Saída'
)


