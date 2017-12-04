--part 1

select *
	,num_steps_from_corner + step_adj as num_steps
from(
select *
	,num_to_corner % (square)
	,((num_to_corner % (square)) % (square/2) )
	,case when square%2 = 0
	then case when num_to_corner % (square) = 0 then 0
		when ((num_to_corner % (square)) % (square/2) ) = 0 then -1*(square/2)
		else case when nice_div((num_to_corner % (square)) , (square/2) ) < 1
			then ((num_to_corner % (square)) % (square/2) ) * -1
			else ((num_to_corner % (square)) % (square/2) ) - (square/2)
			end
		end
	else case when num_to_corner = 0 then 0
		when num_to_corner % (square+1) = 0 then  2
		when (num_to_corner % (square+1) % ((square+1)/2) ) = 0 then -1*((square+1)/2)+2
		else case when nice_div((num_to_corner % (square+1))::int , ((square+1)/2) ) < 1
			then (num_to_corner % (square+1) % ((square+1)/2) ) * -1 + 2
			else ((num_to_corner % (square+1) % ((square+1)/2) ) -  ((square+1)/2) + 2)
			end
		end
	end as step_adj
from(
select *
	,(case when (square^2)::int %2 = 0 then square^2 +1
	else square^2 end)::int as corner
	
	,(case when (square^2)::int %2 = 0 then square 
	else square - 1  end)::int as num_steps_from_corner
	,abs((inputs - case when (square^2)::int %2 = 0 then square^2 +1
	else square^2 end))::int as num_to_corner
from(
select *
	,(floor(sqrt(inputs)))::int as square
from(
select 347991::int as inputs
-- select 56::int as inputs
-- select generate_series(81,105,1) as inputs
)i
)i2

)t
)t2
order by inputs
;



--part ii


/*
Value of a square will always be at least value-1
If it is a corner then it is the value-1 + previousx2 corner
If it is -1 distant from a corner then value-1 + previousx2 corner + previousx2 corner-1

in top right corner: sum of all even squares + 1

gross never mind
*/
drop table if exists coors;
create table coors as
select 
-- 	row_number() over() as rn,
	*,case when x=0 and y =0 then 1 else 0 end as val
from(
select generate_series(-5,5,1) as x)t
inner join (select generate_series(-5,5,1) y) t2
	on true
;




create or replace function jfoster1.update_value(int, int) returns void  as $$
	update coors set val = new_val
		from
		(select c.x
			,c.y
			,sum(c2.val)::int as new_val
		from coors c
		left join coors c2
			on (c.x in (c2.x,c2.x-1, c2.x+1) and c.y in (c2.y,c2.y-1, c2.y+1))
	and not(c.x = c2.x and c.y = c2.y)
		where c.x = $1
			and c.y = $2
		group by 1,2
		)t
		where coors.x = $1
			and coors.y = $2
	;
	$$
	language sql;

-- select jfoster1.update_value(1,0);


with recursive coords(x,y,blah) as (
select x,y,null::void as miller
from coors
where x=0 and y=0
union all

select c.x,c.y
	,jfoster1.update_value(c.x,c.y) as miller
-- 	,sum(case when not(c.x = c2.x and c.y = c2.y) then c2.val end) as val
-- ,sum(c.val)::int
from(
select case when c.x=0 and c.y=0 --start
	then 1
	--corners
	when c.x = abs(c.x) and c.y = abs(c.y) and abs(c.x) = abs(c.y)
		then c.x-1
	when  -1*c.x = abs(c.x) and c.y = abs(c.y) and abs(c.x) = abs(c.y)
		then c.x
	when  -1*c.x = abs(c.x) and -1*c.y = abs(c.y) and abs(c.x) = abs(c.y)
		then c.x+1
	when  c.x = abs(c.x) and -1*c.y = abs(c.y) and abs(c.x) = abs(c.y)
		then c.x+1
	--edges
	when c.x = abs(c.x) and c.x >= abs(c.y)
		then c.x
	when c.y = abs(c.y) and abs(c.x) <= c.y
		then c.x-1
	when -1*c.x = abs(c.x) and abs(c.x) >= abs(c.y)
		then c.x
	when -1*c.y = abs(c.y) and abs(c.x) <= abs(c.y)
		then c.x+1
	end as x
	,case when c.x=0 and c.y=0 --start
	then 0
	--corners
	when c.x = abs(c.x) and c.y = abs(c.y) and abs(c.x) = abs(c.y)
		then c.y
	when  -1*c.x = abs(c.x) and c.y = abs(c.y) and abs(c.x) = abs(c.y)
		then c.y-1
	when  -1*c.x = abs(c.x) and -1*c.y = abs(c.y) and abs(c.x) = abs(c.y)
		then c.y
	when  c.x = abs(c.x) and -1*c.y = abs(c.y) and abs(c.x) = abs(c.y)
		then c.y
	--edges
	when c.x = abs(c.x) and c.x >= abs(c.y)
		then c.y+1
	when c.y = abs(c.y) and abs(c.x) <= c.y
		then c.y
	when -1*c.x = abs(c.x) and abs(c.x) >= abs(c.y)
		then c.y-1
	when -1*c.y = abs(c.y) and abs(c.x) <= abs(c.y)
		then c.y
	end as y
-- 	,c.val
from coords c)c
-- from (select *
-- from coors
-- where x=2 and y=-1)c)c
-- inner join coords c2
-- 	on (c.x in (c2.x,c2.x-1, c2.x+1) and c.y in (c2.y,c2.y-1, c2.y+1))
-- 	and not(c.x = c2.x and c.y = c2.y)
where abs(c.x)<=5 or abs(c.y)<=5
-- group by 1,2
)

select *
from coords
;



select *
from coors
where val > 347991
order by val asc limit 1
;

