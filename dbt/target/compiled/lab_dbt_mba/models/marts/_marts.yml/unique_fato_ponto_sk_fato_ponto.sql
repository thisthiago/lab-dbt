
    
    

select
    sk_fato_ponto as unique_field,
    count(*) as n_records

from "db_dw"."marts"."fato_ponto"
where sk_fato_ponto is not null
group by sk_fato_ponto
having count(*) > 1


