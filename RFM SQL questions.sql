
/* ============================================================
   RFM Segmentation & Churn Risk — SQL Analysis
   Dataset: UCI Online Retail II (Dec 2009 – Dec 2011)
   Tool: PostgreSQL

   Structure:
   Q1–Q7   : RFM segmentation & value analysis
   Q8–Q9   : Retention & cohort analysis
   Q10–Q13 : Purchase-gap risk, regional segmentation, revenue-at-risk
   Churn Model Prep : Feature engineering + label construction for the 
                       Python churn model
   ============================================================ */




--Revenue and customer count per segment
-- Q1. For each customer segment, what is the total revenue generated and how many customers fall into it?
select segment ,sum(monetary) as total_revenue ,count(customer_id) as total_customers
from rfm_scored 
group by segment 
order by total_revenue desc, total_customers desc

--Average order value per segment
-- Q2. What is the average revenue per customer within each segment?
select segment ,round(avg(monetary),2) as avg_revenue
from rfm_scored 
group by segment 
order by avg_revenue desc

--Segments with abnormally high average revenue
-- Q3. Which segments have an average customer revenue more than double the overall average across all customers
select segment,round(avg(monetary),2)
from rfm_scored 
group by segment 
having avg(monetary)> 2*(select avg(monetary) from rfm_scored)

--Each segment's share of total revenue
-- Q4. What percentage of total company revenue does each segment account for?
with segment_share as (
				select segment,sum(monetary) over() as total_revenue ,sum(monetary)over(partition by segment)as rev_per_seg
				from rfm_scored
				)
select distinct  segment,round((rev_per_seg*100.0/total_revenue),2)	as percent_rev
from segment_share
order by percent_rev desc

-- Alternative approach (single subquery instead of window function)

select segment,round((sum(monetary)*100 /(select sum(monetary) as total_revenue from rfm_scored	)),2) as percent_segment
from rfm_scored
group by segment
order by percent_segment desc

--Total revenue at risk
-- Q5. How much total revenue is currently held by customers in the 'At Risk' and 'Needs Win-Back' segments combined?
select sum(monetary) as total_revenue 
from rfm_scored 
where segment ='At Risk' or segment='Needs Win-Back'

--Top 20 highest-value at-risk customers, ranked
-- Q6. List the top 20 customers (by revenue) within the 'At Risk' and 'Needs Win-Back' segments, ranked from highest to lowest.
with risk_customers as (
				select customer_id,monetary ,rank() over(order by monetary desc) as rnk 
				from rfm_scored
				where segment in ('At Risk' ,'Needs Win-Back')
				)
select customer_id,monetary ,rnk 
from risk_customers
where rnk <=20

--Revenue concentration in the top decile
-- Q7. Split all customers into 10 equal-sized groups based on revenue, 
-- and find out what percentage of total company revenue is held by the top group (the highest-spending 10% of customers)

with rev_conc as (select customer_id,monetary,ntile(10)over (order by monetary desc) as decile
from rfm_scored)
select round((sum(monetary)*100.0  /(select sum(monetary)  from rfm_scored)),2) as percent_of_total
from rev_conc
where decile =1

--Cohort Table
-- Q8. Step 1) Cohort month per customer
--For each customer, find the month of their very first purchase
select customer_id,min(Date_Trunc('month',invoice_date)) as cohort_month
from invoice_details
group by customer_id

--Step 2)Invoice month per row
--For every single purchase (every invoice), what month did that specific purchase happen in?
select customer_id,date_trunc('month',invoice_date) as month_of_purchase
from invoice_details

--join
with a as(
			select customer_id,min(Date_Trunc('month',invoice_date)) as cohort_month
			from invoice_details
			group by customer_id

),
b as (
		select customer_id,date_trunc('month',invoice_date) as month_of_purchase
        from invoice_details
)

select 
    b.customer_id,
    a.cohort_month,
    b.month_of_purchase,
	(extract(year from age(b.month_of_purchase,a.cohort_month))*12+
	extract(month from age(b.month_of_purchase, a.cohort_month)))as month_number
  
from b
join a on b.customer_id = a.customer_id

-- Reusable view: cohort month + month number per purchase (used in Q9)

create view cohort_base as
with a as(
			select customer_id,min(Date_Trunc('month',invoice_date)) as cohort_month
			from invoice_details
			group by customer_id

),
b as (
		select customer_id,date_trunc('month',invoice_date) as month_of_purchase
        from invoice_details
)

select 
    b.customer_id,
    a.cohort_month,
    b.month_of_purchase,
	(extract(year from age(b.month_of_purchase,a.cohort_month))*12+
	extract(month from age(b.month_of_purchase, a.cohort_month)))as month_number
  
from b
join a on b.customer_id = a.customer_id

-- Q9. Retention rate (%) by cohort month
with act_customers as (
select cohort_month,month_number,count(distinct customer_id ) as active_customers
from cohort_base 
group by cohort_month,month_number),

with_cohort_size as (
    select cohort_month, month_number, active_customers,
           first_value(active_customers) over(partition by  cohort_month order by month_number) as cohort_size
    from act_customers
)
select cohort_month, month_number, active_customers, cohort_size,
       round(active_customers * 100.0 / cohort_size, 2) as retention_pct
from with_cohort_size
order by cohort_month, month_number

--Days between purchases per customer
-- Q10. For every purchase a customer makes, how many days passed since their previous purchase?
with purchase_difference as (select distinct customer_id,invoice,invoice_date
from invoice_details)
select customer_id,invoice,invoice_date,lag(invoice_date)over(partition by customer_id order by invoice_date) as prev_purchase,(invoice_date-(lag(invoice_date)over(partition by customer_id order by invoice_date))) as diff_days 
from purchase_difference

-- Reusable view: purchase gap per customer

create view  purchases_gap as (
with purchase_difference as (select distinct customer_id,invoice,invoice_date
from invoice_details)
select customer_id,invoice,invoice_date,lag(invoice_date)over(partition by customer_id order by invoice_date) as prev_purchase,(invoice_date-(lag(invoice_date)over(partition by customer_id order by invoice_date))) as diff_days 
from purchase_difference
)

-- Q11. Which customers show a significant widening in their purchase gap 
-- (most recent gap more than 2x their historical average), signaling early churn risk?
create view wide_gaps as (
with ranked as (
select  customer_id, invoice_date, prev_purchase, diff_days,row_number()over(partition by customer_id order by invoice_date desc,invoice desc)as rnk
from purchases_gap
),

recent_gap as (
select customer_id, invoice_date, prev_purchase, diff_days as recent_diff
from ranked 
where rnk=1),

avg_difference as (
select customer_id,  diff_days 
from ranked 
where rnk>1),

average_gap as(
select customer_id, avg(diff_days) as avg_diff
from avg_difference
group by customer_id)

select r.customer_id,r.invoice_date as last_purchase ,
r.recent_diff,a.avg_diff
from  recent_gap r
join average_gap a on r.customer_id = a.customer_id
where r.recent_diff > 2 * a.avg_diff
and a.avg_diff >= INTERVAL '1 day'
order by r.customer_id )

select count(*) from wide_gaps
SELECT pg_get_viewdef('wide_gaps');


-- Q12. How does customer segment distribution and revenue differ 
-- between UK and International customers?
with country_group as (
 select distinct customer_id,country from invoice_details),
sub_division as (
select r.customer_id,r.segment,r.monetary,
case when country='United Kingdom' then'UK' else 'International' end as region
from rfm_scored r join country_group c
on r.customer_id=c.customer_id
) 
select region ,segment,count(customer_id)as customer_count,sum(monetary)as total_rev,round(avg(monetary),2) as avg_rev
from sub_division
group by region, segment
order by region, total_rev desc


-- Reusable view (built for Q13's regional revenue breakdown)

create view  sub_division_1 as (with country_group as (
 select distinct customer_id,country from invoice_details),
sub_division as (
select r.customer_id,r.segment,r.monetary,
case when country='United Kingdom' then'UK' else 'International' end as region
from rfm_scored r join country_group c
on r.customer_id=c.customer_id)
select customer_id, segment, monetary, region
   from sub_division)
   

-- Q13. What percentage of each region's revenue is currently held by 
-- At-Risk / Needs-Win-Back customers — and how does UK compare to International?
with region_revenue as (
select region,
sum(monetary)filter (where segment in('At Risk','Needs Win-Back')) as risk_revenue,
sum(monetary) as total_revenue
from sub_division_1
group by region)

select region,risk_revenue,total_revenue,round((risk_revenue*100.0/total_revenue),2) as percent_risk
from region_revenue

-----------------------------

--Prep for churn model
-- Step 1: Determine typical purchase-gap distribution (to set a churn threshold)
with purchase_days as (
    select distinct
        customer_id,
        date(invoice_date) as purchase_date
    from invoice_details
),
gaps as (
    select
        customer_id,
        purchase_date,
        purchase_date - lag(purchase_date) over (
            partition by customer_id
            order by purchase_date
        ) as gap_days
    from purchase_days
)
select
   percentile_cont (0.5) within group (order by gap_days) as median_gap,
   percentile_cont  (0.75) within group ( order by gap_days) as p75_gap,
   percentile_cont  (0.90) within group ( order by gap_days) as p90_gap,
    round(avg(gap_days),2) as mean_gap,
    count(gap_days) as total_gaps
from gaps

-- Step 2: Confirm dataset date range (to pick a fair cutoff date)

select min(invoice_date),max(invoice_date) from invoice_details
where gap_days is not null

-- Step 3: Draft churn labeling logic

with purchase_days as ( select distinct
        customer_id,
        date(invoice_date) as purchase_date
    from invoice_details),
	
pre_cutoff as (
select customer_id,purchase_date
from purchase_days
where purchase_date<'2011-06-01'
),
post_cutoff as (
select customer_id,purchase_date
from purchase_days
where purchase_date>='2011-06-01'
),
features as (
select p.customer_id,
date '2011-06-01'- max(p.purchase_date) as recency,
count(*) as frequency,
sum(total_amount) as monetary
from pre_cutoff p
join invoice_details d
on d.customer_id=p.customer_id
and date(d.invoice_date)=p.purchase_date
group by p.customer_id
),
next_purchase as (
select customer_id,min(purchase_date) as first_post_cutoff_purchase
from post_cutoff
group by customer_id
),
labels as (
select f.customer_id,
case when n.first_post_cutoff_purchase is null then 1
when n.first_post_cutoff_purchase - (date '2011-06-01'-f.recency)>90 then 1 
else 0
end as churned 
from features f
left join next_purchase n on n.customer_id=f.customer_id)

select 
	f.customer_id,
    f.recency,
    f.frequency,
    f.monetary,
    l.churned

from features f 
join labels l on l.customer_id=f.customer_id


-- Step 4: Final churn_feature view — active customers only, leakage-corrected
create view churn_feature as
with purchase_days as (
    select distinct
        customer_id,
        DATE(invoice_date) as purchase_date
    from invoice_details
),
pre_cutoff as (
    select customer_id, purchase_date
    from purchase_days
    where purchase_date < '2011-06-01'
),
post_cutoff as (
    select customer_id, purchase_date
    from purchase_days
    where purchase_date >= '2011-06-01'
),
features as (
    select
        p.customer_id,
        DATE '2011-06-01' - max(p.purchase_date) as recency,
        count(*) as frequency,
        sum(d.total_amount) as monetary
    from pre_cutoff p
    join invoice_details d
        on d.customer_id = p.customer_id
        and DATE(d.invoice_date) = p.purchase_date
    group by p.customer_id
),
next_purchase as (
    select customer_id, min(purchase_date) as first_post_cutoff_purchase
    from post_cutoff
    group by customer_id
),
labels as (
    select
        f.customer_id,
        case
            when n.first_post_cutoff_purchase is null then 1
            when n.first_post_cutoff_purchase - (DATE '2011-06-01' - f.recency) > 90 then 1
            else 0
        end as churned
    from features f
    left join next_purchase n on n.customer_id = f.customer_id
	
)

select
    f.customer_id,
    f.recency,
    f.frequency,
    f.monetary,
    l.churned
from features f
join labels l on l.customer_id = f.customer_id
where f.recency <= 135

--Validation

-- Check class balance of churn labels

select  churned, count(*), ROUND(100.0 * count(*) / sum(count(*)) over (), 1) as pct
from churn_feature
group by churned


-- Churn rate by purchase frequency (1 purchase vs. 2+)

select
    case when frequency = 1 then '1 purchase' else '2+ purchases' end as buyer_type,
    churned,
    count(*) as num_customers
from churn_feature
group by buyer_type, churned
order by buyer_type, churned


-- Churn rate by recency bucket, repeat customers only
select
    case
        when recency <= 90 then 'recency <= 90 at cutoff'
        when recency <= 180 then 'recency 91-180 at cutoff'
        else 'recency > 180 at cutoff'
    end as  recency_bucket,
    churned,
    count(*) as num_customers
from churn_feature
where frequency >= 2
group by recency_bucket, churned
order by  recency_bucket, churned


-- Confirm wide_gaps view logic and final count
select count(*) from wide_gaps


-- Confirm At-Risk / Needs-Win-Back customer count and revenue
select 
    count(*) as at_risk_customer_count
from rfm_scored
where segment in ('At Risk', 'Needs Win-Back')

select 
    segment,
    count(*) as customer_count,
    sum(monetary) as total_revenue
from rfm_scored
where segment in ('At Risk', 'Needs Win-Back')
group by segment
order by total_revenue desc
