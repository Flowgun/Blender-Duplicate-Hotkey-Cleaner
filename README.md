# Blender-Duplicate-Hotkey-Cleaner

====================================================================

	Description:
   Blender tends to duplicate some addon hotkeys when a key configuration is imported/exported.
   As far as I understand, this is due to addons injecting their hotkeys again after importing the file,
   even if said hotkeys already exist in the file. Exporting and importing again will do it over and over again.

  This script checks for duplicate hotkeys in a chosen file in a redumentary way in each of Blender's hotkey sections,
  and it creates two files with the same name, but an added suffix:
- "_Cleaned": this file contains the hotkeys in the original file, but it removes all the duplicates in each category.
- "_AllDuplicateRemoved": this file removes all instances of hotkeys that are duplicated. This can be useful as addons
  tend to reinject them anyways (and it can be compared with "_Cleaned" if needed).
====================================================================

