
    
    

select
    funcionario_id as unique_field,
    count(*) as n_records

from "db_dw"."staging"."stg_admin__funcionarios"
where funcionario_id is not null
group by funcionario_id
having count(*) > 1


