/* To use it, make sure statistics are up to date for all of the tables in the database, then run the following SQL
The results include only tables with moderate or significant bloat. Moderate bloat is reported when the ratio of actual to expected pages is greater than four and less than ten. Significant bloat is reported when the ratio is greater than ten. */

SELECT * FROM gp_toolkit.gp_bloat_diag;
SELECT * FROM gp_toolkit.gp_bloat_expected_pages LIMIT 5;
