
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    sk_funcionario as unique_field,
    count(*) as n_records

from "db_dw"."marts"."dim_funcionario"
where sk_funcionario is not null
group by sk_funcionario
having count(*) > 1



  
  
      
    ) dbt_internal_test