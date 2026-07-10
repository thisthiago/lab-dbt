
    
    

select
    id as unique_field,
    count(*) as n_records

from "db_dw"."raw_motoristas"."apontamento"
where id is not null
group by id
having count(*) > 1


