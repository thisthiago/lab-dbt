
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    apontamento_id as unique_field,
    count(*) as n_records

from "db_dw"."staging"."stg_admin__apontamentos"
where apontamento_id is not null
group by apontamento_id
having count(*) > 1



  
  
      
    ) dbt_internal_test