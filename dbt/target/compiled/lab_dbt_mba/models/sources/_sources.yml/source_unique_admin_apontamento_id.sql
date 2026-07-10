
    
    

select
    id as unique_field,
    count(*) as n_records

from "db_dw"."raw_admin"."apontamento"
where id is not null
group by id
having count(*) > 1


