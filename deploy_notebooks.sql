/*******************************************************************************
 * Spark on Snowflake - Notebook Deployment
 *
 * PURPOSE:
 *   Single-script deployment of PySpark notebooks via Git integration.
 *   Copy/paste into Snowsight and run to deploy notebooks from GitHub.
 *
 * USAGE IN SNOWSIGHT:
 *   1. Copy this ENTIRE script (Cmd/Ctrl+A, Cmd/Ctrl+C)
 *   2. Open Snowsight -> New SQL Worksheet
 *   3. Paste the script (Cmd/Ctrl+V)
 *   4. Click "Run All" or press Cmd/Ctrl+Shift+Enter
 *   5. Navigate to Notebooks to find the deployed notebooks
 *
 * WHAT GETS CREATED:
 *   - SFE_GITHUB_API_INTEGRATION (API Integration for GitHub access)
 *   - SNOWFLAKE_EXAMPLE database
 *   - SNOWFLAKE_EXAMPLE.GIT_REPOS schema (Git repository clones)
 *   - SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SPARK_NOTEBOOKS_REPO (Git repository)
 *   - SNOWFLAKE_EXAMPLE.SPARK_NOTEBOOKS schema (notebook storage)
 *   - Notebooks: SPARK_ON_SNOWFLAKE, SPARK_ICEBERG_TABLES
 *
 * PREREQUISITES:
 *   - ACCOUNTADMIN role access (or role with CREATE INTEGRATION privilege)
 *   - Network access to GitHub
 *
 * AFTER DEPLOYMENT:
 *   1. Open each notebook in Snowsight
 *   2. Add the `snowpark_connect` package from the Packages menu
 *   3. Run the notebooks
 *
 * SAFE TO RE-RUN:
 *   Yes. All statements use OR REPLACE or IF NOT EXISTS patterns.
 *
 * GIT REPOSITORY:
 *   https://github.com/sfc-gh-miwhitaker/spark
 *
 * Author: SE Community
 * License: Apache 2.0
 ******************************************************************************/

-- ============================================================================
-- PHASE 1: INFRASTRUCTURE SETUP
-- ============================================================================

USE ROLE SYSADMIN;

-- Create shared demo database and schemas
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
    COMMENT = 'Shared demo database for Snowflake examples';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS
    COMMENT = 'Shared Git repository clones for demo deployments';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SPARK_NOTEBOOKS
    COMMENT = 'PySpark notebooks using Snowpark Connect';

-- Elevate privilege for API integration
USE ROLE ACCOUNTADMIN;

-- Create GitHub API integration (safe to rerun; reused by all demo projects)
CREATE API INTEGRATION IF NOT EXISTS SFE_GITHUB_API_INTEGRATION
    API_PROVIDER = git_https_api
    ENABLED = TRUE
    API_ALLOWED_PREFIXES = ('https://github.com/')
    COMMENT = 'GitHub integration for Git-based deployments';

-- Grant usage to deployment role
GRANT USAGE ON INTEGRATION SFE_GITHUB_API_INTEGRATION TO ROLE SYSADMIN;

-- ============================================================================
-- PHASE 2: GIT REPOSITORY SETUP
-- ============================================================================

USE ROLE SYSADMIN;

-- Create Git repository clone
CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SPARK_NOTEBOOKS_REPO
    API_INTEGRATION = SFE_GITHUB_API_INTEGRATION
    ORIGIN = 'https://github.com/sfc-gh-miwhitaker/spark.git'
    COMMENT = 'PySpark on Snowflake demo notebooks';

-- Fetch latest from remote
ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SPARK_NOTEBOOKS_REPO FETCH;

-- ============================================================================
-- PHASE 3: DEPLOY NOTEBOOKS
-- ============================================================================

-- List available notebooks in repository
SELECT "name", "size" 
FROM DIRECTORY(@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SPARK_NOTEBOOKS_REPO/branches/main/notebooks/)
WHERE "name" LIKE '%.ipynb';

-- Create notebook: Spark on Snowflake (basic PySpark operations)
CREATE OR REPLACE NOTEBOOK SNOWFLAKE_EXAMPLE.SPARK_NOTEBOOKS.SPARK_ON_SNOWFLAKE
    FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SPARK_NOTEBOOKS_REPO/branches/main/notebooks/'
    MAIN_FILE = 'spark_on_snowflake.ipynb'
    COMMENT = 'PySpark DataFrame operations on Snowflake compute';

-- Create notebook: Spark with Iceberg Tables
CREATE OR REPLACE NOTEBOOK SNOWFLAKE_EXAMPLE.SPARK_NOTEBOOKS.SPARK_ICEBERG_TABLES
    FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SPARK_NOTEBOOKS_REPO/branches/main/notebooks/'
    MAIN_FILE = 'spark_iceberg_tables.ipynb'
    COMMENT = 'Read and write Iceberg tables with PySpark';

-- ============================================================================
-- DEPLOYMENT COMPLETE
-- ============================================================================

-- Show deployed notebooks
SHOW NOTEBOOKS IN SCHEMA SNOWFLAKE_EXAMPLE.SPARK_NOTEBOOKS;

SELECT
    '✓ DEPLOYMENT COMPLETE' AS status,
    CURRENT_TIMESTAMP() AS completed_at,
    'Open notebooks in Snowsight: Notebooks > SNOWFLAKE_EXAMPLE.SPARK_NOTEBOOKS' AS next_step_1,
    'Add snowpark_connect package from the Packages menu' AS next_step_2,
    'Run the notebooks!' AS next_step_3;

/*******************************************************************************
 * CLEANUP (Optional)
 * Uncomment and run to remove all objects created by this script.
 *******************************************************************************

DROP NOTEBOOK IF EXISTS SNOWFLAKE_EXAMPLE.SPARK_NOTEBOOKS.SPARK_ON_SNOWFLAKE;
DROP NOTEBOOK IF EXISTS SNOWFLAKE_EXAMPLE.SPARK_NOTEBOOKS.SPARK_ICEBERG_TABLES;
DROP GIT REPOSITORY IF EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SPARK_NOTEBOOKS_REPO;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SPARK_NOTEBOOKS;
-- Note: Leaving GIT_REPOS schema and API integration for other demos

 ******************************************************************************/
