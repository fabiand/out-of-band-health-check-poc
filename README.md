## Idea

have an out of band mechanism to determine node health.
- Use this to add a new taint to the node.
- Use this to tell NHC to remediate a node.

Issue: https://issues.redhat.com/browse/CNV-48895 ?

## Usage

1. Configure NHC and remediator

2. Fake oob readiness

```console
$ bash oob-set-node-condition.sh <node> true
…

$ bash oob-set-node-condition.sh <node> false
…
```

## Test

A bsaic test that illustrates how it should work
```console
$ bash test.sh
…
virtualmachine.kubevirt.io/fenced condition met
virtualmachine.kubevirt.io "fenced" deleted
Time from failure to remediation: 4s
Time from remediation to running: 10s
TOTAL: Time from failure to running: 14s
$
```

# Questions

- Is node `Ready: false` required to reschedule pods?
- Is the test correct?
