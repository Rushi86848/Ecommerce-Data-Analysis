
--- ##### -----



-- created a new database [job project] and loaded all the tables 


--- ##### -----



-- converted company X-SKU master table's column weight(g) into weight in KG 

select * from [job project].[dbo].[sku_x] 


alter table [job project].[dbo].[sku_x]
add weight_kg float

update [job project].[dbo].[sku_x]
set weight_kg = round(([weight (g)]/1000),2)


alter table [job project].[dbo].[sku_x]
drop column [weight (g)]


---------------------------------------------------------------------------------------------------------


-- joined two tables [job project].[dbo].[sku_x] and [job project].[dbo].[order_x] by the column SKU 
-- and also done a group by to achieve total weight (kg) as per X and totl order Qty as per x


select a.[ExternOrderNo],sum(a.[Order Qty]) as total_order_qty,sum(b.[weight_kg]) as weight_x 
into X_SKU_order 
from [job project].[dbo].[order_x] a
left join [job project].[dbo].[sku_x] b
on a.SKU=b.SKU 
group by a.[ExternOrderNo]
order by a.[ExternOrderNo]


select * from X_SKU_order 


--------------------------------------------------------------------------------------


-- adding a new column in X_SKU_order table to create a weight slab as per x


select * from X_SKU_order


select *, iif(weightsum <=0.5, 0.5,
iif(weightsum <=1.0, 1.0,
iif(weightsum <=1.5, 1.5,
iif(weightsum <=2.0, 2.0,
iif(weightsum <=2.5, 2.5,
iif(weightsum <=3.0, 3.0,0))))))
as weight_slab_x 
from X_SKU_order



ALTER TABLE X_SKU_order
Add weight_slab_x float ;


Update X_SKU_order
SET weight_slab_x = iif(weightsum <=0.5, 0.5,
iif(weightsum <=1.0, 1.0,
iif(weightsum <=1.5, 1.5,
iif(weightsum <=2.0, 2.0,
iif(weightsum <=2.5, 2.5,
iif(weightsum <=3.0, 3.0,0)))))); 

-----------------------------------------------------------------------------------------------------


-- adding a new column in [courier_invoice] table to create a weight slab as per courier


select * from [job project].[dbo].[courier_invoice]



select *, iif([charged Weight] <=0.5, 0.5,
iif([charged Weight] <=1.0, 1.0,
iif([charged Weight] <=1.5, 1.5,
iif([charged Weight] <=2.0, 2.0,
iif([charged Weight] <=2.5, 2.5,
iif([charged Weight] <=3.0, 3.0,
iif([charged Weight] <=3.5, 3.5,
iif([charged Weight] <=4.0, 4.0,
iif([charged Weight] <=4.5, 4.5,0
)))))))))
as weight_slab_courier 
from [job project].[dbo].[courier_invoice]




ALTER TABLE [job project].[dbo].[courier_invoice]
Add weight_slab_courier float ;



update [job project].[dbo].[courier_invoice]
set weight_slab_courier =
iif([charged Weight] <=0.5, 0.5,
iif([charged Weight] <=1.0, 1.0,
iif([charged Weight] <=1.5, 1.5,
iif([charged Weight] <=2.0, 2.0,
iif([charged Weight] <=2.5, 2.5,
iif([charged Weight] <=3.0, 3.0,
iif([charged Weight] <=3.5, 3.5,
iif([charged Weight] <=4.0, 4.0,
iif([charged Weight] <=4.5, 4.5,0
)))))))))



-------------------------------------------------------------------------------------------------------

-- merge table courier companys invoice and X pincode zones by the column customer pincode


select * from [job project].[dbo].[courier_invoice]

select * from [job project].[dbo].[zone_x]


select a.[AWB Code],a.[Order ID],
a.[Charged Weight] as weight_courier,
a.[weight_slab_courier],
b.[Zone] as zone_x,
a.[Zone] as zone_courier,
a.[Type of Shipment],
a.[Billing Amount (Rs#)] as charged_billing_amount_courier_RS 
into result
from [job project].[dbo].[courier_invoice] a
left join [job project].[dbo].[zone_x] b
on a.[Customer Pincode]=b.[Customer Pincode]


select * from result


-- remove duplicate results from table [result]   ---------------------------------



WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY [Order ID]
			     ORDER BY
				 [Order ID]
			) row_num
From result
)
Select *
From RowNumCTE
Where row_num > 1




WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY [Order ID]
			     ORDER BY
				 [Order ID]
			) row_num
From result
)
delete
From RowNumCTE
Where row_num > 1




select * from result order by [Order ID]


select * from X_SKU_order order by [ExternOrderNo]


-------------------------------------------------------------------------------------------------


-- merging table [X_SKU_order] and [result]  


select a.* , b.[weightsum], b.[weight_slab_X]
into result1
from result a 
left join X_SKU_order b 
on a.[Order ID] = b.[ExternOrderNo]


select * from result1 order by [Order ID]



--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------

---- ##  now we are finding expected charges as per X by applying rates given by courier company ## ----



select * from result1 order by [Order ID]


 select *, (
 iif([weight_slab_X]=0.5 and [zone_x]='b' and [Type of Shipment]='Forward charges' , 33,
 iif([weight_slab_X]=1.0 and [zone_x]='b' and [Type of Shipment]='Forward charges' , 61.3,
 iif([weight_slab_X]=1.5 and [zone_x]='b' and [Type of Shipment]='Forward charges' , 89.6, 
 iif([weight_slab_X]=2.0 and [zone_x]='b' and [Type of Shipment]='Forward charges' ,117.9,
 iif([weight_slab_X]=2.5 and [zone_x]='b' and [Type of Shipment]='Forward charges' ,146.2,
 iif([weight_slab_X]=3.0 and [zone_x]='b' and [Type of Shipment]='Forward charges' ,174.5,0
 ))))))
 ) as frw_b_fix_add
 from result1


alter table result1
add frw_b_fix_add float;


update result1
set frw_b_fix_add =  iif([weight_slab_X]=0.5 and [zone_x]='b' and [Type of Shipment]='Forward charges' , 33,
 iif([weight_slab_X]=1.0 and [zone_x]='b' and [Type of Shipment]='Forward charges' , 61.3,
 iif([weight_slab_X]=1.5 and [zone_x]='b' and [Type of Shipment]='Forward charges' , 89.6, 
 iif([weight_slab_X]=2.0 and [zone_x]='b' and [Type of Shipment]='Forward charges' ,117.9,
 iif([weight_slab_X]=2.5 and [zone_x]='b' and [Type of Shipment]='Forward charges' ,146.2,
 iif([weight_slab_X]=3.0 and [zone_x]='b' and [Type of Shipment]='Forward charges' ,174.5,0
 )))))) 


---------------------------------------------------------------------------------------------------------



select * from result1 order by [Order ID]

 select *, (
 iif([weight_slab_X]=0.5 and [zone_x]='d' and [Type of Shipment]='Forward charges' ,45.5 ,
 iif([weight_slab_X]=1.0 and [zone_x]='d' and [Type of Shipment]='Forward charges' , 90.2,
 iif([weight_slab_X]=1.5 and [zone_x]='d' and [Type of Shipment]='Forward charges' , 135, 
 iif([weight_slab_X]=2.0 and [zone_x]='d' and [Type of Shipment]='Forward charges' ,179.8,
 iif([weight_slab_X]=2.5 and [zone_x]='d' and [Type of Shipment]='Forward charges' ,224.6,
 iif([weight_slab_X]=3.0 and [zone_x]='d' and [Type of Shipment]='Forward charges' ,269.4,0
 ))))))
 ) as frw_d_fix_add
 from result1


alter table result1
add frw_d_fix_add float;


update result1
set frw_d_fix_add =
 iif([weight_slab_X]=0.5 and [zone_x]='d' and [Type of Shipment]='Forward charges' ,45.5 ,
 iif([weight_slab_X]=1.0 and [zone_x]='d' and [Type of Shipment]='Forward charges' , 90.2,
 iif([weight_slab_X]=1.5 and [zone_x]='d' and [Type of Shipment]='Forward charges' , 135, 
 iif([weight_slab_X]=2.0 and [zone_x]='d' and [Type of Shipment]='Forward charges' ,179.8,
 iif([weight_slab_X]=2.5 and [zone_x]='d' and [Type of Shipment]='Forward charges' ,224.6,
 iif([weight_slab_X]=3.0 and [zone_x]='d' and [Type of Shipment]='Forward charges' ,269.4,0
 ))))))



--------------------------------------------------------------------------------------------------------------


select * from result1 order by [Order ID]


 select *, (
 iif([weight_slab_X]=0.5 and [zone_x]='e' and [Type of Shipment]='Forward charges' , 56.6,
 iif([weight_slab_X]=1.0 and [zone_x]='e' and [Type of Shipment]='Forward charges' , 112.1,
 iif([weight_slab_X]=1.5 and [zone_x]='e' and [Type of Shipment]='Forward charges' , 167.6, 
 iif([weight_slab_X]=2.0 and [zone_x]='e' and [Type of Shipment]='Forward charges' ,223.1,
 iif([weight_slab_X]=2.5 and [zone_x]='e' and [Type of Shipment]='Forward charges' ,278.6,
 iif([weight_slab_X]=3.0 and [zone_x]='e' and [Type of Shipment]='Forward charges' ,334.1,0
 ))))))
 ) as frw_e_fix_add
 from result1


alter table result1
add frw_e_fix_add float;


update result1
set frw_e_fix_add =
 iif([weight_slab_X]=0.5 and [zone_x]='e' and [Type of Shipment]='Forward charges' , 56.6,
 iif([weight_slab_X]=1.0 and [zone_x]='e' and [Type of Shipment]='Forward charges' , 112.1,
 iif([weight_slab_X]=1.5 and [zone_x]='e' and [Type of Shipment]='Forward charges' , 167.6, 
 iif([weight_slab_X]=2.0 and [zone_x]='e' and [Type of Shipment]='Forward charges' ,223.1,
 iif([weight_slab_X]=2.5 and [zone_x]='e' and [Type of Shipment]='Forward charges' ,278.6,
 iif([weight_slab_X]=3.0 and [zone_x]='e' and [Type of Shipment]='Forward charges' ,334.1,0
 ))))))



------------------------------------------------------------------------------------------------------------


select * from result1 order by [Order ID]



 select *, (
 iif([weight_slab_X]=0.5 and [zone_x]='b' and [Type of Shipment]='Forward and RTO charges' ,20.5,
 iif([weight_slab_X]=1.0 and [zone_x]='b' and [Type of Shipment]='Forward and RTO charges' , 48.8,
 iif([weight_slab_X]=1.5 and [zone_x]='b' and [Type of Shipment]='Forward and RTO charges' , 77.1, 
 iif([weight_slab_X]=2.0 and [zone_x]='b' and [Type of Shipment]='Forward and RTO charges' ,105.4,
 iif([weight_slab_X]=2.5 and [zone_x]='b' and [Type of Shipment]='Forward and RTO charges' ,133.7,
 iif([weight_slab_X]=3.0 and [zone_x]='b' and [Type of Shipment]='Forward and RTO charges' ,162,0
 ))))))
 ) as frw_b_fix_add_rto
 from result1


alter table result1
add frw_b_fix_add_rto float;


update result1
set frw_b_fix_add_rto =
 iif([weight_slab_X]=0.5 and [zone_x]='b' and [Type of Shipment]='Forward and RTO charges' ,20.5,
 iif([weight_slab_X]=1.0 and [zone_x]='b' and [Type of Shipment]='Forward and RTO charges' , 48.8,
 iif([weight_slab_X]=1.5 and [zone_x]='b' and [Type of Shipment]='Forward and RTO charges' , 77.1, 
 iif([weight_slab_X]=2.0 and [zone_x]='b' and [Type of Shipment]='Forward and RTO charges' ,105.4,
 iif([weight_slab_X]=2.5 and [zone_x]='b' and [Type of Shipment]='Forward and RTO charges' ,133.7,
 iif([weight_slab_X]=3.0 and [zone_x]='b' and [Type of Shipment]='Forward and RTO charges' ,162,0
 ))))))



--------------------------------------------------------------------------------------------------------------


select * from result1 order by [Order ID]


 select *, (
 iif([weight_slab_X]=0.5 and [zone_x]='d' and [Type of Shipment]='Forward and RTO charges' ,41.3,
 iif([weight_slab_X]=1.0 and [zone_x]='d' and [Type of Shipment]='Forward and RTO charges' , 86.1,
 iif([weight_slab_X]=1.5 and [zone_x]='d' and [Type of Shipment]='Forward and RTO charges' , 130.9, 
 iif([weight_slab_X]=2.0 and [zone_x]='d' and [Type of Shipment]='Forward and RTO charges' ,175.5,
 iif([weight_slab_X]=2.5 and [zone_x]='d' and [Type of Shipment]='Forward and RTO charges' ,220.5,
 iif([weight_slab_X]=3.0 and [zone_x]='d' and [Type of Shipment]='Forward and RTO charges' ,265.3,0
 ))))))
 ) as frw_d_fix_add_rto
 from result1


alter table result1
add frw_d_fix_add_rto float;


update result1
set frw_d_fix_add_rto = 
 iif([weight_slab_X]=0.5 and [zone_x]='d' and [Type of Shipment]='Forward and RTO charges' ,41.3,
 iif([weight_slab_X]=1.0 and [zone_x]='d' and [Type of Shipment]='Forward and RTO charges' , 86.1,
 iif([weight_slab_X]=1.5 and [zone_x]='d' and [Type of Shipment]='Forward and RTO charges' , 130.9, 
 iif([weight_slab_X]=2.0 and [zone_x]='d' and [Type of Shipment]='Forward and RTO charges' ,175.5,
 iif([weight_slab_X]=2.5 and [zone_x]='d' and [Type of Shipment]='Forward and RTO charges' ,220.5,
 iif([weight_slab_X]=3.0 and [zone_x]='d' and [Type of Shipment]='Forward and RTO charges' ,265.3,0
 ))))))



-------------------------------------------------------------------------------------------------------------------------


select * from result1 order by [Order ID]

 select *, (
 iif([weight_slab_X]=0.5 and [zone_x]='e' and [Type of Shipment]='Forward and RTO charges' ,50.7,
 iif([weight_slab_X]=1.0 and [zone_x]='e' and [Type of Shipment]='Forward and RTO charges' , 106.2,
 iif([weight_slab_X]=1.5 and [zone_x]='e' and [Type of Shipment]='Forward and RTO charges' , 161.7, 
 iif([weight_slab_X]=2.0 and [zone_x]='e' and [Type of Shipment]='Forward and RTO charges' ,217.2,
 iif([weight_slab_X]=2.5 and [zone_x]='e' and [Type of Shipment]='Forward and RTO charges' ,272.7,
 iif([weight_slab_X]=3.0 and [zone_x]='e' and [Type of Shipment]='Forward and RTO charges' ,328.2,0
 ))))))
 ) as frw_e_fix_add_rto
 from result1


alter table result1
add frw_e_fix_add_rto float;


update result1
set frw_e_fix_add_rto =
 iif([weight_slab_X]=0.5 and [zone_x]='e' and [Type of Shipment]='Forward and RTO charges' ,50.7,
 iif([weight_slab_X]=1.0 and [zone_x]='e' and [Type of Shipment]='Forward and RTO charges' , 106.2,
 iif([weight_slab_X]=1.5 and [zone_x]='e' and [Type of Shipment]='Forward and RTO charges' , 161.7, 
 iif([weight_slab_X]=2.0 and [zone_x]='e' and [Type of Shipment]='Forward and RTO charges' ,217.2,
 iif([weight_slab_X]=2.5 and [zone_x]='e' and [Type of Shipment]='Forward and RTO charges' ,272.7,
 iif([weight_slab_X]=3.0 and [zone_x]='e' and [Type of Shipment]='Forward and RTO charges' ,328.2,0
 ))))))

--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------


select * from result1 order by [Order ID]


alter table result1
add expected_charges_X as (frw_b_fix_add + frw_d_fix_add + frw_e_fix_add + frw_b_fix_add_rto + frw_d_fix_add_rto + frw_e_fix_add_rto);


------ #### now we got all the results that requires to find difference between expected charges as per x and amount charged by couries company  #### ------