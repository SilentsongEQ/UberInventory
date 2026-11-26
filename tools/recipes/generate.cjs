// Development-only. Parse ATT data as syntax; never execute upstream Lua.
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const crypto = require('node:crypto');
const parser = require('luaparse');
const config = require('./source.json');
const addon = path.resolve(__dirname, '../..');
const list = t => Object.keys(t || {}).filter(k => /^\d+$/.test(k)).sort((a,b)=>a-b).map(k=>t[k]);
const unique = a => [...new Set(a)].sort((a,b)=>a-b);

function parse(text) {
    // luaparse interprets Lua byte strings; preserve UTF-8 through its Latin-1 mode.
    return parser.parse(Buffer.from(text.replace(/^\uFEFF/, ''), 'utf8').toString('latin1'),
        { luaVersion: '5.2', encodingMode: 'pseudo-latin1' });
}
function decode(s) { return Buffer.from(s, 'latin1').toString('utf8'); }
function walk(ast, visit) {
    if (!ast || typeof ast !== 'object') return;
    visit(ast);
    for (const [key, value] of Object.entries(ast)) {
        if (key === 'comments') continue;
        if (Array.isArray(value)) value.forEach(v => walk(v, visit));
        else if (value && typeof value === 'object') walk(value, visit);
    }
}
function member(n) {
    if (n?.type === 'Identifier') return n.name;
    if (n?.type === 'MemberExpression') return member(n.base) + '.' + n.identifier.name;
    return '';
}
function readCategories(text, filename, audit) {
    const ast = parse(text), aliases = {}, roots = [];
    walk(ast, n => {
        if (n.type === 'LocalStatement') n.variables.forEach((v,i) => {
            const name = member(n.init[i]);
            if (name.startsWith('_.Create')) aliases[v.name] = name.slice(2);
        });
    });
    function value(n) {
        if (!n) return undefined;
        if (n.type === 'StringLiteral') return decode(n.value);
        if (['NumericLiteral','BooleanLiteral'].includes(n.type)) return n.value;
        if (n.type === 'UnaryExpression' && n.operator === '-') return -value(n.argument);
        if (n.type === 'TableConstructorExpression') {
            const result = {}; let i = 1;
            for (const f of n.fields) {
                const key = f.type === 'TableValue' ? i++ : f.type === 'TableKeyString' ? f.key.name : value(f.key);
                const v = value(f.value);
                if (key !== undefined && v !== undefined) result[key] = v;
            }
            return result;
        }
        if (n.type === 'CallExpression') {
            const name = member(n.base);
            if (name === '_.ResolveQuestData') return value(n.arguments[0]);
            const type = aliases[name] || (name.startsWith('_.Create') ? name.slice(2) : undefined);
            if (type) {
                const args = n.arguments.map(value);
                const data = args.find(a => a && typeof a === 'object') || {};
                return { type, id: args[0], data, file: filename };
            }
            audit.ignoredCalls[name || n.base.type] = (audit.ignoredCalls[name || n.base.type] || 0) + 1;
        }
        // Functions, API calls, identifiers, and expressions are deliberately not run.
        return undefined;
    }
    walk(ast, n => {
        if (n.type === 'AssignmentStatement') n.variables.forEach((v,i) => {
            if (member(v).startsWith('categories.')) {
                const root = value(n.init[i]);
                if (!root || typeof root !== 'object') throw Error('Unsupported category root: ' + filename);
                roots.push(root.type ? root : {type:'Root',data:{g:root},file:filename});
            }
        });
    });
    if (!roots.length) throw Error('No category roots: ' + filename);
    return roots;
}

function readLabels(text) {
    const headers = {}, objects = {}, quests = {};
    const ast = parse(text);
    function literals(table, out) {
        for (const f of table?.fields || []) {
            let k = f.key?.type === 'NumericLiteral' ? f.key.value
                : f.key?.type === 'UnaryExpression' ? -f.key.argument.value : undefined;
            if (k !== undefined && f.value.type === 'StringLiteral') out[k] = decode(f.value.value);
        }
    }
    // Only inspect top-level default labels, never locale overrides inside branches.
    for (const n of ast.body) {
        if (n.type === 'LocalStatement') n.variables.forEach((v,i) => {
            if (v.name === 'ObjectNames') literals(n.init[i], objects);
        });
        if (n.type === 'AssignmentStatement') n.variables.forEach((v,i) => {
            if (member(v) === 'L.QUEST_NAMES') literals(n.init[i], quests);
        });
        if (n.type === 'CallStatement' && member(n.expression.base) === 'localize'
            && member(n.expression.arguments[0]) === 'L.HEADER_NAMES') literals(n.expression.arguments[1], headers);
    }
    return { headers, objects, quests };
}
function nodeItem(n) {
    if (n.type === 'CreateRecipe') return n.data.itemID;
    if (['CreateItem','CreateToy','CreateCharacterUnlockQuest','CreateEnsemble','CreateDecor'].includes(n.type)) return n.data.itemID || n.id;
    if (n.type === 'CreateItemSource') return n.data.itemID; // appearance IDs are not item IDs
    return undefined;
}
function children(n) { return [...list(n.data.g), ...list(n.data)].filter(v => v?.type); }
function maps(data) {
    return unique([...list(data.maps), ...(typeof data.mapID === 'number' ? [data.mapID] : []),
        ...Object.keys(data.coords || {}).map(Number)].filter(n => Number.isInteger(n) && n > 0));
}
function intersection(a,b) { return a && b ? a.filter(v=>b.includes(v)) : a || b; }
function restrictions(parent, d) {
    const races = d.races ? list(d.races) : undefined, classes = d.c ? list(d.c) : undefined;
    return { ...parent,
        faction: d.r || parent.faction,
        races: intersection(parent.races, races), classes: intersection(parent.classes, classes),
        reputation: d.minReputation ? list(d.minReputation) : parent.reputation,
        quests: unique([...(parent.quests || []), ...list(d.sourceQuests)].filter(n=>n>0)),
        added: Math.max(parent.added || 0, d.awp || 0) || undefined,
        removed: d.rwp ? Math.min(parent.removed || Infinity,d.rwp) : parent.removed,
        availability: unique([...(parent.availability || []), ...(d.u ? [d.u] : [])]),
        conditional: parent.conditional || !!(d.customCollect || d.maxReputation || d.sourceAchievements
            || d.lc || d.e || d.isLimited || d.description || list(d.sourceQuests).some(id=>id<=0)),
    };
}
function build(roots, labels, target = config.interface) {
    const recipes = new Set(), result = {}, unresolved = [], unsupportedSymbols = [];
    function collect(n, recipeFilter = false) {
        const filter = n.type === 'CreateFilter' ? n.id === 200 : recipeFilter;
        const item = nodeItem(n);
        if (item > 0 && (n.type === 'CreateRecipe' || filter || n.data.f === 200)) recipes.add(item);
        children(n).forEach(c=>collect(c,filter));
    }
    roots.forEach(r=>collect(r));
    const usedObjects = {}, usedQuests = {};
    function add(item, source, ctx) {
        if (!recipes.has(item)) return;
        if(source.ids) { for(const id of source.ids)add(item,{...source,ids:undefined,id},ctx);return; }
        const sourceMaps = ctx.maps?.length ? ctx.maps : source.maps;
        const record = { kind: source.kind };
        if (source.id > 0) record.id = source.id;
        if (source.text) record.text = source.text;
        if (sourceMaps?.length) record.maps = sourceMaps;
        for (const k of ['faction','races','classes','reputation','quests','added','removed','availability']) {
            if (ctx[k] !== undefined && (!Array.isArray(ctx[k]) || ctx[k].length)) record[k] = ctx[k];
        }
        if (ctx.conditional) record.conditional = true;
        if (ctx.races?.length === 0 || ctx.classes?.length === 0) return;
        if (record.added > target || record.availability?.includes(1)) record.status = 'unavailable';
        else if ((record.removed && record.removed <= target) || record.availability?.includes(2)) record.status = 'removed';
        else if (record.availability?.length) record.status = 'restricted';
        if (record.kind === 'object' && labels.objects[record.id]) usedObjects[record.id] = labels.objects[record.id];
        if (record.kind === 'quest' && labels.quests[record.id]) usedQuests[record.id] = labels.quests[record.id];
        (result[item] ||= []).push(record);
    }
    function visit(n, parent) {
        const d = n.data;
        if(d.aqd || d.hqd) {
            for (const [field,faction] of [['aqd',2],['hqd',1]]) if(d[field]) {
                const branch=d[field].type?d[field]:{...n,data:{...d,...d[field],r:faction}};
                visit({...branch,data:{...branch.data,aqd:undefined,hqd:undefined,r:faction}},parent);
            }
            return;
        }
        const ctx = restrictions(parent,d), ownMaps = maps(d);
        if(n.type==='CreateMap' && n.id>0)ownMaps.unshift(n.id);
        ctx.maps = ownMaps.length ? ownMaps : parent.maps;
        if (n.type === 'CreateCustomHeader') {
            if ([-58,-22].includes(n.id)) { ctx.mode='vendor'; ctx.source=undefined; }
            else if ([-27,-19,-21,-63,-698].includes(n.id)) { ctx.mode='drop'; ctx.source={kind:'world',text:labels.headers[n.id],maps:ctx.maps}; }
            else if (n.id === -45 || n.id === -62) { ctx.mode='quest'; ctx.source=undefined; }
            else if (n.id === -56) { ctx.mode='object'; ctx.source=undefined; }
            else if ([-23,-26,-29].includes(n.id)) { ctx.mode='other';ctx.source={kind:'other',text:labels.headers[n.id] || 'Special source',maps:ctx.maps}; }
            else if(n.id === -554) { ctx.mode='other';ctx.source={kind:'other',text:'Black Market Auction House',maps:ctx.maps}; }
        }
        if (n.type === 'CreateNPC' && n.id > 0) ctx.source={kind:ctx.mode==='vendor'?'vendor':'drop',id:n.id,maps:ctx.maps};
        if (n.type === 'CreateQuest' && n.id > 0) ctx.source={kind:'quest',id:n.id,maps:ctx.maps};
        if (n.type === 'CreateObject' && n.id > 0) ctx.source={kind:'object',id:n.id,maps:ctx.maps};
        if (n.type === 'CreateEncounter') {
            const npcs=unique([...list(d.crs),...(d.npcID?[d.npcID]:[])]);
            ctx.source=npcs.length?{kind:'drop',ids:npcs,maps:ctx.maps}:{kind:'encounter',id:n.id,maps:ctx.maps};
        }
        // Custom vendor headers can identify the merchant via providers rather than n().
        const providers=list(d.providers).filter(v=>v?.[1]==='n' && v[2]>0);
        if (n.type === 'CreateHeader' && providers.length && n.id > 0) {
            ctx.source={kind:ctx.mode==='vendor'?'vendor':'drop',ids:providers.map(v=>v[2]),maps:ctx.maps};
        }
        const item=nodeItem(n);
        if (recipes.has(item)) {
            let source=ctx.source;
            if(list(d.crs).length)source={kind:d.cost?'vendor':'drop',ids:list(d.crs),maps:ctx.maps};
            else if(providers.length && d.cost)source={kind:'vendor',ids:providers.map(v=>v[2]),maps:ctx.maps};
            if (source?.kind==='drop' && (d.cost || ctx.mode==='vendor')) source={...source,kind:'vendor'};
            if (source) add(item,source,ctx);
            else unresolved.push({item,file:n.file,reason:'No explicit item source context'});
        }
        // ATT's simple select-item list is an explicit reference to those items.
        // Do not pretend to implement its full symbolic query language.
        if (d.sym) {
            const commands=list(d.sym);
            if (commands.length===1 && commands[0][1]==='select' && commands[0][2]==='itemID') {
                for(const id of list(commands[0]).slice(2)) if(recipes.has(id) && ctx.source) add(id,ctx.source,ctx);
            } else unsupportedSymbols.push({file:n.file,type:n.type,id:n.id,commands:d.sym});
        }
        const kids=children(n);
        // An item containing other items is a container, not its vendor or quest giver.
        const childCtx = item > 0 && n.type !== 'CreateRecipe' ? {...ctx,source:{kind:'container',id:item,maps:ctx.maps}} : ctx;
        kids.forEach(c=>visit(c,childCtx));
    }
    roots.forEach(r=>visit(r,{}));
    for (const [id, records] of Object.entries(result)) {
        result[id] = [...new Map(records.map(r=>[JSON.stringify(r),r])).values()]
            .sort((a,b)=>JSON.stringify(a).localeCompare(JSON.stringify(b),'en'));
    }
    const missing = [...recipes].filter(id=>!result[id]).sort((a,b)=>a-b);
    const byKind={},byStatus={};
    for(const records of Object.values(result))for(const r of records){byKind[r.kind]=(byKind[r.kind]||0)+1;byStatus[r.status||'unflagged']=(byStatus[r.status||'unflagged']||0)+1;}
    return { sources:result, objects:usedObjects, quests:usedQuests,
        audit:{recipeItems:recipes.size,coveredItems:Object.keys(result).length,byKind,byStatus,
            missingItems:missing,unresolvedContexts:unresolved,unsupportedSymbols} };
}
function lua(v) {
    if (typeof v === 'string') return '"' + v.replace(/\\/g,'\\\\').replace(/"/g,'\\"').replace(/\n/g,'\\n').replace(/\r/g,'\\r').replace(/\t/g,'\\t') + '"';
    if (typeof v === 'number' || typeof v === 'boolean') return String(v);
    if (Array.isArray(v)) return '{'+v.map(lua).join(',')+'}';
    return '{'+Object.entries(v).map(([k,value])=>(/^\d+$/.test(k)?'['+k+']':k)+'='+lua(value)).join(',')+'}';
}
async function generate(args) {
    const arg = key => { const i=args.indexOf(key);return i<0?undefined:args[i+1]; };
    const cache=path.resolve(arg('--cache')||path.join(os.tmpdir(),'ubi-recipes',config.revision));
    if(!/^[a-f0-9]{40}$/.test(config.revision))throw Error('Pin a full upstream commit SHA');
    const priorPath=path.join(__dirname,'audit.json');
    const prior=fs.existsSync(priorPath)?JSON.parse(fs.readFileSync(priorPath,'utf8')):{};
    const files={};
    async function get(file){
        const target=path.join(cache,file);let data;
        if(fs.existsSync(target))data=fs.readFileSync(target);
        else {
            if(args.includes('--offline'))throw Error('Missing offline input: '+file);
            const url='https://raw.githubusercontent.com/'+config.repository+'/'+config.revision+'/'+file.split('/').map(encodeURIComponent).join('/');
            const response=await fetch(url);if(!response.ok)throw Error(file+': HTTP '+response.status);
            data=Buffer.from(await response.arrayBuffer());fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,data);
        }
        files[file]=crypto.createHash('sha256').update(data).digest('hex');
        if(prior.revision===config.revision && prior.inputSHA256?.[file]
            && prior.inputSHA256[file]!==files[file])throw Error('Input checksum changed for pinned revision: '+file);
        return data.toString('utf8');
    }
    const manifest=await get('db/Standard/Database.xml'), license=await get('LICENSE');
    if(!license.startsWith('MIT License'))throw Error('Upstream license changed; review before importing');
    const labels=readLabels(await get('db/Standard/LocalizationDB.lua'));
    const audit={ignoredCalls:{}};const roots=[];
    for(const m of manifest.matchAll(/file="(Categories\/[^\"]+\.lua)"/g)){
        if (/(NeverImplemented|Sourceless|Unsorted)\.lua$/.test(m[1])) continue;
        const file='db/Standard/'+m[1];roots.push(...readCategories(await get(file),file,audit));
    }
    const built=build(roots,labels);
    if(built.audit.coveredItems<1000)throw Error('Unexpectedly low recipe coverage; refusing replacement');
    const metadata={...config,schema:1};
    const output='-- Generated by tools/recipes/generate.cjs. Do not edit manually.\n'
        +'-- Source: https://github.com/'+config.repository+'/tree/'+config.revision+'\n'
        +'-- Data is partial; see tools/recipes/audit.json for unsupported and unresolved sources.\n'
        +'-- AllTheThings data: MIT license, see tools/recipes/ATT-LICENSE.txt.\n'
        +'UBI_RecipeDataInfo = '+lua(metadata)+';\n'
        +'UBI_RecipeObjectNames = '+lua(built.objects)+';\n'
        +'UBI_RecipeQuestNames = '+lua(built.quests)+';\n'
        +'UBI_RecipeSources = {\n'+Object.entries(built.sources).sort((a,b)=>a[0]-b[0]).map(([id,records])=>' ['+id+']='+lua(records)+',').join('\n')+'\n};\n';
    const legacy=require('./legacy-coverage.json'), legacyComparison={};
    for(const [table,kind] of [['UBI_RecipeVendors','vendor'],['UBI_RecipeQuestRewards','quest'],['UBI_RecipeDrops','drop']]){
        legacyComparison[kind]={legacyItems:legacy[table].length,
            nowWithSameKind:legacy[table].filter(id=>built.sources[id]?.some(r=>r.kind===kind)).length,
            nowWithAnySource:legacy[table].filter(id=>built.sources[id]).length,
            missingItems:legacy[table].filter(id=>!built.sources[id])};
    }
    const report={...metadata,inputSHA256:files,excludedCategories:['NeverImplemented','Sourceless','Unsorted'],legacyComparison,
        ...audit,...built.audit};
    const out=path.resolve(arg('--output')||path.join(addon,'UberInventory_recipes.lua'));
    fs.writeFileSync(out,output);
    fs.writeFileSync(path.join(__dirname,'audit.json'),JSON.stringify(report,null,2)+'\n');
    fs.writeFileSync(path.join(__dirname,'ATT-LICENSE.txt'),license);
    console.log(JSON.stringify({output:out,recipeItems:report.recipeItems,coveredItems:report.coveredItems,missing:report.missingItems.length,byKind:report.byKind,byStatus:report.byStatus,unsupportedSymbols:report.unsupportedSymbols.length},null,2));
}
module.exports={parse,readCategories,readLabels,build,lua};
if(require.main===module)generate(process.argv.slice(2)).catch(e=>{console.error(e);process.exitCode=1;});
