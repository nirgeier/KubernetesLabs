#!/bin/bash

# Fix Kibana Data View and Dashboards
# This script refreshes the data view fields and validates dashboards

echo "=== Fixing Kibana Data View ==="
echo ""

# Step 1: Check Elasticsearch has data
echo "1. Checking Elasticsearch indices..."
DOC_COUNT=$(kubectl exec -n efk elasticsearch-0 -- curl -s 'http://localhost:9200/filebeat-*/_count' | jq -r '.count')
echo "   Documents in filebeat-*: $DOC_COUNT"

if [ "$DOC_COUNT" -eq 0 ]; then
  echo "   ⚠️  No data in Elasticsearch. Logs should be flowing soon."
else
  echo "   ✓ Data found!"
fi

echo ""

# Step 2: Refresh data view fields
echo "2. Refreshing data view fields..."
FIELD_COUNT=$(curl -s "http://kibana.local/api/data_views/data_view/filebeat-index-pattern" -H "kbn-xsrf: true" | jq -r '.data_view.fields | length')
echo "   Current field count: $FIELD_COUNT"

if [ "$FIELD_COUNT" -lt 100 ]; then
  echo "   ⚠️  Low field count, triggering refresh..."
  curl -X POST "http://kibana.local/api/data_views/data_view/filebeat-index-pattern/fields" -H "kbn-xsrf: true" >/dev/null 2>&1
  sleep 2
  FIELD_COUNT=$(curl -s "http://kibana.local/api/data_views/data_view/filebeat-index-pattern" -H "kbn-xsrf: true" | jq -r '.data_view.fields | length')
  echo "   New field count: $FIELD_COUNT"
fi

echo ""

# Step 3: Check for json.* fields
echo "3. Verifying json.* fields..."
JSON_FIELDS=$(curl -s "http://kibana.local/api/data_views/data_view/filebeat-index-pattern" -H "kbn-xsrf: true" | jq -r '.data_view.fields[] | select(.name | startswith("json.level") or startswith("json.component") or startswith("json.message")) | .name' | wc -l)
echo "   Found $JSON_FIELDS critical json fields"

if [ "$JSON_FIELDS" -ge 3 ]; then
  echo "   ✓ Fields available!"
else
  echo "   ⚠️  Missing fields, check log processor"
fi

echo ""

# Step 4: List dashboards
echo "4. Available dashboards..."
curl -s "http://kibana.local/api/saved_objects/_find?type=dashboard" -H "kbn-xsrf: true" | jq -r '.saved_objects[] | "   - \(.attributes.title)"'

echo ""
echo "=== Fix Complete ==="
echo ""
echo "Next steps:"
echo "  1. Refresh your browser (Cmd+Shift+R or Ctrl+Shift+R)"
echo "  2. Navigate to Dashboard → Select Error Analysis or General Logs"
echo "  3. If still showing errors, wait 2 minutes for next log processing cycle"
echo ""
echo "Kibana URL: http://kibana.local"
echo ""
