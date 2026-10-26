"""Run with Python and lupa (Lua 5.1): python -m unittest discover -s tests -v."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / 'UberInventory.lua').read_text(encoding='utf-8')


def section(start, end):
    return SOURCE[SOURCE.index(start):SOURCE.index(end, SOURCE.index(start))]


class CompatibilityTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('''
            strlower = string.lower
            strtrim = function(s) return s:match('^%s*(.-)%s*$') end
            wipe = function(t) for k in pairs(t) do t[k] = nil end end
            tinsert = table.insert
            UBI_ACTIVE = true
            UBI_Options = {}
            UBI_Global_Options = {Options={}}
            UBI_Highlights = {}
            UBI_GUILDBANK_OPENED = false
            NUM_CONTAINER_FRAMES = 2
            UI_CONTAINER_OBJECTS = {}
            UberInventoryOptionsFrame = {}
            function UberInventory_ShowBalanceFrame() end
            function UberInventory_Change_Alpha() end
            function UberInventory_SetOptions() end
            function UberInventory_ReloadUI() reloads = (reloads or 0) + 1 end
            function UberInventory_Highlighter() end
        ''')
        defaults = (ROOT / 'UberInventory_globals.lua').read_text(encoding='utf-8')
        self.lua.execute(defaults[defaults.index('UBI_Defaults ='):])

    def test_all_lua_and_xml_scripts_compile(self):
        compile_lua = self.lua.eval('function(s, name) local f,e=loadstring(s,name); assert(f,e) end')
        for path in ROOT.rglob('*.lua'):
            compile_lua(path.read_text(encoding='utf-8-sig'), str(path))
        for path in ROOT.glob('*.xml'):
            tree = ET.parse(path)
            for element in tree.iter():
                if element.tag.endswith('Scripts'):
                    for script in element:
                        compile_lua('function XMLHandler(self, ...)\n' + (script.text or '') + '\nend', str(path))

    def test_missing_defaults_and_scope_preserve_preferences(self):
        self.lua.execute(section('    local globalOptionKeys', '    function UberInventory_Upgrade'))
        self.lua.execute('''
            local character = {show_tooltip=false, show_item_id=false, alpha=0.4}
            local global = {sell_greys=true, show_item_id=false}
            UberInventory_InitializeOptions(character, global)
            assert(character.show_tooltip == false and character.alpha == 0.4)
            assert(character.show_highlight == true and global.ignore_realm == true)
            assert(global.sell_greys == true and global.show_item_id == false)
            assert(character.show_item_id == nil and character.ignore_realm == nil)
        ''')

    def test_reset_changes_global_scope_without_resetting_migration_marker(self):
        self.lua.execute(section('    local globalOptionKeys', '    function UberInventory_Upgrade') +
                         section('    function UberInventory_SetDefaults()', '-- Make Settings frame'))
        self.lua.execute('''
            UBI_Global_Options.Options = {ignore_realm=false, sell_greys=true,
                autorepair_self=true, show_item_id=false, patch_message_version='12.1.0.1'}
            UberInventory_SetDefaults()
            assert(UBI_Global_Options.Options.ignore_realm == true)
            assert(UBI_Global_Options.Options.sell_greys == false)
            assert(UBI_Global_Options.Options.autorepair_self == false)
            assert(UBI_Global_Options.Options.show_item_id == true)
            assert(UBI_Global_Options.Options.patch_message_version == '12.1.0.1')
            assert(UBI_Options.ignore_realm == nil and reloads == 1)
        ''')

    def test_equipped_scan_uses_namespaced_api_and_skips_invalid_slots(self):
        self.lua.execute(section('    function UberInventory_Save_Equipped()', '-- Handle Guildbank items'))
        self.lua.execute('''
            UBI_EQUIP_SLOTS = {'HeadSlot', 'UnknownSlot'}
            C_PaperDollInfo = {GetInventorySlotInfo=function(name) if name=='HeadSlot' then return 1 end end}
            UberInventory_ResetCount = function(kind) assert(kind=='equip') end
            UberInventory_Item = function(bag,slot,kind) assert(slot==1 and kind=='equip'); scanned=true end
            UberInventory_Save_Equipped()
            assert(scanned)
        ''')

    def test_account_bank_scan_is_bounded_and_preserves_inaccessible_data(self):
        self.lua.execute(section('\tfunction UberInventory_Save_AccountBank()', '-- Handle Mailbox items'))
        self.lua.execute('''
            UBI_BANK_OPEN = true
            UBI_Accountbank = {Items={old=true}, Cash=500}
            Enum = {BankType={Account=2}, BagIndex={AccountBankTab_1=13, AccountBankTab_5=17}}
            local accessible = true
            C_Bank = {CanViewBank=function() return accessible end, FetchDepositedMoney=function() return nil end}
            local sizes = {[13]=2, [14]=3}
            local visited = 0
            C_Container = {
                GetContainerNumSlots=function(bag) return sizes[bag] or 0 end,
                GetContainerNumFreeSlots=function(bag) return sizes[bag] or 0 end,
                GetContainerItemLink=function(bag,slot)
                    assert(slot <= sizes[bag], 'scanned beyond tab boundary')
                    visited=visited+1
                end,
            }
            UberInventoryFrame = {IsVisible=function() return false end}
            UberInventory_Save_AccountBank()
            assert(visited==5 and UBI_Accountbank.SlotCount==5 and UBI_Accountbank.Cash==500)
            UBI_Accountbank.Items.saved=true
            accessible=false
            UberInventory_Save_AccountBank()
            assert(UBI_Accountbank.Items.saved and visited==5)
        ''')

    def test_highlights_use_live_slots_and_clear_when_disabled(self):
        self.lua.execute(section('    function UberInventory_Highlighter(', '-- Perform item search'))
        self.lua.execute('''
            local function button(bag,slot)
                return {IsShown=function() return true end,
                    GetBagID=function() return bag end, GetID=function() return slot end,
                    GetBankTabID=function() return bag end, GetContainerSlotID=function() return slot end,
                    GetNormalTexture=function() end,
                    LockHighlight=function(self) self.highlight=true end,
                    UnlockHighlight=function(self) self.highlight=false end}
            end
            SetItemButtonTextureVertexColor=function() end
            local match,wrong,bank=button(0,9),button(0,1),button(13,2)
            ContainerFrame1={IsShown=function() return true end,
                EnumerateValidItems=function() return ipairs({match,wrong}) end}
            BankFrame={BankPanel={IsShown=function() return true end,
                EnumerateValidItems=function() return next,{[bank]=true},nil end}}
            C_Container={GetContainerItemInfo=function(bag,slot)
                return {itemID=(slot==9 or bag==13) and 123 or 456} end}
            UBI_Options.show_highlight=true
            UberInventory_Highlighter(123,'on')
            assert(match.highlight and bank.highlight and not wrong.highlight)
            UBI_Options.show_highlight=false
            UberInventory_Highlighter(nil,'off')
            assert(not match.highlight and not bank.highlight and #UBI_Highlights==0)
            assert(HighlightOn==nil and HighlightOff==nil)
        ''')

    def test_slash_command_accepts_case_and_whitespace(self):
        self.lua.execute(section('    function UberInventory_SlashHandler(', '-- Create a minimap button'))
        self.lua.execute('''
            UberInventory_PlayerGold=function() called=true end
            UberInventory_SlashHandler('  PlAyErGoLd  ')
            assert(called)
        ''')

    def test_settings_use_current_callbacks(self):
        self.lua.execute(section('    function UberInventory_AddCategory(', '-- Update button mask'))
        self.lua.execute('''
            UBI_NAME='UberInventory'
            Settings={RegisterCanvasLayoutCategory=function() return {} end,
                RegisterAddOnCategory=function() end}
            local saves,updates=0,0
            UberInventory_SaveOptions=function() saves=saves+1 end
            UberInventory_UpdateUI=function() updates=updates+1 end
            local frame={}
            UberInventory_AddCategory(frame)
            frame:OnCommit()
            assert(saves==0)
            frame.optionsLoaded=true
            frame:OnCommit()
            assert(saves==1 and updates==1)
            assert(type(frame.OnDefault)=='function' and type(frame.OnRefresh)=='function')
        ''')


if __name__ == '__main__':
    unittest.main()
