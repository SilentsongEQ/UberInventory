// Test-only dependencies: luaparse and fengari (install locally or set NODE_PATH).
// Run from any directory with: node tests/run-tests.cjs
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const parser = require('luaparse');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');

process.chdir(path.resolve(__dirname, '..'));
const read = file => fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, '');
for (const file of fs.readdirSync('.').filter(file => file.endsWith('.lua'))) {
    parser.parse(read(file), { luaVersion: '5.2' });
}
for (const file of ['UberInventory.xml', 'UberInventory_templates.xml', 'Bindings.xml']) {
    const bindings = file === 'Bindings.xml';
    const re = bindings ? /<Binding\b[^>]*>([\s\S]*?)<\/Binding>/g
        : /<(On\w+)\b[^>]*>([\s\S]*?)<\/\1>/g;
    for (const match of read(file).matchAll(re)) {
        const body = (bindings ? match[1] : match[2]).replace(/<!--[\s\S]*?-->/g, '');
        parser.parse(`return function(self,event,elapsed,delta,offset,button,...)\n${body}\nend`,
            { luaVersion: '5.2' });
    }
}
const manifest = read('UberInventory.toc');
for (const line of manifest.split(/\r?\n/).filter(line => line.trim() && !line.startsWith('#'))) {
    assert(fs.existsSync(line.trim().replace(/\\/g, path.sep)), `Missing TOC file: ${line}`);
}
assert.match(manifest, /^## Version: 12\.1\.5\.2\r?$/m);
assert.match(read('changes.txt'), /^Version 12\.1\.5\.2\r?$/m);
assert(manifest.indexOf('UberInventory_items.lua') < manifest.indexOf('\nUberInventory.lua'));
assert.match(read('UberInventory_globals.lua'), /"GET_ITEM_INFO_RECEIVED"/);
assert.match(read('UberInventory_globals.lua'), /"ITEM_DATA_LOAD_RESULT"/);
console.log('PASS: Lua syntax, embedded handlers, manifest references, release metadata');

const globalsSource = read('UberInventory_globals.lua');
const itemConstants = parser.parse(globalsSource, { luaVersion: '5.2', ranges: true }).body
    .filter(node => node.type === 'AssignmentStatement'
        && node.variables.some(variable => variable.name?.startsWith('UBI_ITEM_ID_')));
assert.equal(itemConstants.length, 3, 'Special item IDs must be defined centrally');
const itemConstantSource = itemConstants.map(node => globalsSource.slice(...node.range)).join('\n');
function checkItemLiterals(node, file) {
    if (!node || typeof node !== 'object') return;
    if (file !== 'UberInventory_globals.lua' && node.type === 'NumericLiteral') {
        assert(![82800, 122284, 122270].includes(node.value), `${file}: use a named item ID constant`);
    }
    for (const [key, value] of Object.entries(node)) {
        if (key === 'range' || key === 'loc') continue;
        if (Array.isArray(value)) value.forEach(child => checkItemLiterals(child, file));
        else if (value && typeof value === 'object') checkItemLiterals(value, file);
    }
}
for (const file of ['UberInventory.lua', 'UberInventory_items.lua', 'UberInventory_scroll.lua']) {
    checkItemLiterals(parser.parse(read(file), { luaVersion: '5.2' }), file);
}

function run(source, label) {
    parser.parse(source, { luaVersion: '5.2' });
    const state = lauxlib.luaL_newstate();
    lualib.luaL_openlibs(state);
    const status = lauxlib.luaL_dostring(state, to_luastring(itemConstantSource + '\n' + source));
    if (status !== lua.LUA_OK) {
        const error = to_jsstring(lua.lua_tostring(state, -1));
        lua.lua_close(state);
        throw new Error(`${label}: ${error}`);
    }
    lua.lua_close(state);
}
run(read('tests/inventory_scroll_test.lua'), 'Scrolling controller');

// Load the actual production function bodies, avoiding unrelated WoW startup
// code. The functions under test are never copied into the test fixtures.
const names = [
    'UberInventory_Item', 'UberInventory_Cleanup', 'UberInventory_SortFilter',
    'UberInventory_GetAlts', 'UberInventory_SendMail', 'UberInventory_ReturnInboxItem',
    'UberInventory_MarkButton', 'UberInventory_UpdateButton', 'UberInventory_Search',
    'UberInventory_OnEvent',
    'Process_OnTooltipSetItem', 'UberInventory_GetLink',
];
const source = read('UberInventory.lua');
const functions = parser.parse(source, { luaVersion: '5.2', ranges: true }).body
    .filter(node => node.type === 'FunctionDeclaration' && names.includes(node.identifier?.name));
assert.equal(functions.length, names.length, 'Every requested production function must load');
run(functions.map(node => source.slice(...node.range)).join('\n') + '\n'
    + read('tests/inventory_regressions_test.lua'), 'Inventory regressions');

const tree = parser.parse(source, { luaVersion: '5.2', ranges: true });
const currencyTable = tree.body.find(node => node.type === 'LocalStatement'
    && node.variables.some(variable => variable.name === 'UBI_Currencies'));
assert(currencyTable, 'Currency catalog must load from production');
const currencyNames = ['UberInventory_Save_Currencies', 'UberInventory_DisplayTokens', 'UberInventory_OnMouseWheel'];
const currencyFunctions = tree.body.filter(node => node.type === 'FunctionDeclaration'
    && currencyNames.includes(node.identifier?.name));
assert.equal(currencyFunctions.length, currencyNames.length);
const currencyGlobals = `
for i=0,11 do _G['EXPANSION_NAME'..i]='Expansion '..i; end;
EXPANSION_NAME11,EXPANSION_NAME10='Midnight','The War Within';
LFG_TYPE_DUNGEON,LFG_TYPE_RAID,MISCELLANEOUS,PLAYER_V_PLAYER='Dungeon','Raid','Miscellaneous','PvP';
`;
run(currencyGlobals + source.slice(...currencyTable.range) + '\n'
    + currencyFunctions.map(node => source.slice(...node.range)).join('\n') + '\n'
    + read('tests/currencies_test.lua'), 'Currency catalog and token rendering');
