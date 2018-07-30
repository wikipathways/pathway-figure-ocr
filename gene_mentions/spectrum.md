# Gene Mention Spectrum

## Objectives

Take every entry from `spectrum.json` and expand `raw` to `parsed`. If parsing is ambiguous, give all results, indicating which are ambiguous.

```
jq -r '.[].raw' spectrum.json
```

Should the lexer/parser handle cases like `I` vs. `l` vs. `1`?

## Note on Specific Cases

Alex Pico: Read more about TLR2/1 and TLR2/6… Turns out that TLR2 forms dimers with TLR1 and TLR6. So, the parsing is correct! The odd order in these cases is just the bias of biologists that know that TLR2 is the “main” or “common” component and the “1” or “6" is the add-on.


