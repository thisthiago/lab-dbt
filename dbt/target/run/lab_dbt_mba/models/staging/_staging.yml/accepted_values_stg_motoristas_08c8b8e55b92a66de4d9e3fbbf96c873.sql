
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        sistema_origem as value_field,
        count(*) as n_records

    from "db_dw"."staging"."stg_motoristas__funcionarios"
    group by sistema_origem

)

select *
from all_values
where value_field not in (
    'motoristas'
)



  
  
      
    ) dbt_internal_test