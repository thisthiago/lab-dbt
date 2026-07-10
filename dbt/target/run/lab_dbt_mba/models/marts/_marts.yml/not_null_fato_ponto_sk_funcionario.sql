
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select sk_funcionario
from "db_dw"."marts"."fato_ponto"
where sk_funcionario is null



  
  
      
    ) dbt_internal_test