
    
    

with all_values as (

    select
        status as value_field,
        count(*) as n_records

    from "db_dw"."staging"."stg_admin__funcionarios"
    group by status

)

select *
from all_values
where value_field not in (
    'Ativo','Demitido'
)


