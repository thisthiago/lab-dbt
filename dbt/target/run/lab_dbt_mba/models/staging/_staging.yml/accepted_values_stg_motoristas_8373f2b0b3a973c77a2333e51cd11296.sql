
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        tipo as value_field,
        count(*) as n_records

    from "db_dw"."staging"."stg_motoristas__apontamentos"
    group by tipo

)

select *
from all_values
where value_field not in (
    'Entrada','Saída'
)



  
  
      
    ) dbt_internal_test