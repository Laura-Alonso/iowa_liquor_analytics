-- Builds the raw Iowa liquor sales table: copies sales from 2022-01-01 onward
-- from the BigQuery public dataset into `iowa-liquor-lab.raw.iowa_sales`.
-- Safe to re-run: the dataset is created only if missing and the table is replaced.
--
-- Clustered instead of partitioned: the BigQuery sandbox expires partitions after
-- 60 days, so date partitions older than that would be deleted, losing history.

create schema if not exists `iowa-liquor-lab.raw`
options (location = 'US');

create or replace table `iowa-liquor-lab.raw.iowa_sales`
cluster by date as
select *
from `bigquery-public-data.iowa_liquor_sales.sales`
where date >= '2022-01-01';
