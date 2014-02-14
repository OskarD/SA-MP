[color=#0000BF][size=200]Changelog[/size][/color]


[size=150][color=#0080BF][02/12/2011][/color] [color=#0000BF][b]3.2.0[/b][/color][/size]
[spoiler][list][*] Upgraded to SA-MP 0.3d
[*] Added /setcrimskin for admin level 1+
[*] Updated sscanf for compability
[*] Added /radiostations
[*] Added /stopstream in case something goes wrong
[*] Added /randomstream (Silly streams, not the regular channels)[/list][/spoiler]

[size=150][color=#0080BF][14/09/2011][/color] [color=#0000BF][b]3.1.7[/b][/color][/size]
[spoiler][list][*] Added /markmycar
[*] Fixed static cars
[*] Fixed some flaws in the racing system (Thanks to Nogga for reporting!)
[*] Wrote a work-around for dead queries, MySQL plugin is bugged but soon be fixed I hope[/list][/spoiler]

[size=150][color=#0080BF][14/08/2011][/color] [color=#0000BF][b]3.1.6[/b][/color][/size]
[spoiler][list][*] Added /hardrestart as a last resort if /serverrestart doesn't work
[*] (Hopefully) fixed the random character resets
[*] Brushed up on the racing system, adding millisecond (10^-3) accuracy and removing exploits.
[list][i]All times were reset because of the exploits found and fixed, old record holders are named below.[code]+----------------+-------------------+--------+
| ASU 1          | Jerome Roberts    |   15000 |
| ASU 2          | Michael_Eversmann |   10000 |
| ASU 3          | Alan Collins      |  149000 |
| Cruiser 1      | Chris Clark       |  197000 |
| ASU 4          | Alan_Collins      |  211000 |
| SVU 1          | Jack_Arsenault    |  464000 |
| SVU 5          | Nathan_Borowski   |  121000 |
| SVU 4          | Patrick_Broyles   |   25000 |
| SVU 3          | Marcus_Cambridge  |   62000 |
| SVU 2          | Lenny_Carlson     |  276000 |
| Cruiser 2      | Marcus_Cambridge  |  499000 |
| Cruiser 3      | Chris_Clark       |  269000 |
| HSIU 1         | Marcus_Cambridge  |  590000 |
| HSIU 2         | Corbin_Davidson   |       0 |
| HSIU 3         | Marcus_Cambridge  |  375000 |
| HSIU Realistic | Eduardo_Hernandez |   37000 |
| Speed corners  | Michael_Eversmann |       0 |
| LS Drift 2     | Chris_Clark       |   71000 |
| TEU 1          | Thomas_Daniels    |  170000 |
| TEU 2          | Thomas_Daniels    |  204000 |
| TEU 3          | Thomas_Daniels    |  279000 |
+----------------+-------------------+--------+
[/code]Divide them by 1000 to get the amount of seconds.[/i][/list][/list][/spoiler]

[size=150][color=#0080BF][12/07/2011][/color] [color=#0000BF][b]3.1.5[/b][/color][/size]
[spoiler][list][*] "Under the hood-tweaks"
[*] Updated /serverpanel
[*] Added threaded queries[/list][/spoiler]

[size=150][color=#0080BF][19/06/2011][/color] [color=#0000BF][b]3.1.4[/b][/color][/size]
[spoiler][list][*] Bug fixes
[*] Added /repaintmycar
[*] Added /repaintcar
[*] Added /countdown
[*] Replaced garage cars with static cars[/list][/spoiler]

[size=150][color=#0080BF][16/06/2011][/color] [color=#0000BF][b]3.1.3[/b][/color][/size]
[spoiler][list][*] Bug fixes
[*] Added a dynamic "static car" system to later replace the current garage cars system
[list][*] Added /staticcars
[*] Added /addstaticcar
[*] Added /delstaticcar[/list]
[*] Added /engine
[*] Added /setvehicleparams
[*] Added /despawnmycars[/list][/spoiler]

[size=150][color=#0080BF][14/06/2011][/color] [color=#0000BF][b]3.1.2[/b][/color][/size]
[spoiler][list][*] Many bug fixes
[*] Added /tazer and /tazerid (Taser/taserid works too)
[*] Added /siren
[*] Added /readyall
[*] Converted all races to the MySQL database
[*] Added /reloadraces[/list][/spoiler]

[size=150][color=#0080BF][06/06/2011][/color] [color=#0000BF][b]3.0.0 - 3.1.1[/b][/color][/size]
[spoiler][list][*] Wrote approximately 7000 lines of new code since v. 2:
[list][*] All commands
[*] Race system
[*] Auth system
[*] Teleports system
[*] Deathlist
[*] Personal car system[/list][/list][/spoiler]