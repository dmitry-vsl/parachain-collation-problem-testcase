# Test case demonstrating that collator never starts producing block

Run: `docker build -f Dockerfile-ok .`

Test launches two validator nodes and collator node. Then it registeres parachain.

Collator eventually starts producing logs like:

```
```

Expected behaviour: collator start to produce and finalize blocks.

Actual behaviour: collator never produce and finalize blocks.

