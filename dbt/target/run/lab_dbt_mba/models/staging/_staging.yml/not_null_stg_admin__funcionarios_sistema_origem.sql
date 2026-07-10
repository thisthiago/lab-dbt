
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select sistema_origem
from "db_dw"."staging"."stg_admin__funcionarios"
where sistema_origem is null



  
  
      
    ) dbt_internal_test