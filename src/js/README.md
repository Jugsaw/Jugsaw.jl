## Generating the Javascript parser for Jugsaw IR

```bash
pip install lark-js

lark-js jugsawir.lark -o jugsawirparser.js
```

## How to use?

Open `jugsawdebug.html` in a browser, in the Javascript console, type the following command:

```javascript
const parser = get_parser();

parser.parse('{"type":"Array", "fields":[[2,3], [1,2]]}')
```