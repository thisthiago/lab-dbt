
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select funcionario_id
from "db_dw"."staging"."stg_motoristas__funcionarios"
where funcionario_id is null



  
  
      
    ) dbt_internal_test