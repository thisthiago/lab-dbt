
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select apontamento_id
from "db_dw"."staging"."stg_admin__apontamentos"
where apontamento_id is null



  
  
      
    ) dbt_internal_test