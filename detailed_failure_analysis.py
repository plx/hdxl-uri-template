import re
import json

with open('test-output.txt', 'r') as f:
    content = f.read()

# Extract all failures with detailed info
failures = []
failure_blocks = re.findall(r'􀢄\s+Test.*?(?=(?:􀢄|􀢄.*Test run with|simple @|reserved @|fragment @|label @|pathSegment @|pathParameter @|query @|queryContinuation @))', content, re.DOTALL)

for block in failure_blocks:
    failure = {}
    
    # Extract template
    template_match = re.search(r'`([^`]+)`', block)
    if template_match:
        failure['template'] = template_match.group(1)
    
    # Extract test source
    source_match = re.search(r'→ `([^`]+)`', block)
    if source_match:
        failure['source'] = source_match.group(1)
    
    # Extract expected vs observed
    expected_match = re.search(r'expected: ([^\n]+)', block)
    observed_match = re.search(r'observed: ([^\n]+)', block)
    
    if expected_match:
        failure['expected'] = expected_match.group(1).strip()
    if observed_match:
        failure['observed'] = observed_match.group(1).strip()
    
    # Extract error type
    if 'unableToEscapeVariableValue' in block:
        failure['error_type'] = 'Malformed percent-encoded value'
        error_match = re.search(r'unableToEscapeVariableValue\("([^"]+)"', block)
        if error_match:
            failure['problematic_value'] = error_match.group(1)
    elif 'variableNotFound' in block:
        failure['error_type'] = 'Variable not found'
        var_match = re.search(r'variableNotFound\("([^"]+)"', block)
        if var_match:
            failure['missing_variable'] = var_match.group(1)
    elif 'empty=' in block:
        failure['error_type'] = 'Empty value formatting'
    elif 'keys' in block.lower() and ('comma,%2C' in block or 'dot,.' in block):
        failure['error_type'] = 'Association (explode) formatting'
    elif ':4}' in block or 'path:4' in block:
        failure['error_type'] = 'Prefix modifier with special chars'
    elif 'admin%2F' in block or '%25' in block or '%2F' in block:
        failure['error_type'] = 'Percent-encoded input handling'
    else:
        failure['error_type'] = 'Other'
    
    failures.append(failure)

# Group by error type
by_type = {}
for f in failures:
    error_type = f.get('error_type', 'Unknown')
    if error_type not in by_type:
        by_type[error_type] = []
    by_type[error_type].append(f)

print("=" * 80)
print("DETAILED FAILURE ANALYSIS")
print("=" * 80)
print()

for error_type, items in by_type.items():
    print(f"\n{'=' * 80}")
    print(f"{error_type.upper()} ({len(items)} failures)")
    print('=' * 80)
    
    for i, item in enumerate(items[:3], 1):  # Show first 3 examples
        print(f"\nExample {i}:")
        print(f"  Template: {item.get('template', 'N/A')}")
        print(f"  Source: {item.get('source', 'N/A')}")
        if 'observed' in item:
            print(f"  Observed: {item['observed']}")
        if 'expected' in item:
            print(f"  Expected: {item['expected']}")
        if 'problematic_value' in item:
            print(f"  Problematic value: {item['problematic_value']}")
        if 'missing_variable' in item:
            print(f"  Missing variable: {item['missing_variable']}")
    
    if len(items) > 3:
        print(f"\n  ... and {len(items) - 3} more similar failures")

print(f"\n\n{'=' * 80}")
print(f"TOTAL: {len(failures)} test failures")
print('=' * 80)
