set -e

echo "assumes that vm can be scheduled, aws emulation omde"
echo "this test was done with NHC and MDR"
echo basic checks, but generally we assume that nhc and mdr are already configured properly and all nodes are helathy
[[ $(oc get nodes -o name -l node-role.kubernetes.io/worker | wc -l) = 3 ]]
oc apply -f manifests/nhc.yaml
oc apply -f manifests/mdrtpl.yaml

set -x
oc create -f manifests/vm.yaml
oc wait --for condition=Ready=True -f manifests/vm.yaml

NODE="ip-$(oc get pods -o jsonpath="{.items[0].status.hostIP}" | tr "." "-").ec2.internal"

# Fake that OOB is healthy
bash oob-set-node-condition.sh $NODE true

oc get -w events | grep -i -E "launcher|node|machine|health|fence" &
oc get -w vms &

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

echo "Time from failure to remediation: $(( RECOVERY_TIME - FAILURE_TIME ))s"
echo "Time from remediation to running: $(( RUNNING_TIME - RECOVERY_TIME ))s"
echo "TOTAL: Time from failure to running: $(( RUNNING_TIME - FAILURE_TIME ))s"
