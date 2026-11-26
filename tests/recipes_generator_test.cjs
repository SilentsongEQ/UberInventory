const assert = require('node:assert/strict');
const fs = require('node:fs');
const { readCategories, readLabels, build, lua } = require('../tools/recipes/generate.cjs');
const fixture = `
local _,app=...
app.AddEventHandler("OnBuildDataCache",function(categories)
local h,n,m,r,q,i,o,e,ah=app.CreateCustomHeader,app.CreateNPC,app.CreateMap,app.CreateRecipe,app.CreateQuest,app.CreateItem,app.CreateObject,app.CreateEncounter,app.CreateHeader;
categories.Test=m(84,{g={
h(-58,{g={n(100,{coords={[84]={{1,2}},[85]={{3,4}}},r=2,minReputation={72,42000},g={
r(9001,{itemID=101,sourceQuests={700},u=2}),
i(102,{sym={{"select","itemID",101}}})}})}}),
q(200,{sourceQuests={999},g={r(9002,{itemID=103})}}),
h(-698,{r(9003,{itemID=104})}),
o(300,{g={r(9004,{itemID=105})}}),
i(400,{g={r(9005,{itemID=106})}}),
e(500,{crs={501,502},g={r(9006,{itemID=107})}}),
e(503,{g={r(9012,{itemID=112})}}),
ah(600,{providers={{"n",601},{"n",602}},g={r(9007,{itemID=108,cost={{"i",123,1}}})}}),
q(800,app.ResolveQuestData({g={r(9008,{itemID=109})},aqd={mapID=84},hqd={mapID=85}})),
r(9010,{itemID=110,sym={{"unsupported","itemID",111}},OnInit=function() error("must not execute") end}),
r(9011,{itemID=111,crs={701,702},awp=130000}),
}})
end)
`.replaceAll('app.Create','_.Create').replace('local _,app=...', 'local appName,_=...').replaceAll('app.', '_.');
const audit={ignoredCalls:{}};
const roots=readCategories(fixture,'fixture',audit);
const labels=readLabels('local ObjectNames = {[300]="Café Chest"}\nL.QUEST_NAMES={[200]="A Quest"}\nlocalize(L.HEADER_NAMES,{[-698]="World Drops"})\nif false then L.QUEST_NAMES={[200]="Wrong"} end');
const actual=build(roots,labels);
assert(actual.sources[101].some(r=>r.kind==='vendor'&&r.id===100&&r.status==='removed'));
const vendor=actual.sources[101][0];
assert.deepEqual(vendor.maps,[84,85]);
assert.equal(vendor.faction,2);
assert.deepEqual(vendor.reputation,[72,42000]);
assert.deepEqual(vendor.quests,[700]);
assert(actual.sources[103].every(r=>r.kind==='quest'&&r.id===200));
assert(!actual.sources[103].some(r=>r.id===999),'Prerequisites must never become reward quests');
assert.equal(actual.sources[104][0].kind,'world','Positional children must be extracted');
assert.equal(actual.sources[105][0].kind,'object');
assert.equal(actual.objects[300],'Café Chest');
assert.equal(actual.quests[200],'A Quest');
assert.equal(actual.sources[106][0].kind,'container');
assert.deepEqual(actual.sources[107].map(r=>r.id),[501,502]);
assert.equal(actual.sources[112][0].kind,'encounter');
assert(actual.sources[108].every(r=>r.kind==='vendor'));
assert.deepEqual(actual.sources[108].map(r=>r.id),[601,602]);
assert.equal(actual.sources[109].length,2,'Faction variants must not create a neutral duplicate');
assert.deepEqual(actual.sources[109].map(r=>r.faction).sort(),[1,2]);
assert(actual.sources[109].every(r=>r.maps.length===1));
assert.equal(actual.sources[111][0].status,'unavailable');
assert.deepEqual(actual.audit.missingItems,[110]);
assert.equal(actual.audit.unsupportedSymbols.length,1);
assert.equal(lua(actual.sources),lua(build(roots,labels).sources),'Generation must be deterministic');
assert(!/rate|percent/i.test(lua(actual.sources)),'Drop rates must not be generated');

const report=JSON.parse(fs.readFileSync('tools/recipes/audit.json','utf8'));
assert(report.coveredItems>=5000);
assert.equal(report.legacyComparison.quest.nowWithSameKind,63);
assert(report.missingItems.length>0,'Partial coverage must be reported honestly');
console.log('PASS: recipe item IDs, source kinds, restrictions, faction variants, symbolic gaps, UTF-8, deterministic generation');
