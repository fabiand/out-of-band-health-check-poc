#!/usr/bin/bash

add_condition() {
    local $NODE=$1 TYPE=$2 STATUS=$3 REASON=$4 MESSAGE=$5
  curl --header "Content-Type: application/json-patch+json" \
  --request PATCH \
  --data -
  http://localhost:8001/api/v1/nodes/$NODE/status <<EOJ
[{"op": "add", "path": "/status/conditions/-", "value": {"message": "$MESSAGE", "reason": "$REASON", "status": "$STATUS", "type": "$TYPE"}}]
EOJ
}
