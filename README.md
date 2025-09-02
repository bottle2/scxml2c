# External entities

Currently ignored.

# Internal entities and billion laughs attack 

TODO Write better about this

_This_ tool is not subject to such attack, however, the tools takes no measure
to combat it, so the attack happens further down the pipeline.

Internal entities become object-like C preprocessor macro definitions, so a
possibility of Billion Laughs Attack is handed to the C compiler.

```
#define LOL "lol"
#define LOL1 LOL  LOL  LOL  LOL  LOL  LOL  LOL  LOL  LOL  LOL
#define LOL2 LOL1 LOL1 LOL1 LOL1 LOL1 LOL1 LOL1 LOL1 LOL1 LOL1
#define LOL3 LOL2 LOL2 LOL2 LOL2 LOL2 LOL2 LOL2 LOL2 LOL2 LOL2
#define LOL4 LOL3 LOL3 LOL3 LOL3 LOL3 LOL3 LOL3 LOL3 LOL3 LOL3
#define LOL5 LOL4 LOL4 LOL4 LOL4 LOL4 LOL4 LOL4 LOL4 LOL4 LOL4
#define LOL6 LOL5 LOL5 LOL5 LOL5 LOL5 LOL5 LOL5 LOL5 LOL5 LOL5
#define LOL7 LOL6 LOL6 LOL6 LOL6 LOL6 LOL6 LOL6 LOL6 LOL6 LOL6
#define LOL8 LOL7 LOL7 LOL7 LOL7 LOL7 LOL7 LOL7 LOL7 LOL7 LOL7
#define LOL9 LOL8 LOL8 LOL8 LOL8 LOL8 LOL8 LOL8 LOL8 LOL8 LOL8
static char lolz[] = LOL9;
```

# Recursive productions

The following productions are recursive:

- `element`
- `children`
- `conditionalSect`
  - Also `ignoreSectContents`

## Solution to `element` recursion

This one is the most important

## Solution to `children` recursion

Unsolved.

## Solution to `conditionalSect` and `ignoreSectContents` recursion

Unsolved.

# Datamodel

The datamodel can be either `null` or TODO, which is specific to C.
