-- Executed by run-tests.cjs with the production item-ID constants loaded.
-- Mocks widget calls to exercise the actual controller without a WoW client.
local binds, allocated = 0, 0;
local scale, pixelFactor = 1, 1;
local Frame = {};
Frame.__index = Frame;
local function frame(name, parent)
    local obj = setmetatable({name=name, parent=parent, scripts={}, attributes={},
        width=575, height=346, shown=true, value=0, low=0, high=0}, Frame);
    if name then _G[name] = obj; end;
    return obj;
end;
function Frame:GetName() return self.name; end;
function Frame:GetParent() return self.parent; end;
function Frame:GetFrameLevel() return self.level or 1; end;
function Frame:SetFrameLevel(level) self.level=level; end;
function Frame:GetFrameStrata() return self.strata or "MEDIUM"; end;
function Frame:SetFrameStrata(strata) self.strata=strata; end;
function Frame:GetScrollChild() return UberInventoryFrameScrollContent; end;
function Frame:GetEffectiveScale() return scale; end;
function Frame:GetWidth() return self.width; end;
function Frame:GetHeight() return self.height; end;
function Frame:GetLeft() return 0.37; end;
function Frame:GetTop() return 700.23; end;
function Frame:SetSize(w,h) self.width,self.height=w,h; end;
function Frame:SetWidth(w) self.width=w; end;
function Frame:SetPoint(...) self.point={...}; end;
function Frame:ClearAllPoints() end;
function Frame:SetAllPoints() end;
function Frame:SetScript(event, fn) self.scripts[event]=fn; end;
function Frame:GetScript(event) return self.scripts[event]; end;
function Frame:HookScript(event, fn)
    local old=self.scripts[event];
    self.scripts[event]=function(...) if old then old(...); end; fn(...); end;
end;
function Frame:SetAttribute(key,value) self.attributes[key]=value; end;
function Frame:GetAttribute(key) return self.attributes[key]; end;
function Frame:IsMouseOver() return self.mouseOver or false; end;
function Frame:IsShown() return self.shown; end;
function Frame:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()); end;
function Frame:SetShown(shown) self.shown=shown; end;
function Frame:Show() self.shown=true; end;
function Frame:Hide() self.shown=false; end;
function Frame:SetVerticalScroll(offset) self.offset=offset; end;
function Frame:UpdateScrollChildRect() self.rectUpdates=(self.rectUpdates or 0)+1; end;
function Frame:SetValue(value)
    self.value=math.max(self.low, math.min(self.high,value));
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,self.value); end;
end;
function Frame:SetMinMaxValues(low,high) self.low,self.high=low,high; self:SetValue(self.value); end;
function Frame:SetValueStep(step) self.step=step; end;
function Frame:SetObeyStepOnDrag() end;
function Frame:SetClipsChildren() end;
function Frame:EnableMouseWheel() end;
function Frame:RegisterEvent() end;
function Frame:SetText() end;
function Frame:UnlockHighlight() end;
function Frame:SetColorTexture() end;
function Frame:CreateTexture() return frame(); end;
function CreateFrame(_,name,parent,template)
    local obj=frame(name,parent);
    if template == "ItemButton_Template" then
        allocated=allocated+1;
        frame(name.."ItemButton",obj);
        frame(name.."ItemButtonItemName",obj);
        frame(name.."ItemButtonItemCount",obj);
    end;
    return obj;
end;
PixelUtil={GetPixelToUIUnitFactor=function() return pixelFactor; end,
    SetRoundLayoutToNearestPixelRecursively=function() end};
UBI_Sorted={};
UBI_BATTLEPET_CLASS="Battle Pets";
UberInventoryFrame=frame("UberInventoryFrame");
UberInventoryFrameBorder=frame("UberInventoryFrameBorder",UberInventoryFrame);
UberInventoryFrameBorder:SetFrameLevel(10);
UberInventoryFrameScroll=frame("UberInventoryFrameScroll",UberInventoryFrame);
UberInventoryFrameScrollContent=frame("UberInventoryFrameScrollContent",UberInventoryFrameScroll);
UberInventoryFrameScrollScrollBar=frame("UberInventoryFrameScrollScrollBar",UberInventoryFrame);
function UberInventory_UpdateButton(entry,record)
    binds=binds+1;
    entry.record=record;
    entry.button:SetAttribute("inventoryitem",record);
    entry:SetShown(record ~= nil);
end;
local cleared=0;
function UberInventory_Highlighter(_,state) if state == "off" then cleared=cleared+1; end; end;
function UberInventory_GetLink(id) return "item:"..id; end;
GameTooltip={Hide=function() end, Show=function() end, SetOwner=function() end, SetHyperlink=function() end};
BattlePetTooltip={Hide=function() end};
dofile("UberInventory_scroll.lua");
UberInventory_InventoryScroll_Init();
local view=UberInventoryFrameScroll;
assert(view.content.point and view.content.point[1]=="TOPLEFT"
    and view.content.point[2]==view, "scroll child must have a viewport origin");
assert(view:GetFrameLevel()>UberInventoryFrameBorder:GetFrameLevel(),
    "viewport must render above the black list background");
assert(view.content:GetFrameLevel()>view:GetFrameLevel());
assert(view.entries[1]:GetFrameLevel()>view.content:GetFrameLevel());
assert(view.entries[1].button:GetFrameLevel()>view.entries[1]:GetFrameLevel());
assert(view.rectUpdates>0, "native scroll bounds must be flushed before rendering");
local function populate(count)
    UBI_Sorted={};
    for i=1,count do UBI_Sorted[i]={itemid=i}; end;
    UberInventory_InventoryScroll_Refresh();
end;
local function near(a,b) assert(math.abs(a-b)<0.000001, tostring(a).." ~= "..tostring(b)); end;
local function tick(dt) local fn=view:GetScript("OnUpdate"); if fn then fn(view,dt); end; end;
local function aligned(value)
    local pixels=value/view.pixel;
    near(pixels,math.floor(pixels+0.5));
end;

for _,count in ipairs({0,1,15,16,17,18,10001}) do
    populate(count);
    local rows=math.ceil(count/2);
    near(view.maxOffset,math.max(0,rows==0 and 0 or rows*44-8-346));
    UberInventory_InventoryScroll_SetOffset(1e9);
    near(view.offset,view.maxOffset);
    local found=0;
    for _,entry in ipairs(view.entries) do
        if entry:IsShown() then
            found=found+1;
            assert(entry.record.itemid<=count);
        end;
    end;
    if count>0 then assert(found>0); end;
end;
assert(allocated==18, "pool must not scale with inventory size");
populate(100);
UberInventory_InventoryScroll_SetOffset(0);
local before=binds;
UberInventory_InventoryScroll_Wheel(-1);
tick(0.06);
near(view.current,38.5);
assert(binds==before, "animation within a row must not rebind");
aligned(view.offset);
tick(0.06);
near(view.offset,44);
assert(view.entries[1].record.itemid==3);
assert(view:GetScript("OnUpdate")==nil, "idle animation must stop");
UberInventory_InventoryScroll_Wheel(-1);
UberInventory_InventoryScroll_Wheel(-1);
near(view.target,132);
tick(0.03);
UberInventory_InventoryScroll_Wheel(1);
near(view.target,88);
tick(0.12);
near(view.offset,88);
UberInventory_InventoryScroll_Wheel(-1);
view.bar:SetValue(17.4);
near(view.current,17.4);
near(view.offset,17);
assert(view:GetScript("OnUpdate")==nil, "drag must interrupt easing");
UberInventory_InventoryScroll_Wheel(-1);
view.bar:GetScript("OnMouseDown")(view.bar);
assert(view:GetScript("OnUpdate")==nil);
UberInventory_InventoryScroll_SetOffset(500);
populate(1);
near(view.offset,0);
assert(not view.bar:IsShown());

for _,newScale in ipairs({0.64,0.8,1,1.25}) do
    scale,pixelFactor=newScale,768/1440;
    populate(5000);
    aligned(view.pitch); aligned(view:GetHeight()); aligned(view.maxOffset);
    local origin=view.point;
    aligned(UberInventoryFrame:GetLeft()+origin[4]);
    aligned(UberInventoryFrame:GetTop()+origin[5]);
    UberInventory_InventoryScroll_SetOffset(view.maxOffset);
    near(view.offset,view.maxOffset);
    local last;
    for _,entry in ipairs(view.entries) do
        if entry.record then last=entry.record.itemid; end;
    end;
    assert(last==5000, "last item must remain reachable");
end;
view.mouseOver=true;
local first=view.entries[1].button;
first.mouseOver=true;
UberInventory_InventoryItem_OnEnter(first);
assert(UBI_TooltipItem==first:GetAttribute("inventoryitem"));
UberInventory_InventoryItem_OnLeave(first);
local cage={itemid=UBI_ITEM_ID_PET_CAGE,type=UBI_BATTLEPET_CLASS};
first:SetAttribute("inventoryitem",cage);
UberInventory_InventoryItem_OnEnter(first);
assert(UBI_TooltipItem==cage, "the pet-cage placeholder must use the ordinary item tooltip path");
local previousCleared=cleared;
populate(0);
assert(UBI_TooltipItem==nil and cleared>previousCleared, "refresh must clear recycled hover");
UberInventory_InventoryItem_OnLeave(first); -- delayed leave after recycling
populate(100);
UberInventory_InventoryScroll_Wheel(-1);
view:GetScript("OnHide")(view);
assert(view:GetScript("OnUpdate")==nil);
print("PASS: inventory ranges, bounded pool, easing, reversal, dragging, shrink, scaling, hover, hide");
