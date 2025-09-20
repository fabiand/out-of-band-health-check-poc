
set -x

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

# FIXME we could try to crash the node, but what is the point?
$HEALTHY || timeout 2m oc debug -t node/$NODE -- chroot /host bash -xc "echo crashing node $NODE ; systemctl stop kubelet & echo c > /proc/sysrq-trigger"

# check https://kubernetes.io/docs/tasks/manage-kubernetes-objects/update-api-object-kubectl-patch/#scale-kubectl-patch
oc patch node $NODE --patch-file /dev/stdin --subresource status <<EOJ
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
# FIXME I'm quite sure we do not need this tait, because it's applied by far/snr if needed, not MDR
# we need it if we test with MDR
$HEALTHY || oc adm taint node $NODE node.kubernetes.io/out-of-service:NoExecute

#oc get node $NODE -o json | jq ".status.conditions"
