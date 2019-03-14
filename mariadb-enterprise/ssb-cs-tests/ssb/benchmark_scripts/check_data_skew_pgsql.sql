SELECT gp_segment_id, COUNT(*) FROM orders.part GROUP BY gp_segment_id ORDER BY gp_segment_id;
SELECT gp_segment_id, COUNT(*) FROM orders.supplier GROUP BY gp_segment_id ORDER BY gp_segment_id;
SELECT gp_segment_id, COUNT(*) FROM orders.customer GROUP BY gp_segment_id ORDER BY gp_segment_id;
SELECT gp_segment_id, COUNT(*) FROM orders.dimdate GROUP BY gp_segment_id ORDER BY gp_segment_id;
SELECT gp_segment_id, COUNT(*) FROM orders.lineorder GROUP BY gp_segment_id ORDER BY gp_segment_id;

/*Shows the number of rows per segment as well as the variance from the minimum and maximum numbers of rows */
SELECT 'Part Table' AS "Part", 
    max(c) AS "Max Seg Rows", min(c) AS "Min Seg Rows", 
    (max(c)-min(c))*100.0/max(c) AS "Percentage Difference Between Max & Min" 
FROM (SELECT count(*) c, gp_segment_id FROM orders.part GROUP BY 2) AS a;

SELECT 'Supplier Table' AS "Supplier", 
    max(c) AS "Max Seg Rows", min(c) AS "Min Seg Rows", 
    (max(c)-min(c))*100.0/max(c) AS "Percentage Difference Between Max & Min" 
FROM (SELECT count(*) c, gp_segment_id FROM orders.supplier GROUP BY 2) AS a;

SELECT 'Customer Table' AS "Customer", 
    max(c) AS "Max Seg Rows", min(c) AS "Min Seg Rows", 
    (max(c)-min(c))*100.0/max(c) AS "Percentage Difference Between Max & Min" 
FROM (SELECT count(*) c, gp_segment_id FROM orders.customer GROUP BY 2) AS a;

SELECT 'DWDate Table' AS "DWDate", 
    max(c) AS "Max Seg Rows", min(c) AS "Min Seg Rows", 
    (max(c)-min(c))*100.0/max(c) AS "Percentage Difference Between Max & Min" 
FROM (SELECT count(*) c, gp_segment_id FROM orders.dimdate GROUP BY 2) AS a;

SELECT 'Lineorder Table' AS "Lineorder", 
    max(c) AS "Max Seg Rows", min(c) AS "Min Seg Rows", 
    (max(c)-min(c))*100.0/max(c) AS "Percentage Difference Between Max & Min" 
FROM (SELECT count(*) c, gp_segment_id FROM orders.lineorder GROUP BY 2) AS a;

/*Shows data distribution skew by calculating the coefficient of variation (CV) for the data stored on each segment. Higher values for skccoeff column indicate greater data skew.*/
select * from gp_toolkit.gp_skew_coefficients;

/*shows data distribution skew by calculating the percentage of the system that is idle during a table scan, which is an indicator of computational skew. For example, a value of 0.1 for siffraction column indicates 10% skew, a value of 0.5 indicates 50% skew, and so on. Tables that have more than10% skew should have their distribution policies evaluated.*/

select * from gp_toolkit.gp_skew_idle_fractions;

/* Checking Query Disk Spill Space Usage */
select * from gp_workfile_entries;
select * from gp_workfile_usage_per_query;
select * from gp_workfile_usage_per_segment;
