import re

# Read the test output
with open('test-output.txt', 'r') as f:
    content = f.read()

# Find all test failures
failures = re.findall(r'􀢄.*?(?=(?:􀢄|􀢄.*Test run with|$))', content, re.DOTALL)

print(f"Total failures: {len(failures)}\n")

# Categorize failures
categories = {
    'percent_encoding_errors': [],
    'association_explode_errors': [],
    'prefix_modifier_errors': [],
    'empty_value_errors': [],
    'malformed_percent_errors': [],
    'missing_variable_errors': [],
}

for failure in failures:
    # Extract template and error type
    template_match = re.search(r'template[: ]+([^\s,\)]+)', failure)
    template = template_match.group(1) if template_match else "unknown"
    
    # Determine category
    if 'unableToEscapeVariableValue' in failure:
        categories['malformed_percent_errors'].append((template, failure[:500]))
    elif 'empty=' in failure and 'empty"' in failure:
        categories['empty_value_errors'].append((template, failure[:500]))
    elif '{.keys}' in failure or '{/keys}' in failure or '{;keys}' in failure or '{?keys}' in failure or '{&keys}' in failure:
        categories['association_explode_errors'].append((template, failure[:500]))
    elif ':4}' in failure:
        categories['prefix_modifier_errors'].append((template, failure[:500]))
    elif 'variableNotFound' in failure:
        categories['missing_variable_errors'].append((template, failure[:500]))
    elif 'admin%2F' in failure or 'red%25' in failure or 'val1%2F' in failure:
        categories['percent_encoding_errors'].append((template, failure[:500]))
    else:
        if 'percent_encoding_errors' not in categories:
            categories['percent_encoding_errors'] = []
        categories['percent_encoding_errors'].append((template, failure[:500]))

# Print summary
for category, items in categories.items():
    if items:
        print(f"\n{category.upper().replace('_', ' ')}: {len(items)} failures")
        for template, snippet in items[:3]:  # Show first 3 examples
            print(f"  - {template}")
