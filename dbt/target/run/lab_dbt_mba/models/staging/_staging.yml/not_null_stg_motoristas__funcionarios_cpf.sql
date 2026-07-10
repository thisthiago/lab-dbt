
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select cpf
from "db_dw"."staging"."stg_motoristas__funcionarios"
where cpf is null



  
  
      
    ) dbt_internal_test