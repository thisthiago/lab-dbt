
    
    

with all_values as (

    select
        sistema_origem as value_field,
        count(*) as n_records

    from "db_dw"."staging"."stg_admin__funcionarios"
    group by sistema_origem

)

select *
from all_values
where value_field not in (
    'admin'
)


