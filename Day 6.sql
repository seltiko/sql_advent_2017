
drop table if exists temp_input;
create temp table temp_input as
select 
'11	11	13	7	0	15	5	5	4	4	1	1	7	1	15	11'::text as inputs
;
drop table if exists test_temp_input;
create temp table test_temp_input as
select 
'0	2	7	0'::text as inputs
;


-- with memory as(
drop table if exists memory;
create temp table memory as(
select row_number() over() as rn
	,count(1) over() as num
	,blocks::bigint
	,0::int as iter
from(
select regexp_split_to_table(inputs,'\t') as blocks
from temp_input
-- from test_temp_input
)t
)
;



--part i not well organized... also not very fast...

drop table if exists history;
create temp table history as
select iter
	,array_agg(blocks) as memory
from memory
group by 1;

select *
from history;

create or replace function inception(bigint[],int) returns void  as $$
	insert into history values ($2,$1)
	;
	$$
	language sql;

--This query takes you one step...
/*
select iter, array_agg(blocks), inception(array_agg(blocks),iter)
from(
select rn
	,case when biggest = rn 
		then sum(redib1::int)
		else blocks + max(redib2::int) + sum( redib1::int) end as blocks
	,num
	,iter
from(
select m.rn
	,m.blocks
	,m.num
	,m.iter + 1 as iter
	,m2.rn as biggest
	,m.rn + generate_series(1,coalesce(1+ m2.blocks / num,1),1) * num <= m2.blocks + m2.rn as redib1
	,(m.rn > m2.rn
		and m.rn <= m2.blocks + m2.rn) as redib2
from memory m
left join (
		select m9.rn ,m9.blocks, m9.iter
		from memory m9
		order by m9.blocks desc, m9.rn asc
		limit 1
		) m2
-- 	on m2.rn = m.rn
	on m2.iter = m.iter
)t
group by rn, biggest, blocks, num, iter
)t2
group by iter
;
*/



create or replace function dostuff() returns int  as $$

	
with current_mem as(
select row_number() over() as rn
	,count(1) over() as num
	,blocks
	,iter
from(
select
	unnest(memory) as blocks
	,iter
from(
select *
from history
where not exists(
	select memory, count(1)
	from history
	group by 1
	having count(1) > 1)
order by iter desc
limit 1
)t
)t2
)

select iter
from(
select iter, array_agg(blocks), inception(array_agg(blocks),iter)
from(
select rn
	,case when biggest = rn 
		then sum(redib1::int)
		else blocks + max(redib2::int) + sum( redib1::int) end as blocks
	,num
	,iter
from(
select m.rn
	,m.blocks
	,m.num
	,m.iter + 1 as iter
	,m2.rn as biggest
	,m.rn + generate_series(1,coalesce(1+ m2.blocks / num,1),1) * num <= m2.blocks + m2.rn as redib1
	,(m.rn > m2.rn
		and m.rn <= m2.blocks + m2.rn) as redib2
from current_mem m
left join (
		select m9.rn ,m9.blocks, m9.iter
		from current_mem m9
		order by m9.blocks desc, m9.rn asc
		limit 1
		) m2
	on m2.iter = m.iter
)t
group by rn, biggest, blocks, num, iter
order by rn
)t2
group by iter
)t3
;
$$
	language sql;

-- select dostuff();
	


with recursive
	cur(iter) as(
		select dostuff() as iter
		union all
		select dostuff() as iter
		from cur c
		where 
			 c.iter < 15000
		)
select *
from cur
order by iter desc
limit 1
;



select memory, count(1)
from history
group by 1
having count(1) > 1
;

select *
	--,count(1) over(partition by memory)
from history
order by iter desc
limit 1
;


--part ii

select h.iter - h2.iter
from history h
inner join history h2
	on h2.memory = h.memory
	and h2.iter < h.iter
;



drop function inception(bigint[],int);
drop function dostuff();