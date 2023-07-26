use sql_casestudy

--DATA PREPARATION AND UNDERSTANDING
--1. What is the total number of rows in each of the 3 tables in the database?

select 'Total no. of Customer_Table', count(*) from Customer 
union all
select 'Total no. of Product_Table', count(*) from prod_cat_info 
union all
select 'Total no. of Transaction_Table' ,count(*) from Transactions 

--2. What is the total number of transactions that have a return?

select count([total_amt]) from Transactions
where qty<0

/*3. As you would have noticed, the dates provided across the datasets are not in a correct format. As first steps, pls 
	convert the date variables into valid date formats before proceeding ahead.*/

select convert(Date,DOB,105) as Birth_Date from Customer
select convert(Date,tran_date,105) as Tran_Date from Transactions


-/*4.What is the time range of the transaction data available for analysis? 
	Show the output in number of days, months and years simultaneously
	in different columns.*/
	
select DATEDIFF(Day,Min(convert(Date,tran_date,105)),Max(convert(Date,tran_date,105))) Diff_in_Days,
DATEDIFF(Month,Min(convert(Date,tran_date,105)),Max(convert(Date,tran_date,105)))Diff_in_months,
DATEDIFF(Year,Min(convert(Date,tran_date,105)),Max(convert(Date,tran_date,105))) Diff_in_years
from Transactions

--5.Which product category does the sub-category “DIY” belong to?

select prod_cat
from prod_cat_info
where prod_subcat like'DIY'

select * from Customer
select * from prod_cat_info
select * from Transactions

--DATA ANALYSIS
--1.Which channel is most frequently used for transactions?
--ANS. e-Shop

select top 1 store_type,count(transaction_id) as No_of_transactions
from Transactions
group by store_type
order by No_of_transactions desc

--2.What is the count of Male and Female customers in the database?
--ANS. females = 2753, males = 2892
select gender,count(gender) as Total
from Customer
group by gender 
having gender='M' or gender='F' 

--In two record gender is left blank

--3.From which city do we have the maximum number of customers and how many?
--ANS. 595 customer from city code 3
 select top 1 city_code,count(customer_Id)
 from customer 
 group by city_code
 order by count(customer_Id) desc

-- 4.How many sub-categories are there under the Books category?
--ANS. 6

select prod_cat,count(prod_subcat) sub_cat_no
from prod_cat_info
where prod_cat='Books'
group by prod_cat

--5.What is the maximum quantity of products ever ordered?
--ANS.Books having order 88014

alter table transactions
alter column qty int

	select top 1 t.prod_cat_code,p.prod_cat,sum(Qty)
	 from Transactions t 
	 left join prod_cat_info p
	 on t.prod_cat_code=p.prod_cat_code
	 group by t.prod_cat_code,p.prod_cat
	 order by sum(Qty) desc

--6.What is the net total revenue generated in categories Electronics and Books?
--ANS.23545157.675 
alter table transactions
alter column total_amt float

select sum(t.total_amt)
from Transactions t 
left join prod_cat_info p
on t.prod_cat_code=p.prod_cat_code
and t.prod_subcat_code=p.prod_sub_cat_code
where p.prod_cat in ('Electronics','Books')


--7.How many customers have >10 transactions with us, excluding returns?
--ANS. 6 Customers

select count(customer_Id)
from Customer
where customer_Id in
(select cust_id
from Transactions t 
left join Customer c
on t.cust_id=c.customer_Id
where total_amt not like '-%'
group by cust_id
having count(transaction_id)>10)

--8.What is the combined revenue earned from the “Electronics” & “Clothing” categories, from “Flagship stores”?
--ANS. 3409559.27000001

select sum(total_amt) Amt
from Transactions t left join prod_cat_info p
on t.prod_cat_code=p.prod_cat_code
and t.prod_subcat_code=p.prod_sub_cat_code
where p.prod_cat in ('Electronics','Clothing') and Store_type='Flagship store'

--9.What is the total revenue generated from “Male” customers in “Electronics” category? Output should display total revenue by  prod sub-cat.

select p.prod_subcat ,round(sum(total_amt),2) RVN
from Transactions t 
left join Customer c on c.customer_Id=t.cust_id
left join prod_cat_info p on t.prod_cat_code=p.prod_cat_code 
and t.prod_subcat_code=p.prod_sub_cat_code
where Gender='M' and prod_cat='Electronics'
group by p.prod_subcat
 
--10.What is percentage of sales and returns by product sub category;display only top 5 sub categories in terms of sales?
 
 select p.prod_subcat,
 (sum(case when total_amt>0 then total_amt else null end)/(select sum(total_amt) from Transactions))*100 Percentage_of_sales,
 abs((sum(case when total_amt<0 then total_amt else null end)/(select sum(total_amt) from Transactions)))*100 Percentage_of_return
 from Transactions T
 left join prod_cat_info p on t.prod_cat_code=p.prod_cat_code
 and t.prod_subcat_code=p.prod_sub_cat_code
 where prod_subcat in
 (
 select top 5 P.prod_subcat --sum(total_amt) 
 from Transactions T
 left join prod_cat_info p on t.prod_cat_code=p.prod_cat_code
 and t.prod_subcat_code=p.prod_sub_cat_code
 where total_amt > 0
 group by P.prod_subcat
 order by sum(total_amt) desc)
 group by P.prod_subcat
 order by 2 desc ,3 desc

 /*11.For all customers aged between 25 to 35 years find what is the net total revenue generated by these consumers 
 in last 30 days of transactions from max transaction date available in the data?*/
 
 select sum(total_amt) as Revenue
 from Customer C
 left join Transactions T
 on T.cust_id=C.customer_Id
 where DATEDIFF(Year,DOB,convert(date,tran_date,105)) between 25 and 35 and
 convert(date,tran_date,105) between DATEADD(DAY,-30,(select max(convert(date,tran_date,105)) from transactions)) and 
 (select max(convert(date,tran_date,105)) from transactions)

--12.Which product category has seen the max value of returns in the last 3 months of transactions?
select top 1 prod_cat
from Transactions T
inner join prod_cat_info P
on t.prod_cat_code=p.prod_cat_code and t.prod_subcat_code=p.prod_sub_cat_code
where total_amt < 0 and 
CONVERT(date,tran_date,105) between DATEADD(MONTH,-3,(select max(convert(date,tran_date,105)) from transactions)) and
(select max(convert(date,tran_date,105))from Transactions)
group by prod_cat
order by (sum(total_amt)) desc

--13.Which store-type sells the maximum products; by value of sales amount and by quantity sold?

select top 1 Store_type,sum(total_amt) Total_sales, sum(Qty) Quantity
from Transactions
where total_amt>0 and Qty>0
group by Store_type
order by Total_sales desc

--14.What are the categories for which average revenue is above the overall average.

select prod_cat
from Transactions t
left join prod_cat_info p on t.prod_cat_code=p.prod_cat_code
and t.prod_subcat_code=p.prod_sub_cat_code
group by prod_cat
having AVG(total_amt)>=(select AVG(total_amt) from Transactions)


--15.Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold.

select p.prod_cat,p.prod_subcat , AVG(total_amt) Avg_revenue, sum(total_amt) Revenue
from Transactions t
left join prod_cat_info p on t.prod_cat_code=p.prod_cat_code
and t.prod_subcat_code=p.prod_sub_cat_code
where p.prod_cat in
(select top 5 prod_cat
from prod_cat_info p
left join Transactions t on t.prod_cat_code=p.prod_cat_code
and t.prod_subcat_code=p.prod_sub_cat_code
where qty >0
group by prod_cat
order by sum(Qty) desc)
group by p.prod_cat,p.prod_subcat
order by p.prod_cat