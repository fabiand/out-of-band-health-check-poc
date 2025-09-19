
NODE=$1
HEALTHY=${2:?"Usage: $0 <node> <readiness>, ex. `$0 node01 false`"}

ST="True"
RE="OOBHeartbeatIsAlive"
ME="Heartbeat is working"
if [[ "$HEALTHY" != "true" ]];
then
  ST="False"
  RE="OOBHeartbeatIsDead"
  ME="Heartbeat is NOT working"
fi

set -x

# check https://kubernetes.io/docs/tasks/manage-kubernetes-objects/update-api-object-kubectl-patch/#scale-kubectl-patch
oc patch node $NODE --patch - --subresource status <<EOJ
{ 
  "status": {
    "conditions": [
      {
        "type": "OutOfBandReady",
        "status": "$ST",
        "lastHeartbeatTime": "2025-09-19T09:02:35Z",
        "lastTransitionTime": "2025-09-19T07:58:17Z",
        "reason": "$RE",
        "message": "$ME"
      }
    ]
  }
}
EOJ
oc adm taint node $NO node.kubernetes.io/out-of-service=:NoExecute
