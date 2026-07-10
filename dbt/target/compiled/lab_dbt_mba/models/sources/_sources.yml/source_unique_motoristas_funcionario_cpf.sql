
    
    

select
    cpf as unique_field,
    count(*) as n_records

from "db_dw"."raw_motoristas"."funcionario"
where cpf is not null
group by cpf
having count(*) > 1


