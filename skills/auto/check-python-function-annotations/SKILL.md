---
name: check-python-function-annotations
description: Use when ensuring that all public functions in a Python package have type annotations.
---
1. Verify that every public function (name not starting with '_') in the package has type annotations on all parameters and on the return value.
2. Review the codebase for any functions that lack these annotations and add them accordingly.
3. Run the code analysis tools to check for compliance with this rule.
4. Self-check by ensuring all public functions are annotated before finalizing changes.
