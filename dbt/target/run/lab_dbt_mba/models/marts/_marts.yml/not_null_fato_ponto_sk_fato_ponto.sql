
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select sk_fato_ponto
from "db_dw"."marts"."fato_ponto"
where sk_fato_ponto is null



  
  
      
    ) dbt_internal_test