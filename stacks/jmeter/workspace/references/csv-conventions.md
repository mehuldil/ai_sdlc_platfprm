# CSV Test Data Conventions & Standards

**Version**: 2.0.0  
**Last Updated**: 2026-04-11  
**Purpose**: Guide for generating, validating, and organizing test data CSV files  
**Audience**: perf-builder agents, data generation scripts

---

## Overview

CSV files provide realistic test data for JMeter performance tests. These conventions ensure consistency, prevent data quality issues, and support reliable performance testing.

---

## 1. Column Naming Conventions

### 1.1 Standard Column Names

**Rules**:
- All lowercase
- Underscores for spaces: `device_key` not `deviceKey` or `DeviceKey`
- Match variable names used in JMX: `${device_key}` → column `device_key`
- No special characters except underscore

**Standard Columns**:

| Column | Purpose | Format | Example |
|--------|---------|--------|---------|
| `user_id` | Unique user identifier | String: `user{5-digit}` | `user00001` |
| `email_id` | Email address (must be unique per row) | Valid email format | `user00001@test.com` |
| `password` | Login password (synthetic, not real) | String | `Test@123` |
| `auth_key` | Pre-generated auth token | Base64 or JWT | `base64token00001` |
| `device_key` | Device identifier (for multi-device scenarios) | String: `dk-{id}` | `dk-00001` |
| `shard_key` | Database shard key (for distributed systems) | String: `shard-{num}` | `shard-1` |
| `folder_key` / `root_folder_key` | Primary folder ID | String: `rf-{id}` or `folder-{id}` | `rf-00001` |
| `document_id` | Pre-existing document ID (for download tests) | String: `doc-{id}` | `doc-12345` |
| `search_query` | Search term (for search tests) | String | `python tutorial` |
| `file_name` | File name for upload tests | String | `report-q1.pdf` |
| `file_size` | File size in bytes (for upload tests) | Integer | `2048000` |
| `mime_type` | MIME type for file upload | String | `application/pdf` |

---

## 2. File Naming Conventions

### 2.1 File Name Format

**Format**: `{api}_{scenario}.csv`

**Components**:
- `api`: Which API is tested (auth, users, search, upload, messaging)
- `scenario`: Specific scenario (credentials, complex, queries, files)

**Examples**:
```
auth_credentials.csv        (users for login test)
users_profile.csv           (users for profile lookup)
users_complex.csv           (users with all attributes)
search_queries.csv          (search terms)
search_complex-queries.csv  (complex query operators)
upload_files.csv            (file metadata for upload)
messaging_recipients.csv    (recipient user IDs)
```

### 2.2 File Location

**Path**: `perf-tests/story-{STORY_ID}/data/{filename}.csv`

**Example**:
```
perf-tests/story-12345/data/
├── auth_credentials.csv
├── users_complex.csv
├── search_queries.csv
├── upload_files.csv
└── README.md (data dictionary)
```

---

## 3. Row Count Conventions

### 3.1 Determining Row Count

**Formula**: `(max_thread_count × 1.2) + buffer_for_iterations`

**Examples**:

| Thread Count | Duration | Iterations | Row Count |
|--------------|----------|-----------|-----------|
| 10 threads | 5 min | ~3 iterations per user | 10 × 1.2 = 12 rows (use 15) |
| 100 threads | 30 min | ~30 iterations per user | 100 × 1.2 = 120 rows (use 150) |
| 500 threads | 30 min | ~30 iterations per user | 500 × 1.2 = 600 rows (use 750) |
| 1000 threads | 60 min | ~60 iterations per user | 1000 × 1.2 = 1200 rows (use 1500) |

**Rationale**:
- 1.2x multiplier: 20% buffer for failed requests
- All threads need unique data to avoid contention
- If threads exhaust CSV, `recycle=true` in JMeter restarts from top

### 3.2 Row Distribution

**For sharded systems**: Distribute rows evenly across shards

**Example** (10 shards):
```
100 total rows
→ 10 rows per shard
→ Rows 1-10: shard-1
→ Rows 11-20: shard-2
→ ...
→ Rows 91-100: shard-10
```

---

## 4. Data Generation Patterns

### 4.1 User Data Generation Script

```bash
#!/usr/bin/env bash
# Generate users.csv with 1000 rows

cat > users.csv << 'EOF'
user_id,device_key,email_id,password,auth_key,shard_key,folder_key
EOF

for i in {1..1000}; do
  user_id=$(printf "user%05d" $i)
  device_key="dk-$(printf "%05d" $i)"
  email="user$(printf "%05d" $i)@test.com"
  password="Test@123"
  auth_key="base64token$(printf "%05d" $i)"
  shard=$((($i - 1) % 10 + 1))  # Distribute across 10 shards
  folder_key="rf-$(printf "%05d" $i)"
  
  echo "$user_id,$device_key,$email,$password,$auth_key,shard-$shard,$folder_key" >> users.csv
done

echo "Generated $(wc -l < users.csv) rows"
```

**Result**:
```
user_id,device_key,email_id,password,auth_key,shard_key,folder_key
user00001,dk-00001,user00001@test.com,Test@123,base64token00001,shard-1,rf-00001
user00002,dk-00002,user00002@test.com,Test@123,base64token00002,shard-2,rf-00002
user00003,dk-00003,user00003@test.com,Test@123,base64token00003,shard-3,rf-00003
...
user01000,dk-01000,user01000@test.com,Test@123,base64token01000,shard-10,rf-01000
```

### 4.2 Search Queries Generation Script

```bash
#!/usr/bin/env bash
# Generate search_queries.csv with 500 unique queries

cat > search_queries.csv << 'EOF'
search_query,page,limit
EOF

# Simple queries (70%)
simple_terms=("python" "javascript" "java" "golang" "rust" "kotlin" "swift")
for term in "${simple_terms[@]}"; do
  for topic in "tutorial" "guide" "advanced" "best practices" "performance"; do
    echo "\"$term $topic\",1,20" >> search_queries.csv
  done
done

# Complex queries with operators (30%)
complex_queries=(
  "\"machine learning\" AND python"
  "java OR kotlin OR groovy"
  "database optimization -mysql"
  "REST API design"
  "kubernetes containers deployment"
)
for query in "${complex_queries[@]}"; do
  for page in 1 2 3; do
    echo "\"$query\",${page},50" >> search_queries.csv
  done
done

echo "Generated $(wc -l < search_queries.csv) rows"
```

### 4.3 File Upload Data Generation Script

```bash
#!/usr/bin/env bash
# Generate upload_files.csv with varied file sizes

cat > upload_files.csv << 'EOF'
file_name,file_size,mime_type,folder_key
EOF

# Small files (< 1MB)
for i in {1..100}; do
  echo "document-$i.pdf,524288,application/pdf,rf-$(printf "%05d" $((i % 1000)))" >> upload_files.csv
done

# Medium files (1-10MB)
for i in {101..200}; do
  echo "presentation-$i.pptx,5242880,application/vnd.presentationml,rf-$(printf "%05d" $((i % 1000)))" >> upload_files.csv
done

# Large files (10-100MB)
for i in {201..250}; do
  echo "archive-$i.zip,52428800,application/zip,rf-$(printf "%05d" $((i % 1000)))" >> upload_files.csv
done

echo "Generated $(wc -l < upload_files.csv) rows"
```

---

## 5. CSV Validation Rules

### 5.1 Mandatory Validation

Before using CSV in tests:

**Check 1: Header Consistency**
```bash
# Verify header matches JMX variable names
head -1 users.csv
# Output: user_id,device_key,email_id,password,auth_key,shard_key,folder_key
```

**Check 2: Row Completeness**
```bash
# Count columns in header
HEADER_COLS=$(head -1 users.csv | tr ',' '\n' | wc -l)

# Verify each row has same number of columns
awk -F',' 'NF != '$HEADER_COLS' {print "Row " NR " has " NF " columns, expected " '$HEADER_COLS'"}' users.csv
```

**Check 3: No Duplicates** (for unique columns)
```bash
# Check for duplicate user_ids
cut -d',' -f1 users.csv | tail -n +2 | sort | uniq -d

# If no output → no duplicates ✓
```

**Check 4: Data Type Validation**
```python
import csv
with open('users.csv') as f:
    reader = csv.DictReader(f)
    for row in reader:
        # Validate email format
        if '@' not in row['email_id']:
            print(f"Invalid email: {row['email_id']}")
        
        # Validate user_id format
        if not row['user_id'].startswith('user'):
            print(f"Invalid user_id: {row['user_id']}")
```

**Check 5: No Missing Values**
```bash
# Count empty cells (consecutive commas)
grep ",," users.csv | head -5

# Count rows with fewer than expected fields
awk -F',' 'NF < 7 {print "Row " NR " incomplete"}' users.csv
```

### 5.2 Optional Validation

**PII Check** (ensure no real personally identifiable information):
```bash
# Should only have @test.com emails
grep -v "@test.com" users.csv | head -5
# Should have no real SSNs, phone numbers, etc.
```

**Data Range Check** (for numeric fields):
```bash
# Verify file sizes are in expected range (1KB - 100MB)
awk -F',' '$2 < 1024 {print "File too small: " $0}' upload_files.csv
awk -F',' '$2 > 104857600 {print "File too large: " $0}' upload_files.csv
```

---

## 6. CSV Organization in Git

### 6.1 Directory Structure

```
perf-tests/story-12345/
├── jmx/
│   ├── baseline-test.jmx
│   ├── load-test.jmx
│   └── stress-test.jmx
│
├── data/
│   ├── README.md                    ← Data dictionary
│   ├── auth_credentials.csv
│   ├── users_complex.csv
│   ├── search_queries.csv
│   ├── upload_files.csv
│   └── generate-data.sh             ← Data generation script
│
├── properties/
│   ├── hosts.properties
│   └── sla.properties
│
└── README.md                        ← How to run tests
```

### 6.2 Data Dictionary (README.md)

```markdown
# Test Data Dictionary

## auth_credentials.csv
- **Purpose**: User credentials for LOGIN test
- **Row Count**: 1000 users
- **Columns**:
  - user_id: Unique identifier (format: user00001)
  - email_id: Email address (@test.com domain only)
  - password: Synthetic password (Test@123)
- **Distribution**: Evenly across 10 shards
- **Generated**: 2026-04-11 by generate-data.sh

## search_queries.csv
- **Purpose**: Search terms for SEARCH test
- **Row Count**: 500 queries
- **Columns**:
  - search_query: Search term (simple or complex operators)
  - page: Page number (1, 2, or 3)
  - limit: Results per page (20 or 50)
- **Distribution**: 70% simple queries, 30% complex
- **Generated**: 2026-04-11 by generate-data.sh
```

---

## 7. CSV Special Cases

### 7.1 Headers with Spaces or Special Characters

**Avoid**: CSV columns should be compatible with JMeter variable names

**Bad** (will cause issues):
```
First Name,Last Name,Email Address
```

**Good**:
```
first_name,last_name,email_address
```

### 7.2 Quoted Fields (with commas or newlines)

**Use quotes for fields containing commas**:

```csv
file_name,description
"report-q1.pdf","Quarterly report, FY2025"
"archive.zip","Contains: docs, images, code"
```

**In JMeter CSV Config**, enable: `quotedData=true`

```xml
<boolProp name="quotedData">true</boolProp>
```

### 7.3 Handling Special Characters

**Encoding**: Always UTF-8

**Escaping**: Use standard CSV escaping (double quotes)

**Bad** (will break parsing):
```
user_id,description
user001,Test & validation
user002,Price: $99.99
```

**Good**:
```
user_id,description
user001,"Test & validation"
user002,"Price: $99.99"
```

---

## 8. Data Recycle & Sharing Strategies

### 8.1 Recycle Strategy (Default)

**Use when**: CSV rows < total requests expected

**Configuration**:
```xml
<CSVDataSet ...>
  <boolProp name="recycle">true</boolProp>   <!-- restart from top -->
  <boolProp name="stopThread">false</boolProp> <!-- keep going -->
</CSVDataSet>
```

**Example**:
- 100 rows in CSV
- 500 threads
- Each thread cycles through CSV multiple times
- Useful for long-running tests (soak tests)

### 8.2 Sharing Strategy

**All threads share same CSV** (most common):
```xml
<stringProp name="shareMode">shareMode.all</stringProp>
```

**Each thread gets copy of CSV**:
```xml
<stringProp name="shareMode">shareMode.group</stringProp>
```

**Each thread independent** (no sharing):
```xml
<stringProp name="shareMode">shareMode.thread</stringProp>
```

---

## 9. Example CSV Files

### 9.1 Example: auth_credentials.csv

```csv
user_id,device_key,email_id,password,auth_key,shard_key,folder_key
user00001,dk-00001,user00001@test.com,Test@123,base64token00001,shard-1,rf-00001
user00002,dk-00002,user00002@test.com,Test@123,base64token00002,shard-2,rf-00002
user00003,dk-00003,user00003@test.com,Test@123,base64token00003,shard-3,rf-00003
user00004,dk-00004,user00004@test.com,Test@123,base64token00004,shard-4,rf-00004
user00005,dk-00005,user00005@test.com,Test@123,base64token00005,shard-5,rf-00005
```

### 9.2 Example: search_queries.csv

```csv
search_query,page,limit
python tutorial,1,20
machine learning,1,20
java spring framework,1,20
"database optimization AND mysql",1,50
"REST API" OR "GraphQL",2,50
kubernetes containers,3,50
```

### 9.3 Example: upload_files.csv

```csv
file_name,file_size,mime_type,folder_key
report-q1.pdf,2048000,application/pdf,rf-00001
presentation-annual.pptx,5242880,application/vnd.presentationml,rf-00002
spreadsheet-budget.xlsx,512000,application/vnd.ms-excel,rf-00003
archive-backup.zip,52428800,application/zip,rf-00004
```

---

## 10. CSV Best Practices

### 10.1 DO

- ✓ Use lowercase_with_underscores for column names
- ✓ Include comment row in script explaining data source
- ✓ Generate data deterministically (same seed = same data)
- ✓ Use @test.com domain for all email addresses
- ✓ Include buffer rows (1.2x thread count minimum)
- ✓ Distribute data across shards if applicable
- ✓ Validate row count before committing
- ✓ Keep CSV files in version control

### 10.2 DON'T

- ✗ Use real PII (real names, emails, SSNs)
- ✗ Use special characters in column names
- ✗ Hardcode values that should come from CSV
- ✗ Mix different data types in same column
- ✗ Create CSV files that are too large (>100MB) — use data generator instead
- ✗ Store API tokens or secrets in CSV
- ✗ Manually edit CSV — use script for consistency

---

## 11. Performance Considerations

### 11.1 CSV File Size Impact

- **10 columns × 1000 rows** ≈ 50 KB (negligible)
- **10 columns × 10,000 rows** ≈ 500 KB (acceptable)
- **10 columns × 100,000 rows** ≈ 5 MB (may slow JMeter startup)

**Recommendation**: Keep CSV < 10 MB for startup performance

### 11.2 Recycle vs. Unique Data

**If possible, have enough rows** that each thread gets unique data:
- Avoids data contention
- More realistic load profile
- Better test results

**If CSV is small** (recycle=true):
- Monitor for cache effects (if backend caches by user_id)
- Consider data warming before test load ramps up

---

## Validation Checklist

Before committing CSV files:

- [ ] Header row matches JMX variable names
- [ ] All rows have same number of columns as header
- [ ] No duplicate user_ids or other unique keys
- [ ] Email addresses are @test.com domain only
- [ ] Row count ≥ max_thread_count × 1.2
- [ ] Data is evenly distributed (across shards, if applicable)
- [ ] Data file is UTF-8 encoded
- [ ] Special characters are properly escaped
- [ ] File size < 10 MB (recommend < 5 MB)
- [ ] Data is generated from script (repeatable)
- [ ] README.md documents each CSV file
- [ ] No real PII in any column

---

**Last Updated**: 2026-04-11  
**Owner**: Performance Team  
**Next Review**: 2026-05-11
