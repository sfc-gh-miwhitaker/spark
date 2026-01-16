![Reference Implementation](https://img.shields.io/badge/Reference-Implementation-blue)
![Ready to Run](https://img.shields.io/badge/Ready%20to%20Run-Yes-green)
![Expires](https://img.shields.io/badge/Expires-2026--02--15-orange)

# Run Your PySpark Code on Snowflake

> DEMONSTRATION PROJECT - EXPIRES: 2026-02-15  
> This demo uses Snowflake features current as of January 2026.  
> After expiration, this repository will be archived and made private.

**Author:** SE Community  
**Purpose:** Reference implementation for running PySpark code on Snowflake  
**Created:** 2026-01-16 | **Expires:** 2026-02-15 (30 days) | **Status:** ACTIVE

---

## Your Code. Snowflake's Compute. One Line Change.

**Skeptical?** You should be. Here's exactly what changes:

```python
# BEFORE: Standard PySpark
from pyspark.sql import SparkSession
spark = SparkSession.builder.getOrCreate()

# AFTER: PySpark on Snowflake
from snowflake import snowpark_connect
spark = snowpark_connect.server.init_spark_session()
```

**That's the entire migration.** Everything below that line stays the same:

```python
# This code runs unchanged on Snowflake
from pyspark.sql import functions as F
from pyspark.sql.window import Window

df = spark.createDataFrame(data)
df.filter(F.col("amount") > 100).groupBy("region").agg(F.sum("amount"))
```

---

## What Works

| PySpark API | Status |
|-------------|--------|
| `spark.createDataFrame()` | ✓ Works |
| `spark.table()` / `spark.sql()` | ✓ Works |
| `.select()`, `.filter()`, `.where()` | ✓ Works |
| `.groupBy().agg()` | ✓ Works |
| `.join()` | ✓ Works |
| Window functions | ✓ Works |
| `.write.saveAsTable()` | ✓ Works |
| UDFs (Python) | ✓ Works |
| Iceberg tables | ✓ Works |

For the complete compatibility matrix, see the [Snowpark Connect Compatibility Guide](https://docs.snowflake.com/en/developer-guide/snowpark-connect/compatibility).

**Have a large codebase?** The [Snowpark Migration Accelerator](https://docs.snowflake.com/en/developer-guide/snowpark-migration-accelerator) scans your code and reports compatibility.

---

## Quick Start

### Option A: Deploy from GitHub (Recommended)

Deploy notebooks directly from this repository using Snowflake's Git integration.

1. Copy [`deploy_notebooks.sql`](deploy_notebooks.sql) 
2. Open **Snowsight → SQL Worksheet**
3. Paste and click **Run All**
4. Open the notebooks in **Notebooks → SNOWFLAKE_EXAMPLE.SPARK_NOTEBOOKS**
5. Add `snowpark_connect` from the **Packages** menu
6. Run the notebooks

**What gets created:**
- Git repository clone pointing to this repo
- Two notebooks: `SPARK_ON_SNOWFLAKE` and `SPARK_ICEBERG_TABLES`

### Option B: Import Notebooks Manually

1. Download a notebook from the [`notebooks/`](notebooks/) folder
2. Open **Snowsight → Notebooks → Import .ipynb file**
3. Configure:
   - **Runtime:** Run on warehouse
   - **Runtime version:** Snowflake Warehouse Runtime 2.0
4. Add `snowpark_connect` from the **Packages** menu
5. Run

### Option C: Local Jupyter

**Requires Python 3.10, 3.11, or 3.12**

```bash
# Create environment
python3.11 -m venv .venv
source .venv/bin/activate

# Install
pip install snowpark-connect[jdk] jupyterlab

# Configure Snowflake connection
snow connection add --connection-name spark-connect

# Run
jupyter lab notebooks/spark_on_snowflake.ipynb
```

---

## What's in This Repo

```
spark/
├── README.md                           # You are here
├── deploy_notebooks.sql                # One-click deployment script
└── notebooks/
    ├── environment.yml                 # Package dependencies (auto-loaded from stage)
    ├── spark_on_snowflake.ipynb        # Basic PySpark operations
    └── spark_iceberg_tables.ipynb      # Iceberg table read/write
```

### Notebooks

| Notebook | What It Demonstrates |
|----------|---------------------|
| `spark_on_snowflake.ipynb` | DataFrame creation, filters, aggregations, window functions, Spark SQL, writing tables |
| `spark_iceberg_tables.ipynb` | Creating Iceberg tables, reading with PySpark, transforms, writing results back |

---

## What You Don't Need

| Traditional Spark | Snowflake |
|-------------------|-----------|
| Provision EMR/Databricks cluster | Not needed |
| Configure Spark settings | Not needed |
| Manage executor memory | Not needed |
| Set up data connectors | Not needed |
| Move data to Spark | Not needed |
| Manage separate infrastructure | Not needed |

Your PySpark code runs on Snowflake's warehouses. Data stays in Snowflake. No ETL pipelines to build.

---

## FAQ

**Q: Will my existing notebooks work?**  
A: If they use the standard PySpark DataFrame API, yes. Change the session initialization, keep everything else.

**Q: What about Spark MLlib?**  
A: MLlib is not supported. Use [Snowflake ML](https://docs.snowflake.com/en/developer-guide/snowflake-ml/overview) for machine learning on Snowflake.

**Q: What about Spark Streaming?**  
A: Streaming is not supported. Use [Snowpipe Streaming](https://docs.snowflake.com/en/user-guide/data-load-snowpipe-streaming-overview) for real-time ingestion.

**Q: Do I need a Spark cluster?**  
A: No. Your code runs on Snowflake warehouses. The DataFrame API calls are translated to Snowflake SQL.

**Q: What's the performance like?**  
A: Your queries run on Snowflake's query engine. Performance depends on your warehouse size and data, just like any Snowflake query.

**Q: Can I use this in production?**  
A: Yes. Snowpark Connect is generally available. This demo repo expires, but the feature doesn't.

---

## Resources

- [Snowpark Connect Documentation](https://docs.snowflake.com/en/developer-guide/snowpark-connect)
- [API Compatibility Guide](https://docs.snowflake.com/en/developer-guide/snowpark-connect/compatibility)
- [Migration Accelerator](https://docs.snowflake.com/en/developer-guide/snowpark-migration-accelerator) - Scan your codebase for compatibility
- [Iceberg Tables in Snowflake](https://docs.snowflake.com/en/user-guide/tables-iceberg)

---

## License

Apache 2.0
