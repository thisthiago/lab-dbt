
    
    

select
    sk_funcionario as unique_field,
    count(*) as n_records

from "db_dw"."marts"."dim_funcionario"
where sk_funcionario is not null
group by sk_funcionario
having count(*) > 1


