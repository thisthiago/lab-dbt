
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select horas_trabalhadas
from "db_dw"."marts"."fato_ponto"
where horas_trabalhadas is null



  
  
      
    ) dbt_internal_test