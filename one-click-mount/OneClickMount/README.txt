One-Click Mount (test build 1.3.0, Retail)
=========================================

One action bar button that picks the right mount or movement spell for where you are.

Install
-------
1. Unzip so you have a folder called "OneClickMount".
2. Put it in: World of Warcraft/_retail_/Interface/AddOns/
3. Start the game (or /reload).

Getting started
---------------
- Type /ocm (or Esc > Options > AddOns > One-Click Mount).
- Drag mounts from the Mount Journal (Shift+P) into the rows.
- Drag the icon at the top right ("Drag to your bar") onto your action bar.
  It's a character macro, so you need one free character macro slot.

What the button does, in order
------------------------------
1. In combat or indoors: your class speed spell (Ghost Wolf, Aspect of the
   Cheetah, Travel Form, Divine Steed, ...), picked automatically.
2. Holding Shift / Ctrl / Alt: the mount in that row (vendor, passenger...).
3. Special zones: Qiraji tanks in Ahn'Qiraj, the G-99 in Undermine,
   underwater mounts while swimming in Vashj'ir.
4. Your own zone rules (Locations tab > Add current zone).
5. Otherwise: Flying where you can fly, Ground elsewhere.

Tips
----
- Several mounts in a row = picked at random. "Summon Random Favorite Mount"
  also works in Flying and Ground.
- Drag a slot to move it, hold Ctrl when you let go to copy, right-click to clear.
- Each rule has an on/off checkbox.
- The settings window closes during combat and reopens afterwards.

Reporting a problem
-------------------
Please include:
- what you clicked, where you were, and what happened
- the output of /ocm debug
- any Lua error text (turn errors on with: /console scriptErrors 1)
