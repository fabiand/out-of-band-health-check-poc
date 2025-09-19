## Idea

have an out of band mechanism to determine node health.
- Use this to add a new taint to the node.
- Use this to tell NHC to remediate a node.

## Usage

1. Configure NHC and remediator

2. Fake oob readiness

```console
$ bash oob-set-node-condition.sh <node> true
…

$ bash oob-set-node-condition.sh <node> false
…
```

# Questions

- Is node `Ready: false` required to reschedule pods?
