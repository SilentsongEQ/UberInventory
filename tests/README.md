# Compatibility checks

Install Python 3.12+ and `lupa==2.8`, then run from the repository root:

```text
python -m unittest discover -s tests -v
```

The tests compile all addon and bundled-library Lua files plus embedded XML
scripts using Lua 5.1. They exercise the changed functions with mocked WoW APIs:
missing saved settings, explicit false preferences, reset scope, equipment scan,
account-bank tab bounds and inaccessible data, bag and bank highlighting, current
Settings callbacks, and case/whitespace handling of `/ubi playergold`.

These tests do not run the WoW client. Before releasing 12.1.0.1, check in game:

1. Back up SavedVariables and enable Lua errors. Load both an existing character
   and a new character; confirm saved preferences and inventory remain intact.
2. Open Settings > AddOns > UberInventory. Toggle balance, transparency, and
   highlighting, close and reopen the panel, and reload. Check Reset Defaults,
   including global auto-sell, auto-repair, realm filtering, and item IDs.
3. Hover matching items with separate bags, combined bags, the reagent bag,
   character-bank tabs, account-bank tabs, and the guild bank. Verify matching
   buttons light up and clear on mouse leave or disabling highlights. Check
   that UberInventory's own item list does not acquire spurious quest borders.
4. Visit a normal bank and an account-only banker. Confirm each tab's counts,
   transfer items, reopen, and confirm unavailable bank data was not erased.
5. Change equipment and verify equipped counts. Hover the addon compartment
   icon and verify its tooltip. Run `/ubi playergold` in mixed case and with
   surrounding spaces; confirm it reports saved character wallet gold.

API references checked during this update:

- [PaperDollInfo](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/PaperDollInfoDocumentation.lua)
- [ContainerFrame](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua)
- [BankFrame](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/BankFrame.lua)
- [SettingsPanel](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_SettingsPanel.lua)
