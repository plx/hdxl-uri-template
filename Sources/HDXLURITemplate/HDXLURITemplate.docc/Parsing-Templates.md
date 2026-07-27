# Parsing Templates

Validate URI-template source against the package's strict RFC 6570 grammar.

## Overview

### Parse once and preserve exact source

Create a template with ``URITemplate/init(parsing:)``. Successful parsing
retains the exact accepted spelling in
``URITemplate/templateRepresentation`` and derives the set of referenced names
in ``URITemplate/variableNames``. The resulting value is immutable and can be
reused for many parameter sets.

The parser accepts RFC 6570 Level 4 expressions, including all defined
operators, explode modifiers, prefix modifiers, percent-encoded variable
names, Unicode literals allowed by the grammar, and multiple variable
specifications.

### Strict rejection boundaries

Parsing rejects malformed or noncanonical source instead of normalizing it.
Examples include:

- unmatched or nested braces;
- empty expressions or variable positions;
- unsupported reserved operators;
- invalid literal or variable-name scalars;
- malformed percent triplets; and
- invalid, repeated, or oversized prefix modifiers.

Catch ``URITemplate/ParseError`` to inspect a stable semantic category and an
offending UTF-8 byte range. A zero-length range identifies an insertion point,
such as the end of an unterminated expression. See
<doc:Handling-Errors-and-Diagnostics> for a compiled example and privacy
guidance.

> Note: Parsing establishes URI-template syntax, not an application trust
> decision. A syntactically valid template can still expand to an unwanted
> scheme, host, or path.
