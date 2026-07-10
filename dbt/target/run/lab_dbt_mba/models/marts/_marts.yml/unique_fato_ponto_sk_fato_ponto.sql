
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    sk_fato_ponto as unique_field,
    count(*) as n_records

from "db_dw"."marts"."fato_ponto"
where sk_fato_ponto is not null
group by sk_fato_ponto
having count(*) > 1



  
  
      
    ) dbt_internal_test