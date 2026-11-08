# Iowa Liquor Analytics

An analytics engineering project that models Iowa liquor sales with dbt on
BigQuery, using the public `bigquery-public-data.iowa_liquor_sales` dataset
from 2022 onward.

## Stack

- BigQuery (sandbox)
- dbt v2
- Python 3.12, managed with uv
- pre-commit, to block private keys from being committed

## Status

Work in progress. The environment and the raw table script
(`scripts/create_raw_iowa_sales.sql`) are in place; the dbt project is not
created yet.

## Setup

```sh
uv sync
uv run pre-commit install
```

## License

[MIT](LICENSE)
