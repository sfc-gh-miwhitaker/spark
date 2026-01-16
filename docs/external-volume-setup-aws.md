# Setting Up an External Volume for Iceberg Tables (AWS S3)

This guide walks through creating an external volume in Snowflake backed by AWS S3 for storing Iceberg tables.

## Overview

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│   Snowflake     │ ──────► │    IAM Role     │ ──────► │    S3 Bucket    │
│ External Volume │         │ (Trust Policy)  │         │  (Iceberg Data) │
└─────────────────┘         └─────────────────┘         └─────────────────┘
```

**Components:**
1. **S3 Bucket** - Stores Iceberg table data (Parquet files + metadata)
2. **IAM Policy** - Grants read/write permissions to the bucket
3. **IAM Role** - Assumable by Snowflake with the policy attached
4. **External Volume** - Snowflake object pointing to the S3 location

---

## Step 1: Create S3 Bucket

1. Go to **AWS Console > S3 > Create bucket**
2. Configure:
   - **Bucket name**: Choose a unique name (e.g., `mycompany-iceberg-data`)
   - **Region**: Select your preferred region (note this for later)
   - **Block Public Access**: Keep enabled (default)
   - **Versioning**: Optional, but recommended for production
3. Click **Create bucket**

---

## Step 2: Create IAM Policy

1. Go to **AWS Console > IAM > Policies > Create policy**
2. Select **JSON** tab and paste:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:DeleteObject",
                "s3:DeleteObjectVersion"
            ],
            "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME"
        }
    ]
}
```

3. Replace `YOUR_BUCKET_NAME` with your actual bucket name
4. Name the policy (e.g., `snowflake-iceberg-s3-access`)
5. Click **Create policy**

**Common Mistake:** The first Resource ARN must end with `/*` (for objects), while the second must NOT have a trailing slash or wildcard (for bucket-level operations).

```
CORRECT:
  "Resource": "arn:aws:s3:::my-bucket/*"    <- objects
  "Resource": "arn:aws:s3:::my-bucket"      <- bucket

WRONG:
  "Resource": "arn:aws:s3:::my-bucket/"     <- trailing slash breaks it
```

---

## Step 3: Create IAM Role

1. Go to **AWS Console > IAM > Roles > Create role**
2. Select **Custom trust policy** and paste this placeholder:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::000000000000:user/placeholder"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "placeholder"
                }
            }
        }
    ]
}
```

3. Click **Next**
4. Search for and attach the policy you created in Step 2
5. Name the role (e.g., `snowflake-iceberg-role`)
6. Click **Create role**
7. **Copy the Role ARN** - you'll need it for Snowflake

---

## Step 4: Create External Volume in Snowflake

Run this SQL in Snowflake (requires ACCOUNTADMIN or CREATE EXTERNAL VOLUME privilege):

```sql
CREATE EXTERNAL VOLUME my_iceberg_volume
    STORAGE_LOCATIONS = (
        (
            NAME = 'my-s3-location'
            STORAGE_PROVIDER = 'S3'
            STORAGE_BASE_URL = 's3://YOUR_BUCKET_NAME/'
            STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::YOUR_AWS_ACCOUNT:role/YOUR_ROLE_NAME'
            STORAGE_AWS_EXTERNAL_ID = 'my_external_id'
        )
    );
```

Replace:
- `YOUR_BUCKET_NAME` - Your S3 bucket name
- `YOUR_AWS_ACCOUNT` - Your 12-digit AWS account ID
- `YOUR_ROLE_NAME` - The IAM role name from Step 3
- `my_external_id` - A unique identifier (used in trust policy)

---

## Step 5: Get Snowflake's IAM User ARN

After creating the external volume, retrieve Snowflake's IAM user:

```sql
DESC EXTERNAL VOLUME my_iceberg_volume;
```

Look for `STORAGE_AWS_IAM_USER_ARN` in the output. It looks like:
```
arn:aws:iam::XXXXXXXXXXXX:user/abc1-s-xxxx1234
```

---

## Step 6: Update IAM Role Trust Policy

1. Go to **AWS Console > IAM > Roles** and select your role
2. Click the **Trust relationships** tab
3. Click **Edit trust policy**
4. Update with the actual values:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::XXXXXXXXXXXX:user/abc1-s-xxxx1234"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "my_external_id"
                }
            }
        }
    ]
}
```

Replace:
- The `AWS` principal with `STORAGE_AWS_IAM_USER_ARN` from Step 5
- The `sts:ExternalId` with the value you used in `STORAGE_AWS_EXTERNAL_ID`

5. Click **Update policy**

---

## Step 7: Verify the Setup

Test by creating an Iceberg table:

```sql
CREATE OR REPLACE ICEBERG TABLE my_database.my_schema.test_table (
    id INT,
    name STRING
)
CATALOG = 'SNOWFLAKE'
EXTERNAL_VOLUME = 'my_iceberg_volume'
BASE_LOCATION = 'test/';

-- Insert and query
INSERT INTO my_database.my_schema.test_table VALUES (1, 'test');
SELECT * FROM my_database.my_schema.test_table;

-- Cleanup
DROP TABLE my_database.my_schema.test_table;
```

---

## Troubleshooting

### Error: "Access Denied" on PutObject or GetObject

**Cause:** IAM policy Resource ARN is incorrect.

**Fix:** Ensure the first statement has `/*` at the end:
```json
"Resource": "arn:aws:s3:::my-bucket/*"
```

### Error: "Access Denied" on ListBucket

**Cause:** Either the bucket-level ARN is wrong, or there's a restrictive Condition.

**Fix:** Ensure the second statement has NO trailing slash and NO restrictive conditions:
```json
{
    "Effect": "Allow",
    "Action": ["s3:ListBucket", "s3:GetBucketLocation"],
    "Resource": "arn:aws:s3:::my-bucket"
}
```

### Error: "External volume not found"

**Cause:** Volume doesn't exist or you lack permissions.

**Fix:** 
```sql
SHOW EXTERNAL VOLUMES;  -- List available volumes
GRANT USAGE ON EXTERNAL VOLUME my_volume TO ROLE my_role;  -- Grant access
```

### Error: "Insufficient privileges to operate on external volume"

**Cause:** Your role lacks CREATE EXTERNAL VOLUME privilege.

**Fix:** Use ACCOUNTADMIN or grant the privilege:
```sql
USE ROLE ACCOUNTADMIN;
-- or
GRANT CREATE EXTERNAL VOLUME ON ACCOUNT TO ROLE my_role;
```

---

## Quick Reference

| Snowflake Setting | AWS Equivalent |
|-------------------|----------------|
| `STORAGE_BASE_URL` | `s3://bucket-name/` |
| `STORAGE_AWS_ROLE_ARN` | IAM Role ARN |
| `STORAGE_AWS_EXTERNAL_ID` | Trust policy `sts:ExternalId` |
| `STORAGE_AWS_IAM_USER_ARN` (output) | Trust policy `Principal.AWS` |

---

## See Also

- [Snowflake: Configure an external volume for Iceberg tables](https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-external-volume)
- [AWS: Creating IAM roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create.html)
