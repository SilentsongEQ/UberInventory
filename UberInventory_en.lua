--[[ =================================================================
    Description:
        All strings (English) used by UberInventory.
    ================================================================= --]]

-- Strings used within UberInventory
    -- Help information
    UBI_HELP = { "UberInventory commands:",
                 "    /ubi : open/close UberInventory dialog",
                 "    /ubi { help | ? }: show this list of commands",
                 "    /ubi minimap: toggle the minimap button",
                 "    /ubi <string>: search for items within your inventory",
                 "    /ubi { remchar | remguild } <name-server>: Remove character or guildbank data",
                 "    /ubi resetpos: Reset position of the main UberInventory frame",
                 "    /ubi sendgb: Force sending of guildbank data to other online guildmembers",
                 "    /ubi requestgb: Request guildbank data from other online guildmembers",
                 "    /ubi popup: Show current patch level message dialog" };

    -- Chatframe strings
	UBI_UPGRADE_MESSAGE = C_GREEN.."UBI Reborn, The War Within"..C_CLOSE;
	UBI_MONEY_MESSAGE = "You now have %s";
	UBI_ACCOUNT_SUMMARY_MESSAGE = C_GOLD.."Account Summary";
	UBI_MONEY_PLAYER_MESSAGE_MINIMAP = "|cffeda55fPlayer Gold: "..C_WHITE.."%s";
	UBI_MONEY_ACCOUNT_MESSAGE_MINIMAP = "|cffeda55fOverall Gold: "..C_WHITE.."%s";
	UBI_MONEY_MESSAGE_GREYSELL = "Grey items were sold for %s";
	UBI_MONEY_MESSAGE_AUTOREPAIR_SELF = "Equipment was repaired for %s";
    UBI_STARTUP_MESSAGE = UBI_NAME.." ("..C_GREEN..UBI_VERSION..C_CLOSE..") loaded.";
    UBI_LAST_BANK_VISIT = "Your last visit to the bank was %s day(s) ago, please visit a bank.";
    UBI_VISIT_BANK = C_RED.."Please visit the nearest bank to update inventory data."..C_CLOSE;
    UBI_LAST_GUILDBANK_VISIT = "Your last visit to the guildbank was %s day(s), please visit the guildbank.";
    UBI_VISIT_GUILDBANK = C_RED.."Please visit the nearest guildbank to update inventory data."..C_CLOSE;
    UBI_LAST_MAILBOX_VISIT = "Your last visit to a mailbox was %s day(s) ago, please visit a mailbox.";
    UBI_VISIT_MAILBOX = C_RED.."Please visit the nearest mailbox to update inventory data."..C_CLOSE;
    UBI_UPGRADE = "Upgrading UberInventory data to the current version.";
	UBI_ADDON_FIRSTLOAD = UBI_NAME.." data has been refreshed.";
    UBI_MAIL_CASH = "A mail from %s with subject '%s' had %s attached.";
    UBI_NEW_VERSION = "%s is using a newer version of UberInventory (%s). Please download the latest version from curse.com";
    UBI_NEW_GBDATA = "Receiving new guildbank data (%s)";
    UBI_CASH_TOTAL = "Total cash";
    UBI_MAIL_CHECK_MESSAGE = C_YELLOW.."Checking for mail nearing expiration."..C_CLOSE;
	UBI_MAIL_CHECK_GOOD = "Mail is in good order for all characters.";
    UBI_MAIL_EXPIRES = C_RED.."%s-%s has %d mail(s) that will expire in %d day(s)."..C_CLOSE;
	UBI_MAIL_EXPIRES_LISTBOX = "%s-%s has %d mail(s) that will expire in %d day(s)."..C_CLOSE;
    UBI_MAIL_LOST = C_RED.."%s-%s has LOST %d mail(s) that expired %d day(s) ago."..C_CLOSE;
    UBI_MAIL_EMPTY = C_COPPER.."No mailbox data to process. Either you have no mail, or you need to visit mailboxes so that UBI can scan them."..C_CLOSE;
	UBI_CRITICAL_MAIL_STATUS = "Critical Mails: "..C_CLOSE;
	UBI_SENDGB_VISIT = C_RED.."To be able to forcibly send guildbank data, the guildbank needs to be visited within the current session first."..C_CLOSE;
    UBI_SENDGB_ACCESS = C_RED.."To be able to send guildbank data at least 'View Tab'-permission for each of the guildbank tabs is required."..C_CLOSE;
    UBI_GB_SENDING = "Sending guildbank data to online guildmembers...";
    UBI_GB_REQUESTED = "Request for guildbank data has been sent to online guildmembers...";
	UBI_POPUP_REQUESTED = "Showing current patch message dialog...";
	UBI_CHAR_DELETE = "Character & Guild Data Deletion";
	UBI_RESTED_STRING1 = "%d%% / 150%% rested.";
	UBI_RESTED_NONE = "You have no rested experience.";

    -- UI element titles
    UBI_OPTIONS_TITLE = UBI_NAME.." "..UBI_VERSION ;
    UBI_OPTIONS_SUBTEXT = "These options change the behaviour of "..UBI_NAME..". Type "..C_GOLD.."/ubi help"..C_CLOSE.." for more options.";
    UBI_TEXT_ITEM = "Items";
    UBI_TEXT_QUALITY = "Quality";
    UBI_TEXT_CLASSES = "Types";
    UBI_TEXT_SEARCH = "SEARCH";
    UBI_TEXT_CHARACTER = "Character";
    UBI_ALT_CHARACTER = "Other Characters";
    UBI_TEXT_GUILDBANKS = "Guildbanks";
    UBI_ALL_GUILDBANKS = "All Guildbanks";
    UBI_ALL_CHARACTERS = "All Characters";
	UBI_ACCOUNT_BANK_TITLE = C_BLUE.."Warband Bank"..C_CLOSE;
    UBI_USABLE_ITEMS = "Usable Items Only";
    UBI_USABLE_ITEMS_TIP = "When checked only usable items will be shown";

    -- Dropdown box Locations
	UBI_FILTER_LOCATIONS_ALLITEMS_INDEX = 1;
	UBI_FILTER_LOCATIONS_ACCOUNTBANK_INDEX = 2;
	UBI_FILTER_LOCATIONS_PLAYER = 4;
    UBI_ALL_LOCATIONS = "All Items                       ";
    UBI_LOCATIONS = { "Bags",
                      "Bank",
                      "Mailbox",
                      "Equipped",
                      "Void Storage",
                      "Reagent Bank" };

    -- Dropdown box classes
    UBI_ALL_CLASSES = "All Types";

    -- Button strings
    UBI_OPTIONS_BUTTON = "Options";
    UBI_CLOSE_BUTTON = "Close";
    UBI_RESET_BUTTON = "Reset";
	UBI_MAIL_BUTTON = "Mail Check";
	UBI_CHARDEL_BUTTON = "Cleanup";

    -- Item information strings
    UBI_FREE = "%d of %d";
    UBI_ITEM_SELL = "Sell: ";
    UBI_ITEM_BUY = "Buy: ";
    UBI_ITEM_BUYOUT = "Auction Buyout: ";
    UBI_ITEM_RECIPE_SOLD_BY = "Sold for %s by";
    UBI_ITEM_RECIPE_REWARD_FROM = "Reward from quest";
    UBI_ITEM_RECIPE_DROP_BY = "Dropped by";
	UBI_ITEM_COUNT = "Count: %d (%d / %d / %d / %d / %d / %d)";
    UBI_ITEM_COUNT_SINGLE = "Count: %d";
    UBI_ITEM_SEARCH = "Inventory search for '%s'";
    UBI_ITEM_SEARCH_NONE = "No items found";
    UBI_ITEM_SEARCH_DONE = "Inventory search completed";
    UBI_ITEM_UNCACHED = "Uncached item";
    UBI_INVENTORY_COUNT = " ( "..UBI_FREE.." ) ";
	UBI_SPACE_TITLE = "Space";
	UBI_MONEY_TITLE = "Money";
    UBI_MONEY_WALLET = "Character:"; -- Uses extra space to make the moneyframes align with UBI_MONEY_MAIL and UBI_MONEY_GUILDALT
    UBI_MONEY_MAIL = "Mail:";
    UBI_MONEY_GUILDALT = "Guild/Alt:";
	UBI_MONEY_ACCOUNT = "Overall:";
    UBI_NO_GUILDALT = "No guild/alt selected";
    UBI_BAG = "Bags";
    UBI_BANK = "Bank";
    UBI_REAGENT = "Reagent Bank";
	UBI_ACCOUNT_BANK = "Warband Bank";
    UBI_SLOT_BAGS = UBI_BAG..": "..UBI_FREE.." free";
    UBI_SLOT_BANK = UBI_BANK..": "..UBI_FREE.." free";
    UBI_SLOT_REAGENTBANK = UBI_REAGENT..": "..UBI_FREE.." free";
	UBI_SLOT_ACCOUNTBANK = UBI_ACCOUNT_BANK..": "..UBI_FREE.." free";
    UBI_ALL_QUALITIES = "All Qualities";
    UBI_MAIL_CASH = "Received %s from %s (%s)";

    -- Data removal
    UBI_REM_CASESENSITIVE = "Be aware strings are case-sensitive!";
    UBI_REM_WARNING = "Removal of data cannot be undone!!";
    UBI_REM_CHARNOTFOUND = "Character "..C_YELLOW.."%s"..C_CLOSE.." not found. "..UBI_REM_CASESENSITIVE;
    UBI_REM_GUILDNOTFOUND = "Guildbank "..C_YELLOW.."%s"..C_CLOSE.." not found. "..UBI_REM_CASESENSITIVE;
    UBI_REM_CHARACTER = "Remove data for character "..C_YELLOW.."%s"..C_CLOSE.."? "..UBI_REM_WARNING;
    UBI_REM_GUILDBANK = "Remove data for guildbank "..C_YELLOW.."%s"..C_CLOSE.."? "..UBI_REM_WARNING;
    UBI_REM_DONE = "Data has been succesfully removed for "..C_YELLOW.."%s"..C_CLOSE..".";
    UBI_REM_NOTALLOWED = "You cannot remove data for the current character "..C_YELLOW.."%s"..C_CLOSE..".";
	UBI_REM_CHARACTER_FORMAT = "Character must be in the format of name-realm.";

    -- Checkbox strings (and tooltips)
    UBI_OPTION_MONEY = "Show money notifications";
    UBI_OPTION_MONEY_TIP = "If checked a message will be added to the default chat frame showing your current balance.";
    UBI_OPTION_BALANCE = "Show current balance";
    UBI_OPTION_BALANCE_TIP = "If checked you will always be able to see your current balance in the top left corner of the UI.";
    UBI_OPTION_SHOWTOOLTIP = "Show tooltip information";
    UBI_OPTION_SHOWTOOLTIP_TIP = "If checked information will be added to item tooltips|n|n";
    UBI_OPTION_RECIPEPRICES = "Show recipe buying prices";
    UBI_OPTION_RECIPEPRICES_TIP = "If checked you will be able to see prices for recipes avialable from merchants.";
    UBI_OPTION_QUESTREWARD = "Show recipe quest reward info";
    UBI_OPTION_QUESTREWARD_TIP = "If checked you will be able to see whether or not a recipe is obtainable from a quest.";
    UBI_OPTION_RECIPEDROP = "Show recipe drop info";
    UBI_OPTION_RECIPEDROP_TIP = "If checked you will be able to see which mobs drop a recipe.";
    UBI_OPTION_ITEMCOUNT = "Show item count info";
    UBI_OPTION_ITEMCOUNT_TIP = "If checked item counts will be shown within item tooltips";
    UBI_OPTION_SHOWMAP = "Show minimap icon";
    UBI_OPTION_SHOWMAP_TIP = "If checked an icon will be show at the border of the minimap.";
    UBI_OPTION_ALPHA = "Alpha/Transparency (%d)";
    UBI_OPTION_ALPHA_TIP = "Slide to change the alpha (transparency) of the frames.";
    UBI_OPTION_TAKEMONEY = "Take inbox money";
    UBI_OPTION_TAKEMONEY_TIP = "If checked money attached to mail will automatically be collected into your bag.";
    UBI_OPTION_GBSEND = "Send guildbank data";
    UBI_OPTION_GBSEND_TIP = "If checked guildbank data will be sent to other online guild members.";
    UBI_OPTION_GBRECEIVE = "Receive guildbank data";
    UBI_OPTION_GBRECEIVE_TIP = "If checked data received from other guild members will overwrite your current data.";
    UBI_OPTION_WARN_MAILEXPIRE = "Warn if mails are about to expire";
    UBI_OPTION_WARN_MAILEXPIRE_TIP = "If checked you will be warned about mails that will expire within "..UBI_MAIL_EXPIRE_WARNING.." days.";
    UBI_OPTION_HIGHLIGHT = "Highlight bags/items";
    UBI_OPTION_HIGHLIGHT_TIP = "If checked bags and item slots will be higlighted based on the item you hover over in the inventory frame";
    UBI_OPTION_GBTRACK = "Track guildbank data";
    UBI_OPTION_GBTRACK_TIP = "If checked guildbank data for the current toon will not be stored.|nData already stored will not be removed.|nUse the command /ubi remguild <guild name> to delete unwanted data.";
    UBI_OPTION_PRICES_VENDOR = "Vendor";
    UBI_OPTION_PRICES_VENDOR_TIP = "Item overview will display Vendor sell and buy prices";
    UBI_OPTION_PRICES_AH = "Auction House";
    UBI_OPTION_PRICES_AH_TIP = "Item overview will display Auction House buyout prices from installed Auction House related Add Ons, like AuctionLite, Auctionator, etc.";
    UBI_OPTION_REALMIGNORE = "Ignore realm";
    UBI_OPTION_REALMIGNORE_TIP = "Perform a comprehensive inventory across all realms for a faction. UBI will not restrict to a realm when performing any function.";
    UBI_OPTION_SELLGREYS = "Auto-sell grey items";
    UBI_OPTION_SELLGREYS_TIP = "Auto-sell all grey items that are in your bags when a merchant window is opened. This option is global.";
    UBI_OPTION_AUTOREPAIRSELF = "Auto-repair using own coin";
    UBI_OPTION_AUTOREPAIRSELF_TIP = "Auto-repair using your own money when a repair merchant window is opened. This option is global.";
    UBI_OPTION_SHOWITEMID = "Show item id";
    UBI_OPTION_SHOWITEMID_TIP = "Show item id as part of the UBI General Info section of a tooltip. This option is global.";
    UBI_OPTION_PLACEHOLDER = "PLACEHOLDER";
    UBI_OPTION_PLACEHOLDER_TIP = "PLACEHOLDER TOOLTIP.";
	
    -- Section headings
    UBI_SECTION_GENERAL = "General Settings";
    UBI_SECTION_GUILDBANK = "Guildbank Settings";
    UBI_SECTION_TOOLTIP = "Tooltip Settings";
    UBI_SECTION_MINIMAP = "Minimap Settings";
    UBI_SECTION_WARNINGS = "Warning Settings";
    UBI_SECTION_PRICING = "Pricing Info";

    -- Binding strings
    BINDING_HEADER_UBI = "UberInventory Bindings";
    BINDING_NAME_TOGGLEUBI = "Toggle UberInventory";
    BINDING_NAME_TOGGLEUBITOOLTIP = "Toggle Tooltip ";

    -- Miscellaneous
    UBI_MOVEMENT = "Hold down shift key to move frame to a different location";
	UBI_MINIMAP_OFF = "The minimap icon is disabled. Type  "..C_GOLD.."/ubi minimap"..C_CLOSE.." to enable.";
	UBI_MINIMAP_ON = "The minimap icon is now enabled.";