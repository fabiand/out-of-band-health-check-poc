set -e

echo "assumes that vm can be scheduled, aws emulation omde"

set -x
oc create -f vm.yaml
oc wait --for condition=Ready=True vm fenced
sleep 5

NODE="ip-$(oc get pods -o jsonpath="{.items[0].status.hostIP}" | tr "." "-").ec2.internal"

# Fake that OOB is healthy
bash oob-set-node-condition.sh $NODE true

oc get -w events | grep -i -E "launcher|node|machine|health|fence" &
oc get -w vms &

FAILURE_TIME=$(date +%s)
# Fake that OOB is NOT healthy
bash oob-set-node-condition.sh $NODE false

oc wait --for condition=Ready=False vm fenced
RECOVERY_TIME=$(date +%s)

oc wait --for condition=Ready=True vm fenced
RUNNING_TIME=$(date +%s)

killall oc
oc delete -f vm.yaml --wait=false
set +x

echo "Time from failure to remediation: $(( RECOVERY_TIME - FAILURE_TIME ))s"
echo "Time from remediation to running: $(( RUNNING_TIME - RECOVERY_TIME ))s"
echo "TOTAL: Time from failure to running: $(( RUNNING_TIME - FAILURE_TIME ))s"
