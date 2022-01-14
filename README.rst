NuLauncher
==========

.. image:: https://img.shields.io/discord/930045111285465138.svg?label=&logo=discord&logoColor=ffffff&color=7389D8&labelColor=6A7EC2
   :alt: NuLauncher Discord Server
   :target: https://discord.gg/v9GpYWVya5

What is NuLauncher?
-------------------

NuLauncher is an open source launcher for Dark Age of Camelot.

* Manage your DAoC accounts, toons and teams
* Display in one place your toons levels, ranks and BPs
* Launch accounts, toons or teams easily without going through the patcher or typing your password

Quick start
-----------

* Install `AutoHotkey <https://www.autohotkey.com>`_
* Download and run `NuLauncher.ahk <https://raw.githubusercontent.com/oli-lap/NuLauncher/main/NuLauncher.ahk>`_ (Ctrl+s to download)
* Select the DAoC installation folder
* Add accounts and toons

.. image:: https://raw.githubusercontent.com/oli-lap/NuLauncher/main/NuLauncher/Capture.png
   :alt: Capture of NuLauncher
   :scale: 70 %

Features
--------

**Create, edit, delete accounts**

*  Account name
*  Optional password

   *  Will be saved in NuLauncher.json in plaintext if filled in the account creation
   *  Will be asked every time the account, toon or team is launched if left empty in the account creation. The password will not be stored in this case.

*  Optional Window name : Renames the game window

**Create, edit, delete toons**

*  Toon name
*  Toon associated account
*  Optional toon note
*  Toons infos (realm, class, level, RR, BPs, server) are automatically fetched from the official API

   *  These infos are updated every time NuLauncher is launched

**Create, edit, delete teams**

*  Two toons per team
*  Realm must be the same, toon and associated account must be different

**Select DAoC Path**

*  game.dll must be in the selected path

**When the game is running, select its account and the target screen to move its window**

**Filter by favorites only**

**Filter by realm**

Security
--------

*  Passwords saved at the Account creation are stored in plaintext in the NuLauncher.json file. It is advisable to leave the password field empty and to fill it every time the account is connected. The password will not be stored in this case.
*  Save the account password at your own risk

Limitations
-----------

*  Maximum 2 accounts can be launched at the same time
*  The 2 accounts must be logged on the same realm
*  Toons < lvl 6 can't be found on the Herald's API
*  NuLauncher doesn't go through the DAoC patcher to log in the game

   *  When a new DAoC version is avaible, start DAoC noramlly for the update to take place (no need to log in to the game)

*  Ywain only

Backup and uninstallation
-------------------------

NuLauncher's files are stored in :code:`Users\<user>\AppData\Roaming\NuLauncher`.

:code:`NuData.json` stores the informations about the accounts, toons and teams.

Delete the :code:`NuLauncher` folder to completely uninstall the software.

ToDo
----

*  Add notes to teams
*  Save and load DAoC UI layout
*  Save and load toons macros

ChangeLog
---------

*  1.1.1

   *  Initial release