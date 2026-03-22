Download Google Cloud CLI and configure your project settings using the commands below.
You can skip this step if you are using [Cloud shell](https://docs.cloud.google.com/shell/docs/launching-cloud-shell) which already comes with gcloud preinstalled:
```
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
```

Enable BigQuery permissions for this project if they haven't enabled already:
```
# 1. Store the active project ID and authenticated email in variables for convenience
export PROJECT_ID=$(gcloud config get-value project)
export USER_EMAIL=$(gcloud config get-value account)

# 2. Grant the BigQuery User role (Fixes datasets.create and jobs.create)
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="user:$USER_EMAIL" \
    --role="roles/bigquery.user"
```

Create the dataset and table in BigQuery:
```
bq mk --dataset test

bq query --use_legacy_sql=false < create.sql
```

Load the data in the table:
```
wget --continue --progress=dot:giga 'https://datasets.clickhouse.com/hits_compatible/hits.csv.gz'

# No need to unzip, BigQuery can load from GZIP compressed CSV file.:
echo -n "Load time: "
command time -f '%e' bq load --source_format CSV --allow_quoted_newlines=1 test.hits hits.csv.gz
```

Run the benchmark:
```
pip install google-cloud-bigquery
python3 run_queries.py > results.txt 2> log.txt
```
