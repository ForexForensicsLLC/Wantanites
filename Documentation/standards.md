# General

-   Leaset amount of assumptions as possible
-   Split code into as small of functions as possible

# Functions

## Private Functions

### Return Type

-   Is allowed to return a value other than void or int if the function can never fail

## Public Functions That Can Fail

### Return Types

-   Should only return void or int
    -   int should be value from Constants/Errors
    -   Values that would normally be returned should be passed by reference

### Params

-   Should be specified in the order:
    1. Specific Function Dependent Params
    2. General Params
    3. Objects
    4. values passed by reference prefixed with 'out'
