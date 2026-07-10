
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with child as (
    select sk_funcionario as from_field
    from "db_dw"."marts"."fato_ponto"
    where sk_funcionario is not null
),

parent as (
    select sk_funcionario as to_field
    from "db_dw"."marts"."dim_funcionario"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null



  
  
      
    ) dbt_internal_test