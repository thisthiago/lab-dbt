
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    sk_data as unique_field,
    count(*) as n_records

from "db_dw"."marts"."dim_data"
where sk_data is not null
group by sk_data
having count(*) > 1



  
  
      
    ) dbt_internal_test