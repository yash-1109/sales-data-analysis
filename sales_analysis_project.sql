create database new_project;
use new_project;

select * from new_project.calender_file	 limit 10;

desc new_project.calender_file;

set sql_safe_updates =0;
update new_project.calender_file
set `Date` = str_to_date(`Date`, '%d-%m-%y');
set sql_safe_updates =1;

alter table  new_project.calender_file
modify Date Date;

select * from new_project.sales	 limit 10;
desc new_project.sales;

set sql_safe_updates =0;
update new_project.sales
set `OrderDate` = str_to_date(`OrderDate`, '%d-%m-%Y');

update new_project.sales
set	`ShipDate` = str_to_date(`ShipDate`,'%d-%m-%Y');
set sql_safe_updates =1;

alter table  new_project.sales
modify OrderDate Date,
modify ShipDate Date; 
use new_project; 

select * from new_project.calender_file 
where Date is null or
'Year' is null or
'Quarter' is null or
'Quarter(Q)' is null or
'Quarter_&_Year' is null or
'Month' is null or	
'Month_Name' is null or	
'Month_&_Year' is null or	
'Week_of_Year' is null or	
'Week_of_Year(W)' is null or	
'Day_of_Week' is null or	
'Day_Name' is null ;
 desc new_project.sales;
 
 
 -- 1. year-over-year(YOY) sales & profit growth
 
 select  new_project.calender_file.Year , round(Sum(new_project.sales.Sales),2) as total_sales,
			  round(Sum(new_project.sales.Profit),2) as total_profit
from  new_project.sales 
join new_project.calender_file 
on  new_project.sales.OrderDate = calender_file.Date 
group by new_project.calender_file.Year 
order by new_project.calender_file.Year;

-- 2. Seasonality (The Weekend Effect)

select new_project.calender_file.Day_Name,
              round(sum(new_project.sales.Sales),2) as total_sales,
              sum(case when new_project.sales.Returned = 'yes' then 1 else 0 end) as total_returns
from new_project.sales
join new_project.calender_file
on  new_project.sales.OrderDate = calender_file.Date 
group by new_project.calender_file.Day_name
order by new_project.calender_file.Day_Name;

-- 3. The Best Quarter

select new_project.calender_file.Year,
       new_project.calender_file.`Quarter(Q)`,
       round(sum(new_project.sales.Sales),2) as total_sales
from new_project.sales
join new_project.calender_file
on  new_project.sales.OrderDate = calender_file.Date 
group by new_project.calender_file.Year,
		new_project.calender_file.`Quarter(Q)`
order by total_sales desc
limit  1;

-- 4. The Discount Trap

select new_project.sales.`Category`,`Sub-Category`,
      round(sum(new_project.sales.Sales),2) as total_sales,
      round(avg(Discount)*100,2) as avg_discount_pct,
      round(sum(Profit),2) as total_profit
 from new_project.sales
group by new_project.sales.`Category`,
		new_project.sales.`Sub-Category`
order by total_profit asc;

-- 5. The Return Problem

select new_project.sales.Region,count(*) as total_orders,
       sum(case when Returned = 'Yes' then 1 else 0 end)  as returned_orders, 
     round((sum(case when Returned = 'Yes' then 1 else 0 end)/ count(*)) * 100,2)
      as return_rate_prcnt
from new_project.sales
group by new_project.sales.Region
order by return_rate_prcnt desc;

-- 6. Top 10 Loss-Making Customers


select new_project.sales.`Customer_ID`,`Customer_Name`,
      round(sum(new_project.sales.Sales),2) as total_sales,
      round(sum(new_project.sales.Profit),2) as total_loss
from new_project.sales
group by new_project.sales.`Customer_ID`,
		new_project.sales.`Customer_Name`
        having total_loss < 0
        order by total_loss asc
		limit 10;

-- 7. Shipping Delay Analysis

select new_project.sales.`Ship_Mode`,
       round(avg(datediff(new_project.sales.ShipDate,OrderDate)),2) as avg_shipping_days
from new_project.sales
group by new_project.sales.`Ship_Mode`
order by avg_shipping_days;

-- 8. Late Delivery Impact

with shippingdata as(
     select new_project.sales.`Order_ID`,Returned,
     datediff(ShipDate,OrderDate) as delivery_days
from new_project.sales )
select 
     case when delivery_days > 3 then 'Late (> 3 days)' else 'on Time (<= 3 days)' end
     as delivery_status,
     count(*) as total_orders,
     sum(case when Returned = 'Yes' then 1 else 0 end) as returned_orders,
      round((sum(case when Returned = 'Yes' then 1 else 0 end)/count(*)) *100,2) as returned_rate_prcnt
      from shippingdata
      group by delivery_status;
      
      -- 9. Salesperson Performance
      
select new_project.sales.Retail_Sales_People, 
      round(sum(new_project.sales.Sales),2) as total_sales,
      round(sum(new_project.sales.Profit),2) as total_profit,
      round((sum(Profit)/sum(Sales))*100,2) as profit_margin_Prct
from new_project.sales
group by new_project.sales.Retail_Sales_People
order by total_sales desc;

-- 10. The Pareto Principle (80/20 Rule)

with customers_sales as(
    select Customer_ID,
           sum(sales) as total_sales
	from new_project.sales
	group by Customer_ID),

ranked_customers as (
    select Customer_ID,
           total_sales,
           sum(total_sales) over (order by total_sales desc) as running_total,
           (select sum(sales) from new_project.sales) as grand_total 
    from customers_sales)
    
select 
       count(Customer_ID) as top_customers_count,
       (select count(distinct Customer_ID) from new_project.sales) as total_customers,
       round((count(Customer_ID) / (select count( distinct Customer_ID) from new_project.sales)) *100 ,2)
       as pct_of_cust_generating_80_pct_sales
  from ranked_customers
  where running_total <= grand_total * 0.80;
  
 -- 11. Customer Churn

with customer_years as (
    select new_project.s.Customer_ID,new_project.c.Year
    from  new_project.sales s
    join  new_project.calender_file c
    on c.Date = s.OrderDate
    group by s.Customer_ID, c.Year
    )
select distinct Customer_ID from customer_years 
where Customer_ID in (select Customer_ID from customer_years
where Year in (2015,2016))
and Customer_ID not in ( select Customer_ID from customer_years 
where Year = 2017);

-- 12. 30-Day Moving Average

with daily_sales as (
 select c.Date as order_date,
     sum(s.sales) as daily_sales
     from sales s
     join calender_file c
     on c.Date = s.OrderDate
     group by order_date)
     
select 
    order_date,
    daily_sales,
    (avg(daily_sales) over(order by order_date 
    rows between 29 preceding and current row)) as 30_day_moving_avg
from daily_sales
order by order_date;
  
-- 13. Customer Segmentation (Mini RFM) 

select 
      new_project.sales.Customer_ID,
      new_project.sales.Customer_Name,
      count(Distinct Order_ID) as toral_orders,
      round(sum(Sales),2)  as total_sales,
      case 
          when count(distinct Order_ID) = 1 then 'one_time_buyer'
          when sum(sales) > 5000 then 'VIP'
          else 'regular' end as customer_segment
          from sales
          group by customer_ID,
                   Customer_Name
		  order by total_sales desc;
	   

-- 14. Month-over-Month (MoM) Growth

with  monthly_sales as (
	 select new_project.c.Year,
            new_project.c.Month,
            sum(s.sales) as current_month_sales
            from sales s
            join calender_file c 
            on c.Date  = s.OrderDate
            group by c.Year, c.Month)
	select Year,Month,
          round(current_month_sales,2) as current_sales,
          round(lag(current_month_sales) over (order by Year,Month),2) as prev_month_sales,
         round((((current_month_sales - lag(current_month_sales)over(order by Year,Month ))
          /lag(current_month_sales ) over (order by Year ,Month)) *100),2)
          as mon_growth_pct
	from monthly_sales;
    
    -- 15. Most Profitable Route
    
    select 
          State ,City,
          count(Order_ID) as total_orders,
          round(sum(profit),2) as total_profit,
          round(sum(profit)/count(Order_ID),2 )as profit_per_order
          from Sales
          group by State,City
          having total_orders >10
          order by profit_per_order desc
          limit 5;