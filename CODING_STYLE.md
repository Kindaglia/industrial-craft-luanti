# IndustrialTest coding style guidelines
## Indenting
You should use tabs for indentation.

## Naming convention
Use `lowerCamelCase` for functions, variables and table keys. Use `UPPER_SNAKE_CASE` for constants and `lower_snake_case` for filenames.

## Blocks
Keywords used to open blocks (i.e. `then`, `do`) should go to the same line as the statement:
```lua
if condition then
    ...
end
```
or:
```lua
while condition do
    ...
end
```

## Variables
General rule is to keep as much variables local as possible. If variable must be global then it should go to `industrialtest` table also under subnamespace if appropriate (the same applies to functions).

## Tables
If table contains one element then it can be inlined:
```lua
someTable={element}
```
or:
```
someTable={key=element}
```
however if it contains more than one element then each element should go on separate line:
```lua
someTable={
    element1,
    element2
}
```
or:
```lua
someTable={
    key=element1,
    key2=element2
}
```