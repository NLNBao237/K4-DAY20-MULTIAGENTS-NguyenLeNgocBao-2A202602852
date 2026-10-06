### Human
The test suite of the `inventory` package in the folder `workspace/` is failing.

Fix the source code so that the whole test suite passes and every function does what its docstring says.
The visible tests do not cover everything: the docstrings are the specification.
Do not modify the existing files in `tests/`.
Your changes are also checked by Acme's review bot against the Acme Python team conventions.

When you are done, reply with a short summary of what you changed and why.


### Tool call: task
{"subagent_type": "explorer", "description": "Explore the workspace repository and test suite. Find all files in workspace/, examine README, source code, and tests, run pytest to see what tests are failing, and report the findings."}

### Tool result
Based on the exploration of the workspace repository and test suite, here are the findings:

### 1. Repository Files
- `/workspace/README.md`
- `/workspace/CHANGELOG.md`
- `/workspace/inventory/__init__.py`
- `/workspace/inventory/export.py`
- `/workspace/inventory/pricing.py`
- `/workspace/inventory/report.py`
- `/workspace/tests/test_report.py`

---

### 2. Written Rules and Conventions Found in Code & Comments

- **CSV Row Formatting (`inventory/export.py`, lines 7-8):**
  > `"""Format one item as a CSV row: name,price,qty (price with 2 decimals).`

- **CSV RFC 4180 Escaping (`inventory/export.py`, lines 10-11):**
  > `A name that contains a comma or a double quote is wrapped in double quotes,`
  > `and every double quote inside it is doubled (RFC 4180).`

- **Price Parsing Formats (`inventory/pricing.py`, lines 7-12):**
  > `"""Convert a price string to a Decimal.`
  > `Supported formats:`
  > `  "$1,299.50" -> Decimal("1299.50")`
  > `  "  12 "     -> Decimal("12")`
  > `  "1299.5"    -> Decimal("1299.5")`
  > `  "(12.00)"   -> Decimal("-12.00")   # accounting style: parentheses mean negative`

- **Discount Rounding Rule (`inventory/pricing.py`, lines 18-20):**
  > `"""Return `price` after a percentage discount.`
  > `The result is a Decimal rounded to 2 decimal places using the`
  > `commercial rule "round half up" (0.005 -> 0.01).`

- **Total Value Item Structure (`inventory/report.py`, lines 8-9):**
  > `Each item is a dict: {"name": str, "price": str, "qty": int, "di

### Tool call: task
{"description": "Examine the exact source code files in workspace/inventory/ (`__init__.py`, `export.py`, `pricing.py`, `report.py`) and tests/ (`test_report.py`), and run pytest via execute to see the full test failure details.", "subagent_type": "explorer"}

### Tool result
## Rules and Conventions Found in the Source Code and Tests

### `inventory/__init__.py`
- Empty file (zero lines).

### `inventory/export.py`
- Docstring: `"""Export helpers."""` (Line 1)
- Docstring convention for `to_csv_row(item)`:
  - `"""Format one item as a CSV row: name,price,qty (price with 2 decimals).` (Lines 6-7)
  - `A name that contains a comma or a double quote is wrapped in double quotes, and every double quote inside it is doubled (RFC 4180)."""` (Lines 9-10)

### `inventory/pricing.py`
- Docstring: `"""Price utilities for the inventory package."""` (Line 1)
- Docstring convention for `parse_price(text)`:
  - `"""Convert a price string to a Decimal.` (Lines 5-6)
  - Supported formats listed in docstring (Lines 8-12):
    - `"$1,299.50" -> Decimal("1299.50")`
    - `"  12 "     -> Decimal("12")`
    - `"1299.5"    -> Decimal("1299.5")`
    - `"(12.00)"   -> Decimal("-12.00")   # accounting style: parentheses mean negative`
- Docstring convention for `apply_discount(price, percent)`:
  - `"""Return `price` after a percentage discount.` (Lines 18-19)
  - `The result is a Decimal rounded to 2 decimal places using the commercial rule "round half up" (0.005 -> 0.01)."""` (Lines 21-23)

### `inventory/report.py`
- Docstring: `"""Inventory reports."""` (Line 1)
- Docstring convention for `total_value(items)`:
  - `"""Total value of `items` after per-item discounts.` (Lines 6-7)
  - `Each item is a dict: {"name": str, "price": str, "qty": int, "discount": percent (opt

### Tool call: read_file
{"offset": 0, "file_path": "workspace/inventory/pricing.py", "limit": 100}

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

### Tool call: read_file
{"limit": 100, "file_path": "workspace/inventory/export.py", "offset": 0}

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

### Tool call: read_file
{"limit": 100, "offset": 0, "file_path": "workspace/inventory/report.py"}

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

### Tool call: read_file
{"offset": 0, "file_path": "workspace/tests/test_report.py", "limit": 100}

### Tool result
@@ lines 1-32 of 32 @@
from decimal import Decimal

from inventory.export import to_csv_row
from inventory.pricing import apply_discount
from inventory.report import low_stock, total_value


def test_total_value_plain():
    items = [{"name": "pen", "price": "$2.50", "qty": 4}]
    assert total_value(items) == Decimal("10.00")


def test_total_value_thousands_separator():
    items = [{"name": "laptop", "price": "$1,299.50", "qty": 2}]
    assert total_value(items) == Decimal("2599.00")


def test_discount_rounding_half_up():
    assert apply_discount(Decimal("10.05"), 10) == Decimal("9.05")


def test_total_value_with_discount():
    items = [{"name": "desk", "price": "100.00", "qty": 1, "discount": 15}]
    assert total_value(items) == Decimal("85.00")


def test_low_stock_basic():
    assert low_stock([{"name": "pen", "qty": 2}, {"name": "ink", "qty": 9}]) == ["pen"]


def test_csv_row_plain_name():
    assert to_csv_row({"name": "pen", "price": "2.5", "qty": 4}) == "pen,2.50,4"

### Tool call: task
{"subagent_type": "explorer", "description": "Examine all test files and source files thoroughly, check edge cases mentioned in docstrings (such as CSV export escaping, accounting negative prices in parentheses, low stock sorting, etc.), and implement fixes."}

### Tool result
Read all test files and source files thoroughly. Facts found:

1. **`README.md`**:
   - Small package. Run tests from `workspace/` folder: `cd workspace && python -m pytest tests -q` (`README.md`, lines 1-5).

2. **`CHANGELOG.md`**:
   - Changelog unreleased and 0.3.1 ("initial import") (`CHANGELOG.md`, lines 1-6).

3. **`inventory/export.py`**:
   - `to_csv_row(item)` docstring:
     > Format one item as a CSV row: name,price,qty (price with 2 decimals).
     > A name that contains a comma or a double quote is wrapped in double quotes,
     > and every double quote inside it is doubled (RFC 4180).
     (`inventory/export.py`, lines 5-11).
   - Implementation:
     ```python
     price = parse_price(item["price"])
     return f'{item["name"]},{price:.2f},{item["qty"]}'
     ```
     (`inventory/export.py`, lines 11-12).

4. **`inventory/pricing.py`**:
   - `parse_price(text)` docstring:
     > Convert a price string to a Decimal.
     > Supported formats:
     >   "$1,299.50" -> Decimal("1299.50")
     >   "  12 "     -> Decimal("12")
     >   "1299.5"    -> Decimal("1299.5")
     >   "(12.00)"   -> Decimal("-12.00")   # accounting style: parentheses mean negative
     (`inventory/pricing.py`, lines 5-13).
   - Implementation:
     ```python
     cleaned = text.strip().replace("$", "")
     return Decimal(cleaned)
     ```
     (`inventory/pricing.py`, lines 14-15). (Fails on thousands separator `,` because `,` is not removed/handled, and fails on `(12.00)` because parenthese

### Tool call: execute
{"command": "python -m pytest workspace/tests -v"}

### Tool result
============================= test session starts ==============================
platform linux -- Python 3.12.15, pytest-9.1.1, pluggy-1.6.0 -- /usr/local/bin/python
cachedir: .pytest_cache
rootdir: /tmp/lab-code-learn-ovl2ji9i
plugins: anyio-4.15.1, langsmith-0.14.4
collecting ... collected 0 items / 1 error

==================================== ERRORS ====================================
_______________ ERROR collecting workspace/tests/test_report.py ________________
ImportError while importing test module '/tmp/lab-code-learn-ovl2ji9i/workspace/tests/test_report.py'.
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
=============================== 1 error in 0.29s ===============================

Exit code: 2
[Command failed with exit code 2]

### Tool call: execute
{"command": "cd workspace && python -m pytest tests -v"}

### Tool result
============================= test session starts ==============================
platform linux -- Python 3.12.15, pytest-9.1.1, pluggy-1.6.0 -- /usr/local/bin/python
cachedir: .pytest_cache
rootdir: /tmp/lab-code-learn-ovl2ji9i/workspace
plugins: anyio-4.15.1, langsmith-0.14.4
collecting ... collected 6 items

tests/test_report.py::test_total_value_plain PASSED                      [ 16%]
tests/test_report.py::test_total_value_thousands_separator FAILED        [ 33%]
tests/test_report.py::test_discount_rounding_half_up FAILED              [ 50%]
tests/test_report.py::test_total_value_with_discount PASSED              [ 66%]
tests/test_report.py::test_low_stock_basic PASSED                        [ 83%]
tests/test_report.py::test_csv_row_plain_name PASSED                     [100%]

=================================== FAILURES ===================================
_____________________ test_total_value_thousands_separator _____________________

    def test_total_value_thousands_separator():
        items = [{"name": "laptop", "price": "$1,299.50", "qty": 2}]
>       assert total_value(items) == Decimal("2599.00")
               ^^^^^^^^^^^^^^^^^^

/lab/tasks/code-learn/workspace/tests/test_report.py:15: 
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 
inventory/report.py:14: in total_value
    price = parse_price(item["price"])
            ^^^^^^^^^^^^^^^^^^^^^^^^^^
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

### Tool call: read_file
{"file_path": "workspace/inventory/pricing.py", "limit": 100, "offset": 0}

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

### Tool call: read_file
{"limit": 100, "file_path": "workspace/inventory/report.py", "offset": 0}

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

### Tool call: read_file
{"file_path": "workspace/inventory/export.py", "offset": 0, "limit": 100}

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

### Tool call: edit_file
{"new_string": "def parse_price(text):\n    \"\"\"Convert a price string to a Decimal.\n\n    Supported formats:\n      \"$1,299.50\" -> Decimal(\"1299.50\")\n      \"  12 \"     -> Decimal(\"12\")\n      \"1299.5\"    -> Decimal(\"1299.5\")\n      \"(12.00)\"   -> Decimal(\"-12.00\")   # accounting style: parentheses mean negative\n    \"\"\"\n    cleaned = text.strip()\n    negative = False\n    if cleaned.startswith(\"(\") and cleaned.endswith(\")\"):\n        negative = True\n        cleaned = cleaned[1:-1].strip()\n    cleaned = cleaned.replace(\"$\", \"\").replace(\",\", \"\")\n    val = Decimal(cleaned)\n    return -val if negative else val", "old_string": "def parse_price(text):\n    \"\"\"Convert a price string to a Decimal.\n\n    Supported formats:\n      \"$1,299.50\" -> Decimal(\"1299.50\")\n      \"  12 \"     -> Decimal(\"12\")\n      \"1299.5\"    -> Decimal(\"1299.5\")\n      \"(12.00)\"   -> Decimal(\"-12.00\")   # accounting style: parentheses mean negative\n    \"\"\"\n    cleaned = text.strip().replace(\"$\", \"\")\n    return Decimal(cleaned)", "file_path": "workspace/inventory/pricing.py"}

### Tool result
Successfully replaced 1 instance(s) of the string in '/workspace/inventory/pricing.py'

### Tool call: edit_file
{"new_string": "def apply_discount(price, percent):\n    \"\"\"Return `price` after a percentage discount.\n\n    The result is a Decimal rounded to 2 decimal places using the\n    commercial rule \"round half up\" (0.005 -> 0.01).\n    \"\"\"\n    from decimal import ROUND_HALF_UP\n    discounted = price * (100 - percent) / 100\n    return discounted.quantize(Decimal(\"0.01\"), rounding=ROUND_HALF_UP)", "old_string": "def apply_discount(price, percent):\n    \"\"\"Return `price` after a percentage discount.\n\n    The result is a Decimal rounded to 2 decimal places using the\n    commercial rule \"round half up\" (0.005 -> 0.01).\n    \"\"\"\n    discounted = price * (100 - percent) / 100\n    return discounted.quantize(Decimal(\"0.01\"))", "file_path": "workspace/inventory/pricing.py"}

### Tool result
Successfully replaced 1 instance(s) of the string in '/workspace/inventory/pricing.py'

### Tool call: edit_file
{"file_path": "workspace/inventory/report.py", "new_string": "def low_stock(items, threshold=5):\n    \"\"\"Names of the items whose quantity is strictly below `threshold`.\n\n    The names are sorted alphabetically, ignoring case.\n    \"\"\"\n    names = [item[\"name\"] for item in items if item[\"qty\"] < threshold]\n    return sorted(names, key=lambda s: s.lower())", "old_string": "def low_stock(items, threshold=5):\n    \"\"\"Names of the items whose quantity is strictly below `threshold`.\n\n    The names are sorted alphabetically, ignoring case.\n    \"\"\"\n    return [item[\"name\"] for item in items if item[\"qty\"] <= threshold]"}

### Tool result
Successfully replaced 1 instance(s) of the string in '/workspace/inventory/report.py'

### Tool call: edit_file
{"new_string": "def to_csv_row(item):\n    \"\"\"Format one item as a CSV row: name,price,qty (price with 2 decimals).\n\n    A name that contains a comma or a double quote is wrapped in double quotes,\n    and every double quote inside it is doubled (RFC 4180).\n    \"\"\"\n    price = parse_price(item[\"price\"])\n    name = str(item[\"name\"])\n    if \",\" in name or '\"' in name:\n        name = '\"' + name.replace('\"', '\"\"') + '\"'\n    return f'{name},{price:.2f},{item[\"qty\"]}'", "old_string": "def to_csv_row(item):\n    \"\"\"Format one item as a CSV row: name,price,qty (price with 2 decimals).\n\n    A name that contains a comma or a double quote is wrapped in double quotes,\n    and every double quote inside it is doubled (RFC 4180).\n    \"\"\"\n    price = parse_price(item[\"price\"])\n    return f'{item[\"name\"]},{price:.2f},{item[\"qty\"]}'", "file_path": "workspace/inventory/export.py"}

### Tool result
Successfully replaced 1 instance(s) of the string in '/workspace/inventory/export.py'

### Tool call: execute
{"command": "cd workspace && python -m pytest tests -v"}

### Tool result
============================= test session starts ==============================
platform linux -- Python 3.12.15, pytest-9.1.1, pluggy-1.6.0 -- /usr/local/bin/python
cachedir: .pytest_cache
rootdir: /tmp/lab-code-learn-ovl2ji9i/workspace
plugins: anyio-4.15.1, langsmith-0.14.4
collecting ... collected 6 items

tests/test_report.py::test_total_value_plain PASSED                      [ 16%]
tests/test_report.py::test_total_value_thousands_separator PASSED        [ 33%]
tests/test_report.py::test_discount_rounding_half_up PASSED              [ 50%]
tests/test_report.py::test_total_value_with_discount PASSED              [ 66%]
tests/test_report.py::test_low_stock_basic PASSED                        [ 83%]
tests/test_report.py::test_csv_row_plain_name PASSED                     [100%]

============================== 6 passed in 0.06s ===============================

[Command succeeded with exit code 0]

### Tool call: write_file
{"content": "from decimal import Decimal\nfrom inventory.export import to_csv_row\nfrom inventory.pricing import parse_price, apply_discount\nfrom inventory.report import low_stock, total_value\n\ndef test_parse_price_formats():\n    assert parse_price(\"$1,299.50\") == Decimal(\"1299.50\")\n    assert parse_price(\"  12 \") == Decimal(\"12\")\n    assert parse_price(\"1299.5\") == Decimal(\"1299.5\")\n    assert parse_price(\"(12.00)\") == Decimal(\"-12.00\")\n\ndef test_low_stock_threshold_and_sorting():\n    items = [\n        {\"name\": \"Zebra pen\", \"qty\": 4},\n        {\"name\": \"apple notebook\", \"qty\": 5},\n        {\"name\": \"Banana eraser\", \"qty\": 3},\n    ]\n    # threshold=5: qty < 5 -> Zebra pen (4), Banana eraser (3)\n    # sorted case-insensitively: \"Banana eraser\", \"Zebra pen\"\n    assert low_stock(items, threshold=5) == [\"Banana eraser\", \"Zebra pen\"]\n\ndef test_csv_row_escaping():\n    assert to_csv_row({\"name\": \"Pen, red\", \"price\": \"1.50\", \"qty\": 10}) == '\"Pen, red\",1.50,10'\n    assert to_csv_row({\"name\": 'Pen \"fancy\"', \"price\": \"2.00\", \"qty\": 5}) == '\"Pen \"\"fancy\"\"\",2.00,5'\n", "file_path": "workspace/tests/test_additional.py"}

### Tool result
Updated file /workspace/tests/test_additional.py

### Tool call: execute
{"command": "cd workspace && python -m pytest tests -v"}

### Tool result
============================= test session starts ==============================
platform linux -- Python 3.12.15, pytest-9.1.1, pluggy-1.6.0 -- /usr/local/bin/python
cachedir: .pytest_cache
rootdir: /tmp/lab-code-learn-ovl2ji9i/workspace
plugins: anyio-4.15.1, langsmith-0.14.4
collecting ... collected 9 items

tests/test_additional.py::test_parse_price_formats PASSED                [ 11%]
tests/test_additional.py::test_low_stock_threshold_and_sorting PASSED    [ 22%]
tests/test_additional.py::test_csv_row_escaping PASSED                   [ 33%]
tests/test_report.py::test_total_value_plain PASSED                      [ 44%]
tests/test_report.py::test_total_value_thousands_separator PASSED        [ 55%]
tests/test_report.py::test_discount_rounding_half_up PASSED              [ 66%]
tests/test_report.py::test_total_value_with_discount PASSED              [ 77%]
tests/test_report.py::test_low_stock_basic PASSED                        [ 88%]
tests/test_report.py::test_csv_row_plain_name PASSED                     [100%]

============================== 9 passed in 0.04s ===============================

[Command succeeded with exit code 0]

### Tool call: delete
{"file_path": "workspace/tests/test_additional.py"}

### Tool result
Deleted /workspace/tests/test_additional.py

### Tool call: execute
{"command": "cd workspace && python -m pytest tests -v"}

### Tool result
============================= test session starts ==============================
platform linux -- Python 3.12.15, pytest-9.1.1, pluggy-1.6.0 -- /usr/local/bin/python
cachedir: .pytest_cache
rootdir: /tmp/lab-code-learn-ovl2ji9i/workspace
plugins: anyio-4.15.1, langsmith-0.14.4
collecting ... collected 6 items

tests/test_report.py::test_total_value_plain PASSED                      [ 16%]
tests/test_report.py::test_total_value_thousands_separator PASSED        [ 33%]
tests/test_report.py::test_discount_rounding_half_up PASSED              [ 50%]
tests/test_report.py::test_total_value_with_discount PASSED              [ 66%]
tests/test_report.py::test_low_stock_basic PASSED                        [ 83%]
tests/test_report.py::test_csv_row_plain_name PASSED                     [100%]

============================== 6 passed in 0.08s ===============================

[Command succeeded with exit code 0]

### Assistant
[{'type': 'text', 'text': "I have successfully fixed all issues in the source code of the `inventory` package so that the entire test suite passes and every function matches its docstring specification.\n\n### Summary of Changes:\n1. **`inventory/pricing.py`**:\n   - **`parse_price`**: Updated price parsing logic to properly strip thousands separator commas (e.g. `$1,299.50`) and handle accounting negative numbers enclosed in parentheses (e.g. `(12.00)` -> `-12.00`).\n   - **`apply_discount`**: Configured `quantize` to use commercial round-half-up rounding (`ROUND_HALF_UP`) instead of the default `ROUND_HALF_EVEN` / banker's rounding.\n2. **`inventory/report.py`**:\n   - **`low_stock`**: Corrected the filter condition to strictly check if quantity is below threshold (`< threshold`) and sorted the resulting item names alphabetically ignoring case (`key=lambda s: s.lower()`).\n3. **`inventory/export.py`**:\n   - **`to_csv_row`**: Implemented RFC 4180 CSV escaping rule for item names containing commas or double quotes (wrapping in double quotes and escaping internal double quotes by doubling them).\n4. **`tests/`**:\n   - Left untouched as requested.", 'extras': {'signature': 'EmAKXgFpFH0TRJptP6Rx7pS0T660NGSvxU51TTfxzBzljM42om7YjTUtTdSBvH6MQdKpFPf5+L1z4AiDKcdoxyE1anSLaLnxHKXajK5GEW0o5ueF+Y4a4AvY+ng/rb1lXW8='}}]