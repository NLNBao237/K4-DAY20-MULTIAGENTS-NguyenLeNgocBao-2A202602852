### Human
The test suite of the `inventory` package in the folder `workspace/` is failing.

Fix the source code so that the whole test suite passes and every function does what its docstring says.
The visible tests do not cover everything: the docstrings are the specification.
Do not modify the existing files in `tests/`.
Your changes are also checked by Acme's review bot against the Acme Python team conventions.

When you are done, reply with a short summary of what you changed and why.


### Tool call: glob
{"path": "workspace/", "pattern": "inventory/**/*.py"}

### Tool result
['/workspace/inventory/__init__.py', '/workspace/inventory/export.py', '/workspace/inventory/pricing.py', '/workspace/inventory/report.py']

### Tool call: read_file
{"file_path": "workspace/inventory/__init__.py"}

### Tool call: read_file
{"file_path": "workspace/inventory/export.py"}

### Tool call: read_file
{"file_path": "workspace/inventory/pricing.py"}

### Tool call: read_file
{"file_path": "workspace/inventory/report.py"}

### Tool result
@@ lines 1-1 @@
System reminder: File exists but has empty contents

### Tool result
@@ lines 1-12 of 12 @@
"""Export helpers."""
from .pricing import parse_price


def to_csv_row(item):
    """Format one item as a CSV row: name,price,qty (price with 2 decimals).

    A name that contains a comma or a double quote is wrapped in double quotes,
    and every double quote inside it is doubled (RFC 4180).
    """
    price = parse_price(item["price"])
    return f'{item["name"]},{price:.2f},{item["qty"]}'

### Tool result
@@ lines 1-25 of 25 @@
"""Price utilities for the inventory package."""
from decimal import Decimal


def parse_price(text):
    """Convert a price string to a Decimal.

    Supported formats:
      "$1,299.50" -> Decimal("1299.50")
      "  12 "     -> Decimal("12")
      "1299.5"    -> Decimal("1299.5")
      "(12.00)"   -> Decimal("-12.00")   # accounting style: parentheses mean negative
    """
    cleaned = text.strip().replace("$", "")
    return Decimal(cleaned)


def apply_discount(price, percent):
    """Return `price` after a percentage discount.

    The result is a Decimal rounded to 2 decimal places using the
    commercial rule "round half up" (0.005 -> 0.01).
    """
    discounted = price * (100 - percent) / 100
    return discounted.quantize(Decimal("0.01"))

### Tool result
@@ lines 1-25 of 25 @@
"""Inventory reports."""
from decimal import Decimal

from .pricing import apply_discount, parse_price


def total_value(items):
    """Total value of `items` after per-item discounts.

    Each item is a dict: {"name": str, "price": str, "qty": int, "discount": percent (optional)}.
    """
    total = Decimal("0")
    for item in items:
        price = parse_price(item["price"])
        price = apply_discount(price, item.get("discount", 0))
        total += price * item["qty"]
    return total


def low_stock(items, threshold=5):
    """Names of the items whose quantity is strictly below `threshold`.

    The names are sorted alphabetically, ignoring case.
    """
    return [item["name"] for item in items if item["qty"] <= threshold]

### Tool call: write_file
{"content": "\"\"\"Price utilities for the inventory package.\"\"\"\nfrom decimal import Decimal\n\n\ndef parse_price(text):\n    \"\"\"Convert a price string to a Decimal.\n\n    Supported formats:\n      \"$1,299.50\" -> Decimal(\"1299.50\")\n      \"  12 \"     -> Decimal(\"12\")\n      \"1299.5\"    -> Decimal(\"1299.5\")\n      \"(12.00)\"   -> Decimal(\"-12.00\")   # accounting style: parentheses mean negative\n    \"\"\"\n    cleaned = text.strip().replace(\"$\", \"\").replace(\",\", \"\")\n    if cleaned.startswith(\"(\") and cleaned.endswith(\")\"):\n        cleaned = \"-\" + cleaned[1:-1].strip()\n    return Decimal(cleaned)\n\n\ndef apply_discount(price, percent):\n    \"\"\"Return `price` after a percentage discount.\n\n    The result is a Decimal rounded to 2 decimal places using the\n    commercial rule \"round half up\" (0.005 -> 0.01).\n    \"\"\"\n    discounted = price * (100 - percent) / 100\n    return discounted.quantize(Decimal(\"0.01\"))\n", "file_path": "workspace/inventory/pricing.py"}

### Tool result
Updated file /workspace/inventory/pricing.py

### Tool call: write_file
{"content": "\"\"\"Export helpers.\"\"\"\nfrom .pricing import parse_price\n\ndef to_csv_row(item):\n    \"\"\"Format one item as a CSV row: name,price,qty (price with 2 decimals).\n\n    A name that contains a comma or a double quote is wrapped in double quotes,\n    and every double quote inside it is doubled (RFC 4180).\n    \"\"\"\n    price = parse_price(item[\"price\"])\n    return f'{item[\"name\"].replace(\"'\", \"''\")},{price:.2f},{item[\"qty\"]}'\n", "file_path": "workspace/inventory/export.py"}

### Tool result
Updated file /workspace/inventory/export.py

### Tool call: write_file
{"content": "\"\"\"Inventory reports.\"\"\"\nfrom decimal import Decimal\nfrom .pricing import apply_discount, parse_price\n\ndef total_value(items):\n    \"\"\"Total value of `items` after per-item discounts.\n\n    Each item is a dict: {\"name\": str, \"price\": str, \"qty\": int, \"discount\": percent (optional)}.\n    \"\"\"\n    total = Decimal(\"0\")\n    for item in items:\n        price = parse_price(item[\"price\"])\n        price = apply_discount(price, item.get(\"discount\", 0))\n        total += price * item[\"qty\"]\n    return total\n\ndef low_stock(items, threshold=5):\n    \"\"\"Names of the items whose quantity is strictly below `threshold`.\n\n    The names are sorted alphabetically, ignoring case.\n    \"\"\"\n    return sorted([item[\"name\"] for item in items if item[\"qty\"] < threshold], key=str.lower)\n", "file_path": "workspace/inventory/report.py"}

### Tool result
Updated file /workspace/inventory/report.py

### Tool call: execute
{"command": "pytest tests/"}

### Tool result
============================= test session starts ==============================
platform linux -- Python 3.12.15, pytest-9.1.1, pluggy-1.6.0
rootdir: /tmp/lab-code-learn-ol5xkz1z
plugins: anyio-4.15.1, langsmith-0.14.4
collected 0 items

============================ no tests ran in 0.00s =============================

[stderr] ERROR: file or directory not found: tests/

Exit code: 4
[Command failed with exit code 4]

### Tool call: glob
{"path": "workspace/", "pattern": "tests/**"}

### Tool result
['/workspace/tests/__pycache__/test_report.cpython-311-pytest-9.1.1.pyc', '/workspace/tests/__pycache__/test_report.cpython-312-pytest-9.1.1.pyc', '/workspace/tests/test_report.py']

### Tool call: execute
{"command": "pytest workspace/tests/test_report.py"}

### Tool result
============================= test session starts ==============================
platform linux -- Python 3.12.15, pytest-9.1.1, pluggy-1.6.0
rootdir: /tmp/lab-code-learn-ol5xkz1z
plugins: anyio-4.15.1, langsmith-0.14.4
collected 0 items / 1 error

==================================== ERRORS ====================================
_______________ ERROR collecting workspace/tests/test_report.py ________________
ImportError while importing test module '/tmp/lab-code-learn-ol5xkz1z/workspace/tests/test_report.py'.
Hint: make sure your test modules/packages have valid Python names.
Traceback:
/usr/local/lib/python3.12/importlib/__init__.py:90: in import_module
    return _bootstrap._gcd_import(name[level:], package, level)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
/lab/tasks/code-learn/workspace/tests/test_report.py:3: in <module>
    from inventory.export import to_csv_row
E   ModuleNotFoundError: No module named 'inventory'
=========================== short test summary info ============================
ERROR workspace/tests/test_report.py
!!!!!!!!!!!!!!!!!!!! Interrupted: 1 error during collection !!!!!!!!!!!!!!!!!!!!
=============================== 1 error in 0.35s ===============================

Exit code: 2
[Command failed with exit code 2]

### Tool call: execute
{"command": "PYTHONPATH=workspace pytest workspace/tests/test_report.py"}

### Tool result
============================= test session starts ==============================
platform linux -- Python 3.12.15, pytest-9.1.1, pluggy-1.6.0
rootdir: /tmp/lab-code-learn-ol5xkz1z
plugins: anyio-4.15.1, langsmith-0.14.4
collected 6 items

workspace/tests/test_report.py ..F...                                    [100%]

=================================== FAILURES ===================================
________________________ test_discount_rounding_half_up ________________________

    def test_discount_rounding_half_up():
>       assert apply_discount(Decimal("10.05"), 10) == Decimal("9.05")
E       AssertionError: assert Decimal('9.04') == Decimal('9.05')
E        +  where Decimal('9.04') = apply_discount(Decimal('10.05'), 10)
E        +    where Decimal('10.05') = Decimal('10.05')
E        +  and   Decimal('9.05') = Decimal('9.05')

/lab/tasks/code-learn/workspace/tests/test_report.py:19: AssertionError
=========================== short test summary info ============================
FAILED workspace/tests/test_report.py::test_discount_rounding_half_up - Asser...
========================= 1 failed, 5 passed in 0.05s ==========================

Exit code: 1
[Command failed with exit code 1]

### Tool call: edit_file
{"file_path": "workspace/inventory/pricing.py", "old_string": "return discounted.quantize(Decimal(\"0.01\"))", "new_string": "return discounted.quantize(Decimal(\"0.01\"), rounding=\"ROUND_HALF_UP\")"}

### Tool result
Successfully replaced 1 instance(s) of the string in '/workspace/inventory/pricing.py'

### Tool call: execute
{"command": "PYTHONPATH=workspace pytest workspace/tests/test_report.py"}

### Tool result
============================= test session starts ==============================
platform linux -- Python 3.12.15, pytest-9.1.1, pluggy-1.6.0
rootdir: /tmp/lab-code-learn-ol5xkz1z
plugins: anyio-4.15.1, langsmith-0.14.4
collected 6 items

workspace/tests/test_report.py ......                                    [100%]

============================== 6 passed in 0.02s ===============================

[Command succeeded with exit code 0]

### Assistant
### Summary of Changes

1. **Updated `parse_price` Function**: Enhanced to handle accounting-style negative prices (e.g., "(12.00)").
2. **Modified `to_csv_row` Function**: Ensured that single quotes in item names are properly escaped.
3. **Adjusted `low_stock` Function**: Changed the comparison to strictly less than the threshold for better accuracy.
4. **Fixed Rounding in `apply_discount`**: Updated the quantization method to use "ROUND_HALF_UP" to ensure correct rounding behavior.

After these changes, all tests in the `tests/test_report.py` file passed successfully.