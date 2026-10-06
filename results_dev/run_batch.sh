#!/bin/sh
# Usage: sh results_dev/run_batch.sh <results dir> "<condition> <task>" ...
# One process per run with a hard time limit, so a hung API call cannot block the rest of the batch.
results="$1"; shift
for spec in "$@"; do
    set -- $spec
    timeout 1200 python -m lab.runner --condition "$1" --tasks "$2" --results "$results" 2>&1 | grep -E "^(baseline|subagents|skills-auto)" \
        || echo "$1 $2 NO-RESULT (timed out or crashed)"
done
echo BATCH-DONE
