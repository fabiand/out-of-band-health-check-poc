set -e

echo "assumes that vm can be scheduled, aws emulation omde"
echo "this test is tailored for a 3 node cluster bot cluster"
echo "this test was done with NHC and MDR"
echo basic checks, but generally we assume that nhc and mdr are already configured properly and all nodes are helathy
set -x
[[ $(oc get nodes -o name -l node-role.kubernetes.io/worker | wc -l) > 1 ]]
oc wait mcp worker --for condition=Degraded=False --for condition=Updated=True

oc create -f manifests/vm.yaml
oc wait --for condition=Ready=True -f manifests/vm.yaml

NODE="ip-$(oc get pods -o jsonpath="{.items[0].status.hostIP}" | tr "." "-").ec2.internal"

# Fake that OOB is healthy
bash oob-set-node-condition.sh $NODE true

oc get --watch-only events | grep -i -E "launcher|node|machine|health|fence|taint|drain|evict|delete" &
oc get --watch-only vms &

FAILURE_TIME=$(date +%s)
# Fake that OOB is NOT healthy
bash oob-set-node-condition.sh $NODE false

oc wait --for condition=Ready=False -f manifests/vm.yaml
RECOVERY_TIME=$(date +%s)

oc wait --for condition=Ready=True -f manifests/vm.yaml
RUNNING_TIME=$(date +%s)

killall oc
oc delete -f manifests/vm.yaml --wait=false
set +x

echo "Time from node failure to initiating node remediation: $(( RECOVERY_TIME - FAILURE_TIME ))s"
echo "Time from initiated node remediation to VM running: $(( RUNNING_TIME - RECOVERY_TIME ))s"
echo "TOTAL: Time from node failure to VM running: $(( RUNNING_TIME - FAILURE_TIME ))s"
