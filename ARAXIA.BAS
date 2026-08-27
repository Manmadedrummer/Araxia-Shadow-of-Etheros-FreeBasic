#include "fbgfx.bi"
Option Gosub    ' NpcTalk uses Gosub

' Native Windows MIDI playback via MCI (winmm.dll, built into Windows)
#inclib "winmm"
Declare Function mciSendString Alias "mciSendStringA" (ByVal cmd As ZString Ptr, ByVal ret As ZString Ptr, ByVal retlen As ULong, ByVal hwndcb As Integer) As Integer
Declare Function midiOutSetVolume Alias "midiOutSetVolume" (ByVal dev As Integer, ByVal vol As ULong) As Integer

Declare Sub LoadMap (map$, p%, wx%, wy%)
Declare Sub quit ()
Declare Sub FixLanding ()
Declare Sub killer ()
Declare Sub Shop1 ()
Declare Sub Shop2 ()
Declare Sub Shop3 ()
Declare Sub Shop4 ()
Declare Sub Shopkeeper ()
Declare Sub GotAItem ()
Declare Sub Death ()
Declare Sub Story ()
Declare Sub LoadEnemies ()
Declare Sub Fight ()
Declare Sub LoadGame ()
Declare Sub MenuStatus ()
Declare Sub MenuItems ()
Declare Sub LookRelics ()
Declare Sub MenuEquip ()
Declare Sub SellWeapon ()
Declare Sub SellArmor ()
Declare Sub Menu1 ()
Declare Sub MenuSaveGame ()
Declare Sub Info ()
Declare Sub WhatsUp (FileName$)
Declare Sub NpcTalk (FileName$)
Declare Sub CheckFig ()
Declare Sub CheckMusic ()
Declare Sub LoadShit ()
Declare Sub TEXT (a$, C as integer, XCoordinate as integer, YCoordinate as integer, Size as integer)
Declare Sub delay (Seconds as integer)
Declare Sub box (X, y, x2, y2)
Declare Sub ChangeAnim ()
Declare Sub InitVars ()
Declare Sub LoadTiles ()
Declare Sub waitkey ()
Declare Sub Begin ()
Declare Sub Loadfont ()
Declare Sub ShowMap ()
Declare Sub SetupPalette ()
Declare Sub SetupLevels ()
Declare Sub CheckLevelUp ()
Declare Sub MoveDown ()
Declare Sub MoveLeft ()
Declare Sub MoveRight ()
Declare Sub MoveUp ()
Declare Sub putPlayerPic ()
Declare Sub PutTile (Ico, Jco, MapNo)
Declare Sub TheEnd
Declare Sub LoopMIDI
Declare Sub MusicUpdate ()
Declare Sub LoadMusic ()
Declare Sub PlayTrack (t As Integer)
Declare Sub ApplyVolume ()
Declare Sub SetVideoMode (m As Integer)
Declare Sub DoPresent ()
Declare Sub Present ()
Declare Sub PresentFrame ()
Declare Sub LoadSettings ()
Declare Sub SaveSettings ()
Declare Sub MenuOptions ()
Declare Sub MenuBestiary ()
Declare Sub InitMiniColors ()
Declare Function FogZone (ByVal p As Integer) As Integer
Declare Sub GoFishing ()
Declare Sub FightEtheros ()
Declare Sub FightThrollux ()
Declare Sub ControlsMenu ()
Declare Sub SearchBarrel ()
Declare Sub LoadNpcMap (mapfile$)
Declare Sub CheckDoor ()
Declare Sub RollEncounter (lo As Integer, hi As Integer)
Declare Function NpcAt$ (col, row)
Declare Sub ReadNpcPage (FileName$, pageno, tx1$, tx2$, tx3$, tx4$, tx5$, r1$, t1, r2$, t2, r3$, t3)
Declare Function GetName () As String
Declare Function PopField (ByRef s As String) As String

Declare Function Fixed$ (Num%)


Type WorldDataType
    Rows            As Integer
    Cols            As Integer
    TopRow          As Integer
    TopCol          As Integer
    Action          As Integer
    Place           As Integer
    AnimCycle       As Integer
    Direc           As Integer
    PlayerY         As Integer
    Terreng         As Integer
    NPC             As Integer
    NPCcol          As Integer
    NPCrow          As Integer
    Inside          As Integer
End Type

Type MapType
    Tile            As Integer
    Walkon          As Integer
End Type

Type WarpType
    srcCol          As Integer
    srcRow          As Integer
    destMap         As String
    destPlace       As Integer
    destInside      As Integer
    destCol         As Integer
    destRow         As Integer
End Type

Type Playerdata
    frame as integer
    nextframe as integer
    dir as integer
end type

Const North = 1, South = 2, East = 3, West = 4

Dim Shared CharSet(128, 8, 6) as integer, kbd$, RndNum1, RndNum2
Dim Shared HowMany, Enemy1Name$, Enemy1Hp, Enemy1Attack, Enemy1Defense, Enemy1Poison, Enemy1Gold
Dim Shared Enemy2Name$, Enemy2Hp, Enemy2Attack, Enemy2Defense, Enemy2Poison, Enemy2Gold
Dim Shared Enemy3Name$, Enemy3Hp, Enemy3Attack, Enemy3Defense, Enemy3Poison, Enemy3Gold
Dim Shared kills, Runa, Hp, MaxHp, chrname as string, gold%, Poisoned, PHerb, Fpot, SPot, AHerb, Wep$, Arm$, WepB, ArmB, ItemWepB, ItemArmB, O1, O2, O3, O4, O5, Q1, Q2, Q3, Q4, Q5, Trophies
Dim Shared DeathQ As Integer   ' Deathbane quest: 0 open,1 boss dead,2 claimed
Dim Shared As Integer Level
Dim Shared As Long PlayerExp
Dim Shared As Long LvlXP(1 To 20)   ' cumulative XP required to REACH each level
Dim Shared Bestiary(1 To 60) As Integer   ' kills per enemy.dat index (5 = stats unlocked)
Dim Shared Enemy1Nr As Integer, Enemy2Nr As Integer, Enemy3Nr As Integer
Dim Shared TileColor(-9 To 120) As Integer   ' mini-map color per tile number
Dim Shared Fish As Integer   ' caught fish, sold cheap at shops
Dim Shared RareFish As Integer   ' rare fish, sold for 5 gold each
Dim Shared MiniTrans As Integer   ' mini-map: 0 solid,1 light,2 med,3 heavy,4 off
Dim Shared Fog(1 To 4, -9 To 67, -9 To 67) As UByte   ' fog-of-war: visited tiles per dungeon zone
Dim Shared OwnWep2 As Integer, OwnWep3 As Integer, OwnWep4 As Integer, OwnWep6 As Integer
Dim Shared OwnArm2 As Integer, OwnArm3 As Integer, OwnArm4 As Integer, OwnArm6 As Integer
Dim Shared PlayerLeft1(129), PlayerUp1(129), PlayerDown1(129), PlayerRight1(129)
Dim Shared PlayerLeft2(129), PlayerUp2(129), PlayerDown2(129), PlayerRight2(129)
Dim Shared PlayerLeft1Mask(129), PlayerUp1Mask(129), PlayerDown1Mask(129), PlayerRight1Mask(129)
Dim Shared PlayerLeft2Mask(129), PlayerUp2Mask(129), PlayerDown2Mask(129), PlayerRight2Mask(129)
Dim Shared WorldData As WorldDataType
Dim Shared map(-9 To 67, -9 To 67) As MapType
Dim Shared Warps(200) As WarpType, WarpN As Integer
Dim Shared EnemyLo As Integer, EnemyHi As Integer
Dim Shared NpcFile$, PlaceMidi, File$
dim shared as ubyte Pal(255,3)
Dim Shared path01(201), grass1(201), grass2(201), wall1(201), wall2(201), roof1(201), door1(201), desk1(201)
Dim Shared water1(201), tree1(201), wall01(201), wall02(201), black(201), firepc(201), path02(201), tree3(201), Grass4(201)
Dim Shared bush1(201), wind1(201), bed1(201), wind2(201), tree2(201), door2(201), path03(201), bed2(201), Grass3(201)
Dim Shared barrel1(201), table1(201), torch1(201), sign1(201), shelf1(201), gold1(201), sign2(201), tree4(201), Hedge01(201), Hedge02(201), dock1(201)
Dim Shared lamp1(201), crate1(201), dbarrel1(201), dock2(201), rope1(201), well1(201)
Dim Shared Potio1(79), Potio2(79), PoisLeaf(79), Potio3(79), Desk2(201), Table2(201), Clerk1(201), rock1(201)
Dim Shared AshyGround(201), EmberPile(201), GraveMound(201), Tombstone(201), Tombstone2(201), IronFence(201), WoodenFence(201)
Dim Shared Man01(201), Man01m(201), Man02(201), Man03(201), Man04(201), Man05(201), Man05m(201), Man06(201), Man07(201)
Dim Shared Lich(201), Bhaulx(201)
dim shared as integer CurMidi, NewMidi
dim shared heroimg(3,3,129) as short, Player as Playerdata, SX as integer, SY as integer, move as integer
dim shared nomidi as integer

' --- Araxia engine additions --------------------------------
Dim Shared MusicOpen As Integer        ' 1 = an MCI sequencer is open
Dim Shared KeyInteract$, KeyInv$, KeyMenu$   ' rebindable keys
Dim Shared NpcMapCol(200), NpcMapRow(200), NpcMapFile$(200), NpcMapN  ' per-map NPC dialogue overrides
Dim Shared BarrelX(100), BarrelY(100), BarrelN   ' barrels searched on this map
Dim Shared As Integer BrokenDagger, BustedArmor  ' leftover junk from old saves (sell-only)
Dim Shared MusicName(5) As String
Dim Shared EncSteps As Integer, EncNeed As Integer, EncGrace As Integer, EncLastPlace As Integer

Dim Shared CurMap As String

Dim Shared As Integer VideoMode        ' 0=fullscreen 1=1080p 2=720p 3=360p
Dim Shared As Integer MusicVol         ' 0..10
Dim Shared As Integer ScrW, ScrH, DeskW, DeskH
Dim Shared As Double LastPresent
Redim Shared As Integer XMap(0), YMap(0)
Declare Function memcpy cdecl Alias "memcpy" (ByVal d As Any Ptr, ByVal s As Any Ptr, ByVal n As UInteger) As Any Ptr

Dim z As String
Dim as Integer X, i

Chdir "data\"
Randomize Timer
WindowTitle "Araxia: Shadow of Etheros"

nomidi = 0
CurMidi = -1: NewMidi = -1
LoadSettings
ScreenInfo DeskW, DeskH                ' desktop size (for fullscreen)
SetVideoMode VideoMode

LoadShit
InitMiniColors

Do
    If O5 = 2 Or Hp <= 0 Then Death: Begin: Goto jop
    If O5 = 3 Then Begin: Goto jop
        
    Select Case WorldData.Place
    Case 1, 2, 4, 5, 6, 7, 8, 9, 12       ' Thunder Bay region towns + Balthix (outdoor)
        NewMidi = 1
    Case 40 To 48                        ' any building interior - same as town
        NewMidi = 1
    Case Else                            ' Caves(3), Eversmoke Woods,
        NewMidi = 2                      ' Cemetary, Temple, Gate, Lair, etc.
    End Select
    LoopMidi
    
    kbd$ = INKEY$
    
    jop:
    'LOCATE 1, 1: PRINT "X:"; WorldData.TopCol; "Y:"; WorldData.TopRow; "T:"; WorldData.Terreng; "P:"; WorldData.Place
    'LOCATE 2, 1: PRINT "CurMidi:"; CurMidi; "PlaceMidi:"; PlaceMidi; "Fight:"; RndNum1; "-"; RndNum2
    
    If kbd$ <> "" Then
        ukbd$ = UCase$(kbd$)
        If kbd$ = KeyInteract$ Or ukbd$ = KeyInteract$ Then
            WhatsUp NpcFile$
        ElseIf kbd$ = CHR$(27) Or kbd$ = KeyMenu$ Or ukbd$ = KeyMenu$ Then
            Menu1
        ElseIf kbd$ = KeyInv$ Or ukbd$ = KeyInv$ Then
            MenuItems
        ElseIf ukbd$ = "H" Or kbd$ = "?" Then
            NpcTalk("help.npc")
        ElseIf ukbd$ = "M" Then
            nomidi = nomidi xor 1
            if nomidi = 1 then
                PlayTrack(-1)
            else
                PlayTrack(CurMidi)
            end if
        ElseIf kbd$ = "Q" Then
            quit
        End If
    End If
    
    if SX = 0 and SY = 0 then
        move = 0
        if Multikey(&h48) then
            MoveUp
            WorldData.Action = true
            CheckFig
            Player.Dir = 2

        elseif Multikey(&h50) then
            
            MoveDown
            WorldData.Action = true
            CheckFig
            Player.Dir = 0
            
        elseif Multikey(&h4B) then
            
            MoveLeft
            WorldData.Action = true
            CheckFig
            Player.Dir = 3

        elseif Multikey(&h4d) then
            
            MoveRight
            WorldData.Action = true
            CheckFig
            Player.Dir = 1

        end if
    End If
    
    ShowMap
    
    if SX > 0 then SX = SX - 2
    if SX < 0 then SX = SX + 2
    if SY > 0 then SY = SY - 2
    if SY < 0 then SY = SY + 2
    
    if sx <> 0 or sy <> 0 or move = 1 then
        if Player.Nextframe > 0 then 
            Player.Nextframe -= 1
        else
            Player.Frame += 1
            if Player.Frame > 3 then Player.Frame = 0
            Player.Nextframe = 5
        end if
    else
        Player.Frame = 0
        Player.Nextframe = 0
    end if
    
Loop

'-------------------------------------------
Sub Begin
    dim as integer x
    dim z$
    NewMidi = -1
    'Screen 13
    'SetupPalette
    Cls
    
    
    Walikko:
    Cls
    box(65, 70, 240, 160)
    TEXT "Araxia", 2, 75, 26, 3
    TEXT "Araxia Games", 2, 100, 175, 1
    TEXT "Shadow of Etheros", 2, 85, 50, 1
    TEXT "Manmadedrummer is proud to present", 2, 38, 5, 1
    X = 1
    Do
        
        TEXT "New Game",  IIf(X = 1, 239, 170), 110, 80, 1
        TEXT "Load Game", IIf(X = 2, 239, 170), 110, 95, 1
        TEXT "Options",   IIf(X = 3, 239, 170), 110, 110, 1
        TEXT "Help/Info", IIf(X = 4, 239, 170), 110, 125, 1
        TEXT "Quit",      IIf(X = 5, 239, 170), 110, 140, 1
        Do
            z$ = INKEY$
            LoopMidi
        Loop Until z$ <> ""
        If z$ = CHR$(255) + CHR$(80) Then X = X + 1: If X > 5 Then X = 1
        If z$ = CHR$(255) + CHR$(72) Then X = X - 1: If X < 1 Then X = 5
    Loop Until z$ = CHR$(13)
    
    If X = 1 Then
        chrname = "Elaxian"
        
        Story
        InitVars                                    ' defaults first
        LoadMap("StartingZoneIN.MAP", 40, 0, 41)    ' start inside on floor (editor 48,4 = grid 49,5)
        WorldData.Inside = 1
        ShowMap
        Exit Sub
    elseIf X = 2 Then
        LoadGame
        ShowMap
        Exit Sub
    elseIf X = 3 Then
        MenuOptions
        Goto Walikko
    elseIf X = 4 Then
        Info
        Goto Walikko
    elseIf X = 5 Then
        
        Cls : Print ""
        TheEnd
    End If
    
End Sub

'-------------------------------------------
Sub box (X, y, x2, y2)
    Line (X, y)-(x2, y2), 200, B
    Line (X + 1, y + 1)-(x2 - 1, y2 - 1), 140, B
    Line (X + 2, y + 2)-(x2 - 2, y2 - 2), 200, B
    Line (X + 3, y + 3)-(x2 - 3, y2 - 3), 0, B
    Line (X + 4, y + 4)-(x2 - 4, y2 - 4), 0, BF
    
End Sub

'-------------------------------------------
Sub ChangeAnim
    
    If WorldData.AnimCycle = 1 Then 
        WorldData.AnimCycle = 2 
    ElseIf WorldData.AnimCycle = 2 Then 
        WorldData.AnimCycle = 1
    end if
    
End Sub

Sub CheckFig
    Dim lmap$
    Dim As Integer Place
    
    CheckDoor
    If WorldData.Terreng = 0 And WorldData.Inside = 0 Then
        Select Case WorldData.Place
        Case 1
            If WorldData.Direc = West  Then lmap$ = "Turnstead.MAP": Place = 2
        Case 2
            If WorldData.Direc = East  Then lmap$ = "Lighthouse.MAP": Place = 1
            If WorldData.Direc = West  Then lmap$ = "Caves.MAP": Place = 3
            If WorldData.Direc = South Then lmap$ = "ThunderBayCentral.MAP": Place = 5
        Case 3
            If WorldData.Direc = East  Then lmap$ = "Turnstead.MAP": Place = 2
        Case 4
            If WorldData.Direc = West  Then lmap$ = "ThunderBayCentral.MAP": Place = 5
            If WorldData.Direc = South Then lmap$ = "ThunderBaySouthDocks.MAP": Place = 7
        Case 5
            If WorldData.Direc = North Then lmap$ = "Turnstead.MAP": Place = 2
            If WorldData.Direc = West  Then lmap$ = "ThunderBayNorthWest.MAP": Place = 6
            If WorldData.Direc = South Then lmap$ = "ThunderBayIsland.MAP": Place = 8
            If WorldData.Direc = East  Then lmap$ = "StartingZone.MAP": Place = 4
        Case 6
            If WorldData.Direc = East  Then lmap$ = "ThunderBayCentral.MAP": Place = 5
            If WorldData.Direc = South Then lmap$ = "ThunderBayWest.MAP": Place = 9
        Case 7
            If WorldData.Direc = North Then lmap$ = "StartingZone.MAP": Place = 4
            If WorldData.Direc = West  Then lmap$ = "ThunderBayIsland.MAP": Place = 8
        Case 8
            If WorldData.Direc = North Then lmap$ = "ThunderBayCentral.MAP": Place = 5
            If WorldData.Direc = East  Then lmap$ = "ThunderBaySouthDocks.MAP": Place = 7
            If WorldData.Direc = West  Then lmap$ = "ThunderBayWest.MAP": Place = 9
        Case 9
            If WorldData.Direc = North Then lmap$ = "ThunderBayNorthWest.MAP": Place = 6
            If WorldData.Direc = West  Then lmap$ = "EversmokeWoods1.MAP": Place = 10
            If WorldData.Direc = East  Then lmap$ = "ThunderBayIsland.MAP": Place = 8
        Case 10
            If WorldData.Direc = West  Then lmap$ = "EversmokeWoods2.MAP": Place = 11
            If WorldData.Direc = East  Then lmap$ = "ThunderBayWest.MAP": Place = 9
        Case 11
            If WorldData.Direc = North Then lmap$ = "YsirasRest.MAP": Place = 15
            If WorldData.Direc = South Then lmap$ = "ThrolluxTemple.MAP": Place = 14
            If WorldData.Direc = East  Then lmap$ = "EversmokeWoods1.MAP": Place = 10
            If WorldData.Direc = West  Then lmap$ = "Balthix.MAP": Place = 12
        Case 12
            If WorldData.Direc = East  Then lmap$ = "EversmokeWoods2.MAP": Place = 11
            If WorldData.Direc = West  Then lmap$ = "BalthixCemetary.MAP": Place = 13
        Case 13
            If WorldData.Direc = East  Then lmap$ = "Balthix.MAP": Place = 12
        Case 14
            If WorldData.Direc = South Then lmap$ = "EversmokeWoods2.MAP": Place = 11
        Case 15
            If WorldData.Direc = North Then lmap$ = "Yellowseed.MAP": Place = 16
            If WorldData.Direc = South Then lmap$ = "EversmokeWoods2.MAP": Place = 11
        Case 16
            If WorldData.Direc = North Then lmap$ = "Gate.MAP": Place = 19
            If WorldData.Direc = South Then lmap$ = "YsirasRest.MAP": Place = 15
        Case 19
            If WorldData.Direc = South Then lmap$ = "Yellowseed.MAP": Place = 16
            If WorldData.Direc = North Then lmap$ = "EtherosLair.MAP": Place = 20
        Case 20
            If WorldData.Direc = South Then lmap$ = "Gate.MAP": Place = 19
        End Select

        If lmap$ <> "" Then
            If WorldData.Place = 19 And WorldData.Direc = South Then
                ' Gate -> Yellowseed: always land on editor cell (23,1) facing south.
                ' player cell = (TopCol+8, TopRow+5); editor (23,1) = grid (24,2)
                ' -> TopCol=16, TopRow=-3. FixLanding skipped so the cell is exact.
                LoadMap(lmap$, Place, -3, 16)
                WorldData.Direc = South
            ElseIf WorldData.Place = 11 And WorldData.Direc = South Then
                ' Eversmoke Woods 2 -> Throllux Temple: land on editor (25,28) facing north
                ' editor (25,28) = grid (26,29) -> TopCol=18, TopRow=24. FixLanding skipped.
                LoadMap(lmap$, Place, 24, 18)
                WorldData.Direc = North
            ElseIf WorldData.Place = 14 And WorldData.Direc = South Then
                ' Throllux Temple (exit south) -> Eversmoke Woods 2: land editor (24,28) facing north
                LoadMap(lmap$, Place, 24, 17)
                WorldData.Direc = North
            Else
                If WorldData.Direc = West  Then LoadMap(lmap$, Place, WorldData.TopRow, 42)
                If WorldData.Direc = East  Then LoadMap(lmap$, Place, WorldData.TopRow, -7)
                If WorldData.Direc = North Then LoadMap(lmap$, Place, 25, WorldData.TopCol)
                If WorldData.Direc = South Then LoadMap(lmap$, Place, -4, WorldData.TopCol)
                FixLanding
            End If
        End If
    End If
    
    'CheckMusic
    
    ' FFX-style step gauge: only actual walks count, and only on encounter tiles.
    ' Old 8%-per-step was ~1 fight / 12 steps. This is a threat counter with
    ' a long rest after each fight (and a small chance of a short chain).
    Select Case WorldData.Place
    Case 10                               ' EversmokeWoods1 - cultist bandits, Lvl 1-5
        If WorldData.Terreng = 2 Then RollEncounter(1, 4)
    Case 1                                 ' Lighthouse - coastal eelfolk
        If WorldData.Terreng = 2 Then RollEncounter(5, 8)
    Case 11                               ' EversmokeWoods2 - deep-woods predators, Lvl 6-14
        If WorldData.Terreng = 2 Then RollEncounter(9, 12)
    Case 3                                 ' Caves - Lvl 6-14
        If WorldData.Terreng = 43 Then RollEncounter(19, 24)
    Case 13                               ' BalthixCemetary - skeletons and ghouls (31-34)
        If WorldData.Terreng = 1 Or WorldData.Terreng = 2 Or WorldData.Terreng = 5 Or WorldData.Terreng = 43 Then RollEncounter(31, 34)
    Case 14                               ' ThrolluxTemple - temple guardians, Lvl 15-20
        If WorldData.Terreng = 6 Or WorldData.Terreng = 43 Then RollEncounter(13, 17)
    Case 19                               ' Gate - final gauntlet, Lvl 15-20
        If WorldData.Terreng = 6 Then RollEncounter(25, 29)
    ' Balthix (12), YsirasRest (15), Yellowseed (16), StartingZone/ThunderBay,
    ' and the unreachable placeholder places intentionally have NO battle case = safe
    End Select
    
End Sub

'-------------------------------------------
' FFX-like random encounters: a step counter fills toward a per-area threshold.
' Walking into a new map grants a grace window. After a fight you get a longer
' rest, with a small chance of a short follow-up (a "pack") then a long gap.
Sub RollEncounter (lo As Integer, hi As Integer)
    If move <> 1 Then Exit Sub
    If EncLastPlace <> WorldData.Place Then
        EncLastPlace = WorldData.Place
        EncSteps = 0
        EncGrace = 14 + Int(Rnd * 9)          ' 14-22 free steps on map entry
        EncNeed = 0
    End If
    If EncNeed <= 0 Then
        Select Case WorldData.Place
        Case 10, 1                            ' lighter: woods1, lighthouse
            EncNeed = 32 + Int(Rnd * 21)      ' 32-52 steps
        Case 11, 3, 13                        ' medium: woods2, caves, cemetery
            EncNeed = 24 + Int(Rnd * 17)      ' 24-40 steps
        Case 14, 19                           ' heavier: temple, gate
            EncNeed = 20 + Int(Rnd * 13)      ' 20-32 steps
        Case Else
            EncNeed = 28 + Int(Rnd * 17)
        End Select
    End If
    If EncGrace > 0 Then
        EncGrace = EncGrace - 1
        Exit Sub
    End If
    EncSteps = EncSteps + 1
    If EncSteps < EncNeed Then Exit Sub
    EncSteps = 0
    If Int(Rnd * 100) < 16 Then               ' ~1 in 6: short chain, then a long rest
        EncGrace = 4
        EncNeed = 8 + Int(Rnd * 8)
    Else
        EncGrace = 14 + Int(Rnd * 13)         ' 14-26 free steps after a fight
        EncNeed = 0
    End If
    EnemyLo = lo: EnemyHi = hi
    LoadEnemies
    Fight
End Sub

'-------------------------------------------
' Position-aware door warps (interior <-> exterior).
' Keys on the current map + the cell the player is facing (NPCcol/NPCrow,
' set by every Move sub, even when the faced tile is solid). To land the
' player on cell (C,R): LoadMap map$, place, R-5, C-8.
' Generic door warps. Scans the current map's Warps() table (loaded from the
' map file's #WARPS section) for the cell the player is standing on and, if
' found, jumps to the destination map/cell. No per-building code here.
Sub CheckDoor
    dim as integer pc, pr, k
    dim dm$
    dim as integer dpl, dins, dc, dr

    pc = WorldData.TopCol + 8      ' player's current cell (1-based grid)
    pr = WorldData.TopRow + 5

    For k = 1 To WarpN
        If Warps(k).srcCol = pc And Warps(k).srcRow = pr Then
            dm$  = Warps(k).destMap
            dpl  = Warps(k).destPlace
            dins = Warps(k).destInside
            dc   = Warps(k).destCol
            dr   = Warps(k).destRow
            LoadMap dm$, dpl, dr - 5, dc - 8      ' land player cell on (dc,dr)
            WorldData.Inside = dins
            Exit Sub
        End If
    Next
End Sub


'-------------------------------------------
Sub Death
    'StopMIDI
    'UnloadMIDI MIDIHandle%
    PlayTrack(-1)
    NewMidi = -1
    Cls
    TEXT "You Have Perished...", 4, 20, 50, 2
    TEXT "Press any key to Continue.", 4, 20, 80, 1
    waitkey
End Sub

'-------------------------------------------
Sub delay (Seconds as integer)
    dim as single CurrentTimer
    CurrentTimer = Timer
    
    While Timer < (CurrentTimer + Seconds)
        Sleep 1, 1
    Wend
    
End Sub

'-------------------------------------------
Sub Fight
    dim as integer a, ea, poi, Givem, dropRoll, uy
    dim txt as string
    dim u1$, u2$, u3$, drop$
    
    SX = 0
    SY = 0
    Player.Frame = 0
    Player.NextFrame = 0
    
    NewMidi = 0 'Change to battle music
    
    Fight01:
    If Hp <= 0 Then Hp = 0: Exit Sub
    box(1, 1, 318, 192)
    TEXT " A Fight Approaches...", 4, 10, 10, 1
    TEXT "Your Status:", 14, 15, 25, 1
    TEXT "Hit Points:" + Fixed$(Hp) + "/" + Fixed$(MaxHp), 15, 15, 35, 1
    TEXT "Gold:" + Fixed$(gold%), 15, 15, 45, 1
    TEXT "Weapon:" + (Wep$) + " + " + Fixed$(WepB), 15, 15, 55, 1
    TEXT "Armor:" + (Arm$) + " + " + Fixed$(ArmB), 15, 15, 65, 1
    TEXT "Total Attack Skill:" + Fixed$(WepB + ItemWepB + (Level - 1)), 15, 15, 75, 1
    TEXT "Total Defense Skill:" + Fixed$(ArmB + ItemArmB + (Level - 1)), 15, 15, 85, 1
    TEXT "A) Fight", 14, 15, 95, 1
    TEXT "B) Run", 14, 15, 105, 1
    TEXT "C) Use", 14, 15, 115, 1
    If Enemy1Hp <= 0 And Enemy2Hp <= 0 And Enemy3Hp <= 0 Then Goto EnemyDeath:
    TEXT "Enemy Rapport:", 4, 165, 25, 1
    If Enemy1Hp >= 1 Then TEXT "1: " + Left$(Enemy1Name$, 14) + " /" + Fixed$(Enemy1Hp), 4, 165, 35, 1
    If Enemy2Hp >= 1 Then TEXT "2: " + Left$(Enemy2Name$, 14) + " /" + Fixed$(Enemy2Hp), 4, 165, 45, 1
    If Enemy3Hp >= 1 Then TEXT "3: " + Left$(Enemy3Name$, 14) + " /" + Fixed$(Enemy3Hp), 4, 165, 55, 1
    
    Do
        txt = INKEY$
        If txt = "a" Or txt = "A" Then Goto Fight02
        If txt = "b" Or txt = "B" Then Goto Fight04
        If txt = "c" Or txt = "C" Then MenuItems: Goto Fight01
        LoopMidi
    Loop
    
    Fight02:
    TEXT "Attack which enemy ?", 14, 165, 75, 1
    Do
        txt = INKEY$
        If txt = "1" And Enemy1Hp >= 1 Then Goto fight03:
        If HowMany >= 2 And Enemy2Hp >= 1 And txt = "2" Then Goto fight03:
        If HowMany >= 3 And Enemy3Hp >= 1 And txt = "3" Then Goto fight03:
        LoopMidi
    Loop While txt = ""
    Goto Fight02:
    
    fight03:
    a = Int(Rnd * 10 + Rnd * WepB + ItemWepB + (Level - 1))
    
    If txt = "1" Then
        ea = Int(Rnd * Enemy1Defense)
        a = a - ea
        If a < 0 Then a = 0
        TEXT "You hit " + Enemy1Name$ + "," + Fixed$(a) + " dmg.", 15, 15, 125, 1
        Enemy1Hp = Enemy1Hp - a
    End If
    If txt = "2" Then
        ea = Int(Rnd * Enemy2Defense)
        a = a - ea
        If a < 0 Then a = 0
        TEXT "You hit " + Enemy2Name$ + "," + Fixed$(a) + " dmg.", 15, 15, 125, 1
        Enemy2Hp = Enemy2Hp - a
    End If
    If txt = "3" Then
        ea = Int(Rnd * Enemy3Defense)
        a = a - ea
        If a < 0 Then a = 0
        TEXT "You hit " + Enemy3Name$ + "," + Fixed$(a) + " dmg.", 15, 15, 125, 1
        Enemy3Hp = Enemy3Hp - a
    End If
    
    Select Case HowMany
    Case 1
        If Enemy1Hp >= 1 Then
            ea = Int(Rnd * Enemy1Attack)
            a = Int(Rnd * ArmB + ItemArmB + (Level - 1))
            ea = ea - a
            If ea < 0 Then ea = 0
            TEXT Enemy1Name$ + " hit's you," + Fixed$(ea) + " dmg.", 15, 15, 135, 1
            Hp = Hp - ea
        End If
    Case 2
        If Enemy1Hp >= 1 Then
            ea = Int(Rnd * Enemy1Attack)
            a = Int(Rnd * ArmB + ItemArmB + (Level - 1))
            ea = ea - a
            If ea < 0 Then ea = 0
            TEXT Enemy1Name$ + " hit's you," + Fixed$(ea) + " dmg.", 15, 15, 135, 1
            Hp = Hp - ea
        End If
        If Enemy2Hp >= 1 Then
            ea = Int(Rnd * Enemy2Attack)
            a = Int(Rnd * ArmB + ItemArmB + (Level - 1))
            ea = ea - a
            If ea < 0 Then ea = 0
            TEXT Enemy2Name$ + " hit's you," + Fixed$(ea) + " dmg.", 15, 15, 145, 1
            Hp = Hp - ea
        End If
    Case 3
        If Enemy1Hp >= 1 Then
            ea = Int(Rnd * Enemy1Attack)
            a = Int(Rnd * ArmB + ItemArmB + (Level - 1))
            ea = ea - a
            If ea < 0 Then ea = 0
            TEXT Enemy1Name$ + " hit's you," + Fixed$(ea) + " dmg.", 15, 15, 135, 1
            Hp = Hp - ea
        End If
        
        If Enemy2Hp >= 1 Then
            ea = Int(Rnd * Enemy2Attack)
            a = Int(Rnd * ArmB + ItemArmB + (Level - 1))
            ea = ea - a
            If ea < 0 Then ea = 0
            TEXT Enemy2Name$ + " hit's you," + Fixed$(ea) + " dmg.", 15, 15, 145, 1
            Hp = Hp - ea
        End If
        
        If Enemy3Hp >= 1 Then
            ea = Int(Rnd * Enemy3Attack)
            a = Int(Rnd * ArmB + ItemArmB + (Level - 1))
            ea = ea - a
            If ea < 0 Then ea = 0
            TEXT Enemy3Name$ + " hit's you," + Fixed$(ea) + " dmg.", 15, 15, 155, 1
            Hp = Hp - ea
        End If
        
    End Select
    
    If Poisoned = 0 Then
        If (Enemy1Poison = 1 And Enemy1Hp >= 1) Or (Enemy2Poison = 1 And Enemy2Hp >= 1) Or (Enemy3Poison = 1 And Enemy3Hp >= 1) Then
            poi = Int(Rnd * 40) + 1
            If poi <= 5 Then
                Poisoned = 1
                TEXT "You got Poisoned !", 12, 15, 165, 1
                waitkey
                Goto Fight01:
            End If
        End If
    End If
    
    If Poisoned = 1 Then
        poi = Int(Rnd * 10) + 1
        TEXT "Poison hurts you for " + Fixed$(poi) + " dmg.", 12, 15, 165, 1
        Hp = Hp - poi
    End If
    
    Do: txt = INKEY$: LoopMidi:Loop While txt = ""
    Goto Fight01:
    
    Fight04:
    If Runa = 1 Then
        Runa = 0
        TEXT "You run away!", 14, 95, 140, 1
        waitkey
        Cls
        CurMidi = 0
        
        ShowMap
        Exit Sub
    End If
    TEXT "You failed runing away!", 14, 95, 140, 1
    waitkey
    Goto Fight01
    
    EnemyDeath:
    If HowMany = 1 Then Givem = (Rnd * Enemy1Gold) + 1
    If HowMany = 2 Then Givem = (Rnd * Enemy1Gold) + 1 + (Rnd * Enemy2Gold) + 1
    If HowMany = 3 Then Givem = (Rnd * Enemy1Gold) + 1 + (Rnd * Enemy2Gold) + 1 + (Rnd * Enemy3Gold) + 1
    kills = kills + HowMany
    u1$ = "": u2$ = "": u3$ = "": drop$ = ""
    If HowMany >= 1 And Enemy1Nr >= 1 And Enemy1Nr <= 60 Then
        Bestiary(Enemy1Nr) = Bestiary(Enemy1Nr) + 1
        If Bestiary(Enemy1Nr) = 5 Then u1$ = Enemy1Name$
    End If
    If HowMany >= 2 And Enemy2Nr >= 1 And Enemy2Nr <= 60 Then
        Bestiary(Enemy2Nr) = Bestiary(Enemy2Nr) + 1
        If Bestiary(Enemy2Nr) = 5 Then u2$ = Enemy2Name$
    End If
    If HowMany >= 3 And Enemy3Nr >= 1 And Enemy3Nr <= 60 Then
        Bestiary(Enemy3Nr) = Bestiary(Enemy3Nr) + 1
        If Bestiary(Enemy3Nr) = 5 Then u3$ = Enemy3Name$
    End If
    PlayerExp = PlayerExp + (HowMany * 15)
    TEXT "You slained your enemies!", 2, 95, 140, 1
    TEXT "You get " + Fixed$(Givem) + " Gold coins.", 14, 95, 150, 1
    gold% = gold% + Givem
    Trophies = Trophies + HowMany
    TEXT "You collect " + Fixed$(HowMany) + " Trophies.", 14, 95, 160, 1
    ' Occasional consumable (no more junk dagger/armor drops)
    If Int(Rnd * 100) < 5 Then
        dropRoll = Int(Rnd * 100)
        If dropRoll < 45 Then
            SPot = SPot + 1: drop$ = "You found a Small Heal!"
        ElseIf dropRoll < 70 Then
            PHerb = PHerb + 1: drop$ = "You found an Antidote!"
        ElseIf dropRoll < 88 Then
            AHerb = AHerb + 1: drop$ = "You found an Agility Potion!"
        Else
            Fpot = Fpot + 1: drop$ = "You found a Large Heal!"
        End If
        TEXT drop$, 14, 95, 170, 1
    End If
    waitkey
    If u1$ <> "" Or u2$ <> "" Or u3$ <> "" Then
        box(1, 1, 318, 192)
        TEXT "BESTIARY", 11, 130, 70, 1
        uy = 95
        If u1$ <> "" Then TEXT u1$ + " has been added to Bestiary", 11, 20, uy, 1: uy = uy + 14
        If u2$ <> "" And u2$ <> u1$ Then TEXT u2$ + " has been added to Bestiary", 11, 20, uy, 1: uy = uy + 14
        If u3$ <> "" And u3$ <> u1$ And u3$ <> u2$ Then TEXT u3$ + " has been added to Bestiary", 11, 20, uy, 1
        waitkey
    End If
    
    CheckLevelUp
    
    Cls
    ShowMap
End Sub

'-------------------------------------------
Function Fixed$ (Num)
    Fixed$ = LTRIM$(RTRIM$(STR$(Num)))
End Function

'-------------------------------------------
Sub GotAItem
    ' Bonuses match the relic descriptions in item1-5.npc
    If Q1 = 0 And O1 = 1 Then NpcTalk("item1.npc"): ItemArmB = ItemArmB + 4   ' Sun-Winged Aegis: Def +4
    If Q2 = 0 And O2 = 1 Then NpcTalk("item2.npc"): ItemWepB = ItemWepB + 3   ' Aquamarine of Ran: Atk +3
    If Q3 = 0 And O3 = 1 Then NpcTalk("item3.npc"): ItemArmB = ItemArmB + 3   ' Root-Bound Ring: Def +3
    If Q4 = 0 And O4 = 1 Then NpcTalk("item4.npc"): ItemArmB = ItemArmB + 2   ' Eye of Foresight: Def +2
    If Q5 = 0 And O5 = 1 Then NpcTalk("item5.npc"): ItemWepB = ItemWepB + 5   ' Orm's Seventh Eye: Atk +5
End Sub

'-------------------------------------------
Sub Info
    dim as integer x, y
    dim a$
    
    Cls
    
    For X = 0 To 319 Step 20
        For y = 0 To 199 Step 20
            
            Put (X, y), wall1, Pset
            
        Next
    Next
    
    TEXT "Araxia", 15, 32, 2, 2
    TEXT "Shadow of Etheros", 15, 140, 10, 1
    TEXT "Do you want to read Help/Info.  Y/N", 14, 20, 50, 1
    Do: a$ = INKEY$: LoopMidi: Loop Until a$ = "y" Or a$ = "Y" Or a$ = "n" Or a$ = "N"
    If a$ = "y" Or a$ = "Y" Then NpcTalk("help.npc")
    
    Cls
    
    For X = 0 To 319 Step 20
        For y = 0 To 199 Step 20
            
            Put (X, y), wall1, Pset
            
        Next
    Next
    
TEXT "Araxia", 15, 32, 2, 2
    TEXT "Shadow of Etheros", 15, 140, 10, 1
    TEXT "Story/Scripts/Maps/NPCs:", 110, 1, 25, 1
    TEXT "Eric 'Manmadedrummer' Gates", 189, 1, 36, 1
    TEXT "Graphics:", 110, 1, 55, 1
    TEXT "Daniel Wilfong & Jocke The Beast,", 189, 1, 66, 1
    TEXT "some custom art by Eric Gates", 189, 1, 77, 1
    TEXT "Music:", 110, 1, 96, 1
    TEXT "Royalty-free MIDI, various sources", 189, 1, 107, 1
    TEXT "some music tracks by Eric Gates", 189, 1, 118, 1
    TEXT "Araxia Games (Freeware)", 10, 1, 174, 1
    TEXT "Web: https://github.com/Manmadedrummer", 11, 1, 184, 1
    waitkey
    Cls
End Sub
'-------------------------------------------
Sub InitVars
    
    WorldData.Direc = West
    WorldData.AnimCycle = 1
    WorldData.PlayerY = 97
    WorldData.Place = 4
    WorldData.Inside = 1
    WorldData.Terreng = 3
    Hp = 90
    MaxHp = 100
    gold% = 450
    
    Runa = 0
    ItemWepB = 0
    ItemArmB = 0
    Poisoned = 0
    Wep$ = "Dagger"
    WepB = 1
    Arm$ = "Cloth"
    ArmB = 1
    OwnWep2 = 0: OwnWep3 = 0: OwnWep4 = 0: OwnWep6 = 0
    OwnArm2 = 0: OwnArm3 = 0: OwnArm4 = 0: OwnArm6 = 0
    AHerb = 1
    PHerb = 1
    Fpot = 1
    SPot = 1
    kills = 0
    Level = 1
    PlayerExp = 0
    BrokenDagger = 0: BustedArmor = 0: Trophies = 0: Fish = 0: RareFish = 0
    EncSteps = 0: EncNeed = 0: EncGrace = 16: EncLastPlace = -1
    Dim BiInit As Integer
    For BiInit = 1 To 60: Bestiary(BiInit) = 0: Next
    Dim As Integer fzInit, fxInit, fyInit
    For fzInit = 1 To 4
        For fyInit = -9 To 67
            For fxInit = -9 To 67
                Fog(fzInit, fxInit, fyInit) = 0
            Next
        Next
    Next
    O1 = 0: O2 = 0: O3 = 0: O4 = 0: O5 = 0: Q1 = 0: Q2 = 0: Q3 = 0: Q4 = 0: Q5 = 0
    DeathQ = 0
    
    
    NpcFile$ = " "
    '            NewMidi = 1
    '            CurMidi = -1
    SX = 0
    SY = 0
    Player.Frame = 0
    Player.NextFrame = 0
    
End Sub

'-------------------------------------------
Sub killer
    If kills = 0 Then NpcTalk("killer01.npc"): Exit Sub
    NpcTalk("killer02.npc")
    gold% = gold% + kills * 10
    kills = 0
End Sub

'-------------------------------------------
Sub LoadEnemies
    dim as integer i
    If EnemyHi < EnemyLo Or EnemyHi = 0 Then EnemyLo = 1: EnemyHi = 17
    
    HowMany = 0: Enemy1Name$ = "": Enemy1Hp = 0: Enemy1Attack = 0: Enemy1Defense = 0: Enemy1Poison = 0: Enemy1Gold = 0
    Enemy2Name$ = "": Enemy2Hp = 0: Enemy2Attack = 0: Enemy2Defense = 0: Enemy2Poison = 0: Enemy2Gold = 0
    Enemy3Name$ = "": Enemy3Hp = 0: Enemy3Attack = 0: Enemy3Defense = 0: Enemy3Poison = 0: Enemy3Gold = 0
    
    
    HowMany = Int(Rnd * 3) + 1
    ' safety: bosses (18=Bhaulx, 30=Etheros) never appear as random encounters
    If EnemyLo <= 18 And EnemyHi >= 18 Then EnemyHi = 17
    If EnemyLo <= 30 And EnemyHi >= 30 Then EnemyHi = 29
    
    Select Case HowMany
    Case 1
        Enemy1Nr = Int(Rnd * (EnemyHi - EnemyLo + 1)) + EnemyLo
    Case 2
        Enemy1Nr = Int(Rnd * (EnemyHi - EnemyLo + 1)) + EnemyLo
        Enemy2Nr = Int(Rnd * (EnemyHi - EnemyLo + 1)) + EnemyLo
    Case 3
        Enemy1Nr = Int(Rnd * (EnemyHi - EnemyLo + 1)) + EnemyLo
        Enemy2Nr = Int(Rnd * (EnemyHi - EnemyLo + 1)) + EnemyLo
        Enemy3Nr = Int(Rnd * (EnemyHi - EnemyLo + 1)) + EnemyLo
    End Select
    
    Select Case HowMany
    Case 1
        Open "enemy.dat" For Input As #1
        For i = 1 To Enemy1Nr
            Input #1, Enemy1Name$, Enemy1Hp, Enemy1Attack, Enemy1Defense, Enemy1Poison, Enemy1Gold
        Next i
        Close #1
    Case 2
        Open "enemy.dat" For Input As #1
        For i = 1 To Enemy1Nr
            Input #1, Enemy1Name$, Enemy1Hp, Enemy1Attack, Enemy1Defense, Enemy1Poison, Enemy1Gold
        Next i
        Close #1
        
        Open "enemy.dat" For Input As #1
        For i = 1 To Enemy2Nr
            Input #1, Enemy2Name$, Enemy2Hp, Enemy2Attack, Enemy2Defense, Enemy2Poison, Enemy2Gold
        Next i
        Close #1
        
    Case 3
        Open "enemy.dat" For Input As #1
        For i = 1 To Enemy1Nr
            Input #1, Enemy1Name$, Enemy1Hp, Enemy1Attack, Enemy1Defense, Enemy1Poison, Enemy1Gold
        Next i
        Close #1
        
        Open "enemy.dat" For Input As #1
        For i = 1 To Enemy2Nr
            Input #1, Enemy2Name$, Enemy2Hp, Enemy2Attack, Enemy2Defense, Enemy2Poison, Enemy2Gold
        Next i
        Close #1
        
        Open "enemy.dat" For Input As #1
        For i = 1 To Enemy3Nr
            Input #1, Enemy3Name$, Enemy3Hp, Enemy3Attack, Enemy3Defense, Enemy3Poison, Enemy3Gold
        Next i
        Close #1
    End Select
    
End Sub

'-------------------------------------------
Sub Loadfont
    dim as integer a, x, y, b
    Open "font.dat" For Input As #1
    For a = 1 To 126
        For X = 1 To 8
            For y = 1 To 6
                Input #1, B
                CharSet(a, X, y) = B        'loads font data into 3-D array.
            Next y
        Next X
    Next a
    Close #1
    
End Sub

'-------------------------------------------
Sub LoadGame
    dim as integer Wdtc, Wdtr
    Open "save.dat" For Input As #1
    Input #1, chrname, WorldData.Place, Wdtc, Wdtr, Hp, MaxHp, gold%, Fpot, SPot, PHerb, AHerb, Poisoned, Runa, Wep$, WepB, Arm$, ArmB, ItemWepB, ItemArmB, O1, O2, O3, O4, O5, Q1, Q2, Q3, Q4, Q5, kills, Level, PlayerExp, Trophies, Fish, RareFish, DeathQ, OwnWep2, OwnWep3, OwnWep4, OwnWep6, OwnArm2, OwnArm3, OwnArm4, OwnArm6
    Close #1
    Dim bi As Integer
    For bi = 1 To 60: Bestiary(bi) = 0: Next
    If Dir("beast.dat") <> "" Then
        Open "beast.dat" For Input As #2
        For bi = 1 To 60
            If Not EOF(2) Then Input #2, Bestiary(bi)
        Next
        Close #2
    End If
    Dim As Integer fgZ, fgX, fgY, fgCh
    Dim fgS As String
    For fgZ = 1 To 4
        For fgY = -9 To 67
            For fgX = -9 To 67
                Fog(fgZ, fgX, fgY) = 0
            Next
        Next
    Next
    If Dir("fog.dat") <> "" Then
        Open "fog.dat" For Input As #3
        For fgZ = 1 To 4
            If Not EOF(3) Then
                Input #3, fgS
                fgCh = 1
                For fgY = -9 To 67
                    For fgX = -9 To 67
                        If fgCh <= Len(fgS) Then
                            Fog(fgZ, fgX, fgY) = Val(Mid$(fgS, fgCh, 1))
                            fgCh = fgCh + 1
                        End If
                    Next
                Next
            End If
        Next
        Close #3
    End If
    
    WorldData.TopCol = Wdtc
    WorldData.TopRow = Wdtr
    WorldData.Direc = West
    WorldData.AnimCycle = 1
    WorldData.PlayerY = 97
    WorldData.Inside = 0
    WorldData.Terreng = -9
    CurMidi = 0
    CheckFig
    WorldData.TopRow = WorldData.TopRow + 2
    
    SX = 0
    SY = 0
    Player.Frame = 0
    Player.NextFrame = 0
End Sub

'-------------------------------------------
' Reads BOTH the old plain format (one integer per tile) and the new
' RLE + #WARPS format. RLE token is "V:N" (N copies of V); a bare "V" is
' one tile. Tiles stream row-major regardless of line breaks. After the
' tiles, an optional "#WARPS" section lists this map's outbound warps as:
'   srcCol,srcRow,destMap,destPlace,destInside,destCol,destRow
' Warp coordinates are in EDITOR (0-based) numbers; +1 makes them 1-based grid.
Sub LoadMap (map$, p, wx, wy)
    dim as integer i, j, f, total, filled, cnt, v, q, atWarps
    dim ln$, tok$, ws$

    ' Clear the whole tile array first, so tiles from a previously loaded
    ' (larger) map don't linger past the edges of a smaller one - stale
    ' tiles there would block edge-warps and show as ghost tiles.
    For i = -9 To 67
        For j = -9 To 67
            map(i, j).Tile = 0
            map(i, j).Walkon = false
        Next j
    Next i

    BarrelN = 0
    LoadNpcMap map$

    WorldData.Place = p
    CurMap = LCase(map$)
    WarpN = 0
    If EncLastPlace <> p Then
        EncLastPlace = p
        EncSteps = 0
        EncGrace = 14 + Int(Rnd * 9)
        EncNeed = 0
    End If

    f = FreeFile
    Open map$ For Input As #f

    ' --- header: Rows,Cols ---
    Line Input #f, ln$
    ln$ = Trim(ln$)
    q = Instr(ln$, ",")
    WorldData.Rows = Val(Left(ln$, q - 1))
    WorldData.Cols = Val(Mid(ln$, q + 1))

    total = WorldData.Rows * WorldData.Cols
    filled = 0 : i = 1 : j = 1 : atWarps = 0

    ' --- tile section (RLE "V:N" or plain "V") ---
    Do While filled < total And Not EOF(f)
        Line Input #f, ln$
        ln$ = Trim(ln$)
        If ln$ = "#WARPS" Then atWarps = 1 : Exit Do
        If ln$ <> "" And Left(ln$, 1) <> "#" And Left(ln$, 1) <> "'" Then
            Do While Len(ln$) > 0 And filled < total
                q = Instr(ln$, ",")
                If q > 0 Then
                    tok$ = Trim(Left(ln$, q - 1)) : ln$ = Mid(ln$, q + 1)
                Else
                    tok$ = Trim(ln$) : ln$ = ""
                End If
                If tok$ <> "" Then
                    q = Instr(tok$, ":")
                    If q > 0 Then
                        v = Val(Left(tok$, q - 1)) : cnt = Val(Mid(tok$, q + 1))
                    Else
                        v = Val(tok$) : cnt = 1
                    End If
                    Do While cnt > 0 And filled < total
                        map(j, i).Tile = v
                        Select Case v
                        Case 0, -1, -2, -3, -4, -5, -6, -7, 7, 21, 22, 20, 10, 11, 14, 16, 17, 13, 4, 18, 19, 24, 25, 26, 27, 28, 29, 30, 68 To 110, 33, 34, 36, 37, 38, 39, 42, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57
                            map(j, i).Walkon = false
                        Case Else
                            map(j, i).Walkon = true
                        End Select
                        j = j + 1
                        If j > WorldData.Cols Then j = 1 : i = i + 1
                        filled = filled + 1
                        cnt = cnt - 1
                    Loop
                End If
            Loop
        End If
    Loop

    ' --- reach the warp marker (new maps); old maps just hit EOF here ---
    If atWarps = 0 Then
        Do While Not EOF(f)
            Line Input #f, ln$
            If Trim(ln$) = "#WARPS" Then Exit Do
        Loop
    End If

    ' --- warp section ---
    Do While Not EOF(f)
        Line Input #f, ln$
        ln$ = Trim(ln$)
        If ln$ <> "" And Left(ln$, 1) <> "#" And Left(ln$, 1) <> "'" Then
            WarpN = WarpN + 1
            ws$ = ln$
            Warps(WarpN).srcCol     = Val(PopField(ws$)) + 1   ' editor 0-based -> grid
            Warps(WarpN).srcRow     = Val(PopField(ws$)) + 1
            Warps(WarpN).destMap    = PopField(ws$)
            Warps(WarpN).destPlace  = Val(PopField(ws$))
            Warps(WarpN).destInside = Val(PopField(ws$))
            Warps(WarpN).destCol    = Val(PopField(ws$)) + 1
            Warps(WarpN).destRow    = Val(PopField(ws$)) + 1
            If WarpN >= 200 Then Exit Do
        End If
    Loop

    Close #f

    WorldData.TopRow = wx
    WorldData.TopCol = wy
    ' Gate of Relics: wardens already satisfied stay cleared on re-entry
    If WorldData.Place = 19 Then
        If O1 = 1 Then map(11, 15).Tile = 6: map(11, 15).Walkon = true
        If O2 = 1 Then map(10, 12).Tile = 6: map(10, 12).Walkon = true
        If O3 = 1 Then map(11, 9).Tile = 6: map(11, 9).Walkon = true
        If O4 = 1 Then map(10, 6).Tile = 6: map(10, 6).Walkon = true
        If O5 = 1 Then map(11, 3).Tile = 6: map(11, 3).Walkon = true
    End If
    WorldData.Terreng = 1
End Sub

'-------------------------------------------
' Pops the first comma-delimited field off s$ (trimmed) and shortens s$.
Function PopField (ByRef s As String) As String
    dim as integer q
    q = Instr(s, ",")
    If q > 0 Then
        PopField = Trim(Left(s, q - 1))
        s = Trim(Mid(s, q + 1))
    Else
        PopField = Trim(s)
        s = ""
    End If
End Function

'-------------------------------------------
Sub LoadShit
    dim as integer x
    
    Cls
    'Width 80
    Color 1
    For X = 1 To 40: Locate 1, X: Print "�"
    Next
    
    
    Color 15, 1
    Locate 1, 1: Print "Loading Araxia: Shadow of Etheros"
    Color 7, 0
    Print 
    Print "Time: "; TIME$; "   Date: "; DATE$
    Print
    Print "FontLoad    : ";
    
    
    Loadfont
    Print "Done!"
    Print "SetupPalette: ";
    SetupPalette
    Print "Done!"
    Print "SetupLevels : ";
    SetupLevels
    Print "Done!"
    Print "InitVars    : ";
    Print "Done!"
    Print "LoadTiles   : ";
    LoadTiles
    Print "Done!"
    Print "LoadMap     : ";
    Print "Done!"
    
    Print "Load Music  : ";
    LoadMusic
    Print "Done!"
    
    Print "": Print "Araxia is Loaded!": Print "": Print "Press Any key to Continue..."
    waitkey
    Begin
End Sub

'-------------------------------------------
Sub LoadTiles
    
    '���������������������������������������������������������    ���     ��     �
    ' DEF SEG = VARSEG(Tree1(0)): BLOAD "tree.mdt", VARPTR(Tree1(0))
    '                  Array            "Tile"             Array
    ' The 0 represents the offset, or where the data starts loading. This is just
    ' important for those of you that have indexed pictures.
    '���������������������������������������������������������    ���     ��     �
    Bload "black.mdt", Varptr(black(0))
    Bload "grass1.mdt", Varptr(grass1(0))
    Bload "grass2.mdt", Varptr(grass2(0))
    Bload "water1.mdt", Varptr(water1(0))
    Bload "tree1.mdt", Varptr(tree1(0))
    Bload "tree2.mdt", Varptr(tree2(0))
    Bload "tree3.mdt", Varptr(tree3(0))
    Bload "tree4.mdt", Varptr(tree4(0))
    Bload "wall01.mdt", Varptr(wall01(0))
    Bload "wall02.mdt", Varptr(wall02(0))
    Bload "floor1.mdt", Varptr(path01(0))
    Bload "path01.mdt", Varptr(path02(0))
    Bload "floor2.mdt", Varptr(path03(0))
    Bload "roof1.mdt", Varptr(roof1(0))
    Bload "wall1.mdt", Varptr(wall1(0))
    Bload "wall2.mdt", Varptr(wall2(0))
    Bload "door1.mdt", Varptr(door1(0))
    Bload "door2.mdt", Varptr(door2(0))
    Bload "firepc.mdt", Varptr(firepc(0))
    Bload "bush1.mdt", Varptr(bush1(0))
    Bload "wind01.mdt", Varptr(wind1(0))
    Bload "wind02.mdt", Varptr(wind2(0))
    Bload "bed1.mdt", Varptr(bed1(0))
    Bload "bed2.mdt", Varptr(bed2(0))
    Bload "desk1.mdt", Varptr(desk1(0))
    Bload "barrel1.mdt", Varptr(barrel1(0))
    Bload "table1.mdt", Varptr(table1(0))
    Bload "sign1.mdt", Varptr(sign1(0))
    Bload "torch1.mdt", Varptr(torch1(0))
    Bload "shelf1.mdt", Varptr(shelf1(0))
    Bload "gold.mdt", Varptr(gold1(0))
    Bload "poti.mdt", Varptr(Potio1(0))
    Bload "poti2.mdt", Varptr(Potio2(0))
    Bload "poti3.mdt", Varptr(Potio3(0))
    Bload "poison1.mdt", Varptr(PoisLeaf(0))
    Bload "clerk1.mdt", Varptr(Clerk1(0))
    Bload "desk2.mdt", Varptr(Desk2(0))
    Bload "table2.mdt", Varptr(Table2(0))
    Bload "sign2.mdt", Varptr(sign2(0))
    Bload "dock1.mdt", Varptr(dock1(0))
    Bload "lamp1.mdt", Varptr(lamp1(0))
    Bload "crate1.mdt", Varptr(crate1(0))
    Bload "dbarrel1.mdt", Varptr(dbarrel1(0))
    Bload "dock2.mdt", Varptr(dock2(0))
    Bload "rope1.mdt", Varptr(rope1(0))
    Bload "well1.mdt", Varptr(well1(0))
    Bload "rock1.mdt", Varptr(rock1(0))
    Bload "grass3.mdt", Varptr(Grass3(0))
    Bload "grass4.mdt", Varptr(Grass4(0))
    Bload "hedge1.mdt", Varptr(Hedge01(0))
    Bload "hedge2.mdt", Varptr(Hedge02(0))
    Bload "man01.mdt", Varptr(Man01(0))
    Bload "man01m.mdt", Varptr(Man01m(0))
    Bload "lich.mdt", Varptr(Lich(0))
    Bload "bhaulx.mdt", Varptr(Bhaulx(0))
    Dim As UByte Ptr bhp = Cast(UByte Ptr, Varptr(Bhaulx(0)))
    Dim As Integer bhi
    For bhi = 4 To 403
        If bhp[bhi] = 161 Then bhp[bhi] = 0
    Next
    Bload "man02.mdt", Varptr(Man02(0))
    Bload "man03.mdt", Varptr(Man03(0))
    Bload "man04.mdt", Varptr(Man04(0))
    Bload "man05.mdt", Varptr(Man05(0))
    Bload "man05m.mdt", Varptr(Man05m(0))
    Bload "man06.mdt", Varptr(Man06(0))
    Bload "man07.mdt", Varptr(Man07(0))
    Bload "ashyground.mdt", Varptr(AshyGround(0))
    Bload "emberpile.mdt", Varptr(EmberPile(0))
    Bload "gravemound.mdt", Varptr(GraveMound(0))
    Bload "tombstone.mdt", Varptr(Tombstone(0))
    Bload "tombstone2.mdt", Varptr(Tombstone2(0))
    Bload "ironfence.mdt", Varptr(IronFence(0))
    Bload "woodenfence.mdt", Varptr(WoodenFence(0))
    Bload "guyd1.mdt", Varptr(PlayerDown1(0))
    Bload "guyd2.mdt", Varptr(PlayerDown2(0))
    Bload "guyd1m.mdt", Varptr(PlayerDown1Mask(0))
    Bload "guyd2m.mdt", Varptr(PlayerDown2Mask(0))
    Bload "guyl1.mdt", Varptr(PlayerLeft1(0))
    Bload "guyl2.mdt", Varptr(PlayerLeft2(0))
    Bload "guyl1m.mdt", Varptr(PlayerLeft1Mask(0))
    Bload "guyl2m.mdt", Varptr(PlayerLeft2Mask(0))
    Bload "guyr1.mdt", Varptr(PlayerRight1(0))
    Bload "guyr2.mdt", Varptr(PlayerRight2(0))
    Bload "guyr1m.mdt", Varptr(PlayerRight1Mask(0))
    Bload "guyr2m.mdt", Varptr(PlayerRight2Mask(0))
    Bload "guyu1.mdt", Varptr(PlayerUp1(0))
    Bload "guyu2.mdt", Varptr(PlayerUp2(0))
    Bload "guyu1m.mdt", Varptr(PlayerUp1Mask(0))
    Bload "guyu2m.mdt", Varptr(PlayerUp2Mask(0))
    Bload "guy.mdt", Varptr(HeroImg(0, 0, 0))
End Sub

'-------------------------------------------
Sub Menu1
    dim as integer HPPercent, x, mi
    dim z$
    dim itm(1 to 6) as string = {"Inventory", "Status", "Bestiary", "Save Game", "Options", "Quit"}
    
    HPPercent = Hp / MaxHp * 100
    box(1, 130, 235, 192)
    TEXT "Name: " + chrname, 175, 6, 145, 1
    Put (8, 155), gold1, Pset: TEXT "= " + Fixed$(gold%), 15, 30, 164, 1
    TEXT "Hp:" + Fixed$(Hp) + "/" + Fixed$(MaxHp), 15, 145, 140, 1
    Line (120, 150)-(220, 157), 172, B
    Line (121, 151)-Step(HPPercent - 2, 3), 77, BF
    Line (121, 154)-Step(HPPercent - 2, 2), 79, BF
    If Poisoned = 1 Then TEXT "Poisoned!", 4, 120, 164, 1
    TEXT "Lv:" + Fixed$(Level), 15, 100, 140, 1
    If Level < 20 Then XpPct = (PlayerExp - LvlXP(Level)) / (LvlXP(Level + 1) - LvlXP(Level)) * 100 Else XpPct = 100
    If XpPct < 0 Then XpPct = 0
    If XpPct > 100 Then XpPct = 100
    TEXT "Xp", 15, 100, 176, 1
    Line (120, 176)-(220, 182), 172, B
    If XpPct > 2 Then Line (121, 177)-Step(XpPct - 2, 4), 9, BF
    box(240, 130, 318, 192)
    X = 1
    Do
        For mi = 1 To 6
            TEXT itm(mi), IIf(mi = X, 9, 15), 250, 126 + mi * 9, 1
        Next
        
        Do
            z$ = INKEY$
            LoopMidi
        Loop Until z$ <> ""
        If z$ = CHR$(27) Then ShowMap: Exit Sub
        If z$ = CHR$(255) + CHR$(80) Then X = X + 1: If X > 6 Then X = 1
        If z$ = CHR$(255) + CHR$(72) Then X = X - 1: If X < 1 Then X = 6
    Loop Until z$ = CHR$(13)
    
    Select Case X
    Case 1
        MenuItems
        Menu1
    Case 2
        MenuStatus
    Case 3
        MenuBestiary
        Cls
        ShowMap
        Menu1
    Case 4
        MenuSaveGame
    Case 5
        MenuOptions
        Cls
        ShowMap
        Menu1
    Case 6
        quit
    End Select
    
End Sub

Sub MenuBestiary
    Dim As Integer i, j, n, cnt, page, per, idx, yy, tmp
    Dim nm(1 To 60) As String
    Dim As Integer ehp(1 To 60), eatk(1 To 60), edef(1 To 60), epsn(1 To 60), egld(1 To 60)
    Dim ord(1 To 60) As Integer
    Dim z$
    n = 0
    If Dir("enemy.dat") <> "" Then
        Open "enemy.dat" For Input As #1
        Do While Not EOF(1) And n < 60
            n = n + 1
            Input #1, nm(n), ehp(n), eatk(n), edef(n), epsn(n), egld(n)
            ord(n) = n
        Loop
        Close #1
    End If
    ' alphabetical sort (simple insertion sort - n is small)
    For i = 2 To n
        tmp = ord(i)
        j = i - 1
        Do While j >= 1 And nm(ord(j)) > nm(tmp)
            ord(j + 1) = ord(j)
            j = j - 1
        Loop
        ord(j + 1) = tmp
    Next
    per = 12
    page = 0
    Do
        Cls
        box(1, 1, 318, 198)
        TEXT "BESTIARY", 9, 130, 6, 1
        cnt = 0
        For i = 1 To n
            If ord(i) <> 18 And ord(i) <> 30 Then cnt = cnt + 1
        Next
        yy = 20
        idx = 0
        For i = 1 To n
            If ord(i) <> 18 And ord(i) <> 30 Then          ' Bhaulx/Etheros: boss-only, never listed
                idx = idx + 1
                If idx > page * per And idx <= page * per + per Then
                    If Bestiary(ord(i)) = 0 Then
                        TEXT "???", 8, 6, yy, 1
                    ElseIf Bestiary(ord(i)) >= 5 Then
                        TEXT nm(ord(i)) + "  HP:" + Fixed$(ehp(ord(i))) + " A:" + Fixed$(eatk(ord(i))) + " D:" + Fixed$(edef(ord(i))), 15, 6, yy, 1
                    Else
                        TEXT nm(ord(i)) + "  (slain " + Fixed$(Bestiary(ord(i))) + "/5 - stats locked)", 7, 6, yy, 1
                    End If
                    yy = yy + 13
                End If
            End If
        Next
        If cnt = 0 Then TEXT "No monsters recorded yet.", 15, 6, 24, 1
        TEXT "Up/Down: page   Esc: back", 170, 6, 188, 1
        Do
            z$ = INKEY$
            LoopMidi
        Loop Until z$ <> ""
        If z$ = CHR$(27) Then Exit Do
        If z$ = CHR$(255) + CHR$(80) Then If (page + 1) * per < cnt Then page = page + 1
        If z$ = CHR$(255) + CHR$(72) Then If page > 0 Then page = page - 1
    Loop
End Sub

'-------------------------------------------
Sub LookRelics
    Dim As Integer n, sel, i
    Dim nm(1 To 5) As String
    Dim ds(1 To 5) As String
    n = 0
    If O1 = 1 Then n = n + 1: nm(n) = "Sun-Winged Aegis": ds(n) = "Defense +4"
    If O2 = 1 Then n = n + 1: nm(n) = "Aquamarine of Ran": ds(n) = "Attack +3"
    If O3 = 1 Then n = n + 1: nm(n) = "Root-Bound Ring": ds(n) = "Defense +3"
    If O4 = 1 Then n = n + 1: nm(n) = "Eye of Foresight": ds(n) = "Defense +2"
    If O5 = 1 Then n = n + 1: nm(n) = "Orm's Seventh Eye": ds(n) = "Attack +5"
    If n = 0 Then Exit Sub
    sel = 1
    Dim a$
    lookuse:
    box(60, 50, 260, 150)
    TEXT "Relics", 9, 130, 56, 1
    For i = 1 To n
        TEXT nm(i), IIf(sel = i, 14, 15), 70, 60 + i * 12, 1
    Next
    TEXT ds(sel), 11, 70, 60 + (n + 2) * 12, 1
    TEXT "Esc: back", 15, 70, 140, 1
    Do
        a$ = INKEY$
        If a$ = CHR$(255) + CHR$(72) Then
            sel = sel - 1: If sel < 1 Then sel = n
            Goto lookuse
        End If
        If a$ = CHR$(255) + CHR$(80) Then
            sel = sel + 1: If sel > n Then sel = 1
            Goto lookuse
        End If
        If a$ = CHR$(27) Then Exit Do
        LoopMidi
    Loop
End Sub

'-------------------------------------------
Sub MenuEquip
    Dim As Integer n, sel, i, kind(1 To 10), bon(1 To 10)
    Dim nm(1 To 10) As String
    Dim a$
    n = 0
    n = n + 1: kind(n) = 1: bon(n) = 1: nm(n) = "Dagger (+1)"
    If OwnWep2 = 1 Then n = n + 1: kind(n) = 1: bon(n) = 2: nm(n) = "Broad Sword (+2)"
    If OwnWep3 = 1 Then n = n + 1: kind(n) = 1: bon(n) = 3: nm(n) = "Long Sword (+3)"
    If OwnWep4 = 1 Then n = n + 1: kind(n) = 1: bon(n) = 4: nm(n) = "Battle Axe (+4)"
    If OwnWep6 = 1 Then n = n + 1: kind(n) = 1: bon(n) = 6: nm(n) = "Jeweled Scimitar (+6)"
    n = n + 1: kind(n) = 2: bon(n) = 1: nm(n) = "Cloth (+1)"
    If OwnArm2 = 1 Then n = n + 1: kind(n) = 2: bon(n) = 2: nm(n) = "Leather Armor (+2)"
    If OwnArm3 = 1 Then n = n + 1: kind(n) = 2: bon(n) = 3: nm(n) = "Chain Mail (+3)"
    If OwnArm4 = 1 Then n = n + 1: kind(n) = 2: bon(n) = 4: nm(n) = "Plate Mail (+4)"
    If OwnArm6 = 1 Then n = n + 1: kind(n) = 2: bon(n) = 6: nm(n) = "Jeweled Armor (+6)"
    sel = 1
    equpuse:
    box(40, 15, 280, 195)
    TEXT "Equip", 9, 140, 20, 1
    Dim As Integer dr
    dr = 0
    TEXT "-- Weapons --", 8, 55, 30 + dr * 11, 1
    dr = dr + 1
    For i = 1 To n
        If kind(i) = 2 And (i = 1 Or kind(i - 1) = 1) Then
            TEXT "-- Armor --", 8, 55, 30 + dr * 11, 1
            dr = dr + 1
        End If
        Dim eqtag$
        eqtag$ = ""
        If kind(i) = 1 And bon(i) = WepB Then eqtag$ = " *"
        If kind(i) = 2 And bon(i) = ArmB Then eqtag$ = " *"
        TEXT nm(i) + eqtag$, IIf(sel = i, 14, 15), 55, 30 + dr * 11, 1
        dr = dr + 1
    Next
    TEXT "Enter: equip   Esc: back", 15, 55, 178, 1
    Do
        a$ = INKEY$
        If a$ = CHR$(255) + CHR$(72) Then
            sel = sel - 1: If sel < 1 Then sel = n
            Goto equpuse
        End If
        If a$ = CHR$(255) + CHR$(80) Then
            sel = sel + 1: If sel > n Then sel = 1
            Goto equpuse
        End If
        If a$ = CHR$(13) Then
            If kind(sel) = 1 Then
                WepB = bon(sel)
                Select Case WepB
                Case 1: Wep$ = "Dagger"
                Case 2: Wep$ = "Broad Sword"
                Case 3: Wep$ = "Long Sword"
                Case 4: Wep$ = "Battle Axe"
                Case 6: Wep$ = "Jeweled Scimitar"
                End Select
            Else
                ArmB = bon(sel)
                Select Case ArmB
                Case 1: Arm$ = "Cloth"
                Case 2: Arm$ = "Leather Armor"
                Case 3: Arm$ = "Chain Mail"
                Case 4: Arm$ = "Plate Mail"
                Case 6: Arm$ = "Jeweled Armor"
                End Select
            End If
            Goto equpuse
        End If
        If a$ = CHR$(27) Then Exit Do
        LoopMidi
    Loop
End Sub

'-------------------------------------------
Sub SellWeapon
    Dim As Integer n, sel, i, bon(1 To 4), price(1 To 4)
    Dim nm(1 To 4) As String
    Dim a$
    n = 0
    If OwnWep2 = 1 And WepB <> 2 Then n = n + 1: bon(n) = 2: price(n) = 100: nm(n) = "Broad Sword"
    If OwnWep3 = 1 And WepB <> 3 Then n = n + 1: bon(n) = 3: price(n) = 200: nm(n) = "Long Sword"
    If OwnWep4 = 1 And WepB <> 4 Then n = n + 1: bon(n) = 4: price(n) = 250: nm(n) = "Battle Axe"
    If OwnWep6 = 1 And WepB <> 6 Then n = n + 1: bon(n) = 6: price(n) = 500: nm(n) = "Jeweled Scimitar"
    If n = 0 Then
        TEXT " Nothing else to sell ", 15, 43, 92, 1
        waitkey
        Exit Sub
    End If
    sel = 1
    sellwuse:
    box(46, 60, 274, 120)
    TEXT "Sell which weapon?", 9, 54, 66, 1
    For i = 1 To n
        TEXT nm(i) + "  " + Fixed$(price(i)) + "g", IIf(sel = i, 14, 15), 54, 66 + i * 11, 1
    Next
    Do
        a$ = INKEY$
        If a$ = CHR$(255) + CHR$(72) Then
            sel = sel - 1: If sel < 1 Then sel = n
            Goto sellwuse
        End If
        If a$ = CHR$(255) + CHR$(80) Then
            sel = sel + 1: If sel > n Then sel = 1
            Goto sellwuse
        End If
        If a$ = CHR$(13) Then
            gold% = gold% + price(sel)
            Select Case bon(sel)
            Case 2: OwnWep2 = 0
            Case 3: OwnWep3 = 0
            Case 4: OwnWep4 = 0
            Case 6: OwnWep6 = 0
            End Select
            box(46, 60, 274, 120)
            TEXT "Sold " + nm(sel) + " for " + Fixed$(price(sel)) + "g", 15, 54, 90, 1
            waitkey
            Exit Sub
        End If
        If a$ = CHR$(27) Then Exit Sub
        LoopMidi
    Loop
End Sub

'-------------------------------------------
Sub SellArmor
    Dim As Integer n, sel, i, bon(1 To 4), price(1 To 4)
    Dim nm(1 To 4) As String
    Dim a$
    n = 0
    If OwnArm2 = 1 And ArmB <> 2 Then n = n + 1: bon(n) = 2: price(n) = 75: nm(n) = "Leather Armor"
    If OwnArm3 = 1 And ArmB <> 3 Then n = n + 1: bon(n) = 3: price(n) = 175: nm(n) = "Chain Mail"
    If OwnArm4 = 1 And ArmB <> 4 Then n = n + 1: bon(n) = 4: price(n) = 225: nm(n) = "Plate Mail"
    If OwnArm6 = 1 And ArmB <> 6 Then n = n + 1: bon(n) = 6: price(n) = 450: nm(n) = "Jeweled Armor"
    If n = 0 Then
        TEXT " Nothing else to sell ", 15, 43, 92, 1
        waitkey
        Exit Sub
    End If
    sel = 1
    sellause:
    box(46, 60, 274, 120)
    TEXT "Sell which armor?", 9, 54, 66, 1
    For i = 1 To n
        TEXT nm(i) + "  " + Fixed$(price(i)) + "g", IIf(sel = i, 14, 15), 54, 66 + i * 11, 1
    Next
    Do
        a$ = INKEY$
        If a$ = CHR$(255) + CHR$(72) Then
            sel = sel - 1: If sel < 1 Then sel = n
            Goto sellause
        End If
        If a$ = CHR$(255) + CHR$(80) Then
            sel = sel + 1: If sel > n Then sel = 1
            Goto sellause
        End If
        If a$ = CHR$(13) Then
            gold% = gold% + price(sel)
            Select Case bon(sel)
            Case 2: OwnArm2 = 0
            Case 3: OwnArm3 = 0
            Case 4: OwnArm4 = 0
            Case 6: OwnArm6 = 0
            End Select
            box(46, 60, 274, 120)
            TEXT "Sold " + nm(sel) + " for " + Fixed$(price(sel)) + "g", 15, 54, 90, 1
            waitkey
            Exit Sub
        End If
        If a$ = CHR$(27) Then Exit Sub
        LoopMidi
    Loop
End Sub

'-------------------------------------------
Sub MenuItems
    dim as integer HPPercent
    dim a$
    Dim sel As Integer
    sel = 1
    
    use:
    HPPercent = Hp / MaxHp * 100
    box(1, 130, 235, 192)
    TEXT "Name: " + chrname, 175, 6, 145, 1
    Put (8, 155), gold1, Pset: TEXT "= " + Fixed$(gold%), 15, 30, 164, 1
    TEXT "Hp:" + Fixed$(Hp) + "/" + Fixed$(MaxHp), 15, 145, 140, 1
    Line (120, 150)-(220, 157), 172, B
    Line (121, 151)-Step(HPPercent - 2, 3), 77, BF
    Line (121, 154)-Step(HPPercent - 2, 2), 79, BF
    If Poisoned = 1 Then TEXT "Poisoned!", 4, 120, 164, 1
    TEXT "Lv:" + Fixed$(Level), 15, 100, 140, 1
    If Level < 20 Then XpPct = (PlayerExp - LvlXP(Level)) / (LvlXP(Level + 1) - LvlXP(Level)) * 100 Else XpPct = 100
    If XpPct < 0 Then XpPct = 0
    If XpPct > 100 Then XpPct = 100
    TEXT "Xp", 15, 100, 176, 1
    Line (120, 176)-(220, 182), 172, B
    If XpPct > 2 Then Line (121, 177)-Step(XpPct - 2, 4), 9, BF
    box(1, 1, 318, 20)
    box(1, 20, 180, 125)
    box(180, 20, 318, 125)
    TEXT "Heals/Herbs", 9, 20, 5, 1
    TEXT "Items", 9, 230, 5, 1
    TEXT "L) Look", 15, 260, 5, 1
    TEXT "E) Equip", 15, 260, 14, 1
    If O1 = 1 Then TEXT "# Sun-Winged Aegis", 4, 184, 30, 1
    If O2 = 1 Then TEXT "# Aquamarine of Ran", 14, 184, 40, 1
    If O3 = 1 Then TEXT "# Root-Bound Ring", 8, 184, 50, 1
    If O4 = 1 Then TEXT "# Eye of Foresight", 2, 184, 60, 1
    If O5 = 1 Then TEXT "# Orm's Seventh Eye", 9, 184, 70, 1
    TEXT "Fish: " + Fixed$(Fish), 15, 184, 82, 1
    TEXT "Rare Fish: " + Fixed$(RareFish), 14, 184, 92, 1
    TEXT "Trophies: " + Fixed$(Trophies), 15, 184, 102, 1
    
    ' consumables (FF-style cursor list) - always show all four
    Put (10, 30), Potio1, Pset
    TEXT "Large Heal  x" + Fixed$(Fpot), IIf(Fpot >= 1, 15, 8), 30, 30, 1
    Put (10, 40), Potio2, Pset
    TEXT "Small Heal  x" + Fixed$(SPot), IIf(SPot >= 1, 15, 8), 30, 40, 1
    Put (10, 50), PoisLeaf, Pset
    TEXT "Antidote    x" + Fixed$(PHerb), IIf(PHerb >= 1, 15, 8), 30, 50, 1
    Put (10, 60), Potio3, Pset
    TEXT "Agility Pot x" + Fixed$(AHerb), IIf(AHerb >= 1, 15, 8), 30, 60, 1
    TEXT ">", 14, 2, 20 + sel * 10, 1
    TEXT "Up/Dn: pick", 15, 6, 104, 1
    TEXT "Enter use  Esc back", 15, 6, 114, 1
    
    Do
        a$ = INKEY$
        If a$ = CHR$(255) + CHR$(72) Then
            sel = sel - 1: If sel < 1 Then sel = 4
            Goto use
        End If
        If a$ = CHR$(255) + CHR$(80) Then
            sel = sel + 1: If sel > 4 Then sel = 1
            Goto use
        End If
        If a$ = CHR$(13) Then
            If sel = 1 And Fpot >= 1 Then Hp = MaxHp: Fpot = Fpot - 1: Goto use
            If sel = 2 And SPot >= 1 Then
                Hp = Hp + 10: If Hp > MaxHp Then Hp = MaxHp
                SPot = SPot - 1
                Goto use
            End If
            If sel = 3 And PHerb >= 1 Then Poisoned = 0: PHerb = PHerb - 1: Goto use
            If sel = 4 And AHerb >= 1 Then Runa = 1: AHerb = AHerb - 1: Goto use
        End If
        If a$ = "L" Or a$ = "l" Then
            LookRelics
            Goto use
        End If
        If a$ = "E" Or a$ = "e" Then
            MenuEquip
            Goto use
        End If
        If a$ = CHR$(27) Then Exit Do
        LoopMidi
    Loop
    ShowMap
End Sub

'-------------------------------------------
Sub MenuSaveGame
    dim as integer  Wdtc, Wdtr
    
    box(50, 50, 290, 80)
    If WorldData.Inside = 0 Then
        TEXT "Must be Inside a Building to Save Game!", 15, 56, 60, 1
        waitkey
        ShowMap
        Menu1
        Exit Sub
    End If
    TEXT "Game Saved!", 15, 130, 60, 1
    Wdtc = WorldData.TopCol
    Wdtr = WorldData.TopRow
    Open "save.dat" For Output As #1
    Write #1, chrname, WorldData.Place, Wdtc, Wdtr, Hp, MaxHp, gold%, Fpot, SPot, PHerb, AHerb, Poisoned, Runa, Wep$, WepB, Arm$, ArmB, ItemWepB, ItemArmB, O1, O2, O3, O4, O5, Q1, Q2, Q3, Q4, Q5, kills, Level, PlayerExp, Trophies, Fish, RareFish, DeathQ, OwnWep2, OwnWep3, OwnWep4, OwnWep6, OwnArm2, OwnArm3, OwnArm4, OwnArm6
    Close #1
    Dim bi As Integer
    Open "beast.dat" For Output As #2
    For bi = 1 To 60: Write #2, Bestiary(bi): Next
    Close #2
    Dim As Integer fgZ, fgX, fgY
    Dim fgS As String
    Open "fog.dat" For Output As #3
    For fgZ = 1 To 4
        fgS = ""
        For fgY = -9 To 67
            For fgX = -9 To 67
                fgS = fgS + Chr$(48 + Fog(fgZ, fgX, fgY))
            Next
        Next
        Write #3, fgS
    Next
    Close #3
    waitkey
    ShowMap
    Menu1
End Sub

'-------------------------------------------
Sub MenuStatus
    box(1, 1, 315, 128)
    TEXT "Status / Weapons", 9, 20, 5, 1
    TEXT "Name: " + (chrname), 15, 15, 25, 1
    TEXT "Hit Points:" + Fixed$(Hp) + "/" + Fixed$(MaxHp), 15, 15, 35, 1
    TEXT "Gold:" + Fixed$(gold%), 15, 15, 45, 1
    TEXT "Weapon:" + (Wep$) + " + " + Fixed$(WepB), 79, 15, 65, 1
    TEXT "Armor:" + (Arm$) + " + " + Fixed$(ArmB), 79, 15, 75, 1
    TEXT "Total Attack Skill:" + Fixed$(WepB + ItemWepB + (Level - 1)), 108, 15, 95, 1
    TEXT "Total Defense Skill:" + Fixed$(ArmB + ItemArmB + (Level - 1)), 109, 15, 105, 1
    If Level < 20 Then
        TEXT "Level:" + Fixed$(Level) + "  Exp:" + Fixed$(CInt(PlayerExp)) + "/" + Fixed$(CInt(LvlXP(Level + 1))), 15, 15, 115, 1
    Else
        TEXT "Level: 20 (MAX)", 15, 15, 115, 1
    End If
    If Level < 20 Then
        Dim XpPct As Integer
        XpPct = (PlayerExp - LvlXP(Level)) * 100 \ (LvlXP(Level + 1) - LvlXP(Level))
        If XpPct < 0 Then XpPct = 0
        If XpPct > 100 Then XpPct = 100
        TEXT "XP", 15, 158, 117, 1
        Line (175, 116)-(277, 124), 172, B
        If XpPct > 1 Then Line (176, 117)-Step(XpPct - 2, 6), 9, BF
    End If
    TEXT "Trophies:" + Fixed$(Trophies), 4, 220, 105, 1
    waitkey
    ShowMap
    Menu1
    
End Sub


'-------------------------------------------
Sub MoveDown
    
    WorldData.Direc = South
    ChangeAnim
    
    If map(WorldData.TopCol + 8, WorldData.TopRow + 5 + 1).Walkon = true Then
        WorldData.Terreng = map(WorldData.TopCol + 8, WorldData.TopRow + 5 + 1).Tile
        WorldData.TopRow = WorldData.TopRow + 1
        WorldData.NPC = map(WorldData.TopCol + 8, WorldData.TopRow + 5 + 1).Tile
        WorldData.NPCcol = WorldData.TopCol + 8: WorldData.NPCrow = WorldData.TopRow + 5 + 1
        SY = -20
        move = 1
    else
        WorldData.Terreng = map(WorldData.TopCol + 8, WorldData.TopRow + 5 + 1).Tile
        WorldData.NPC = WorldData.Terreng
        WorldData.NPCcol = WorldData.TopCol + 8: WorldData.NPCrow = WorldData.TopRow + 5 + 1
    End If
    
End Sub

'-------------------------------------------
Sub MoveLeft
    
    WorldData.Direc = West
    ChangeAnim
    
    If map(WorldData.TopCol + 8 - 1, WorldData.TopRow + 5).Walkon = true Then
        WorldData.Terreng = map(WorldData.TopCol + 8 - 1, WorldData.TopRow + 5).Tile
        WorldData.TopCol = WorldData.TopCol - 1
        WorldData.NPC = map(WorldData.TopCol + 8 - 1, WorldData.TopRow + 5).Tile
        WorldData.NPCcol = WorldData.TopCol + 8 - 1: WorldData.NPCrow = WorldData.TopRow + 5
        SX = 20
        move = 1
    else
        WorldData.Terreng = map(WorldData.TopCol + 8 - 1, WorldData.TopRow + 5).Tile
        WorldData.NPC = WorldData.Terreng
        WorldData.NPCcol = WorldData.TopCol + 8 - 1: WorldData.NPCrow = WorldData.TopRow + 5
    End If
    
End Sub

'-------------------------------------------
Sub MoveRight
    
    WorldData.Direc = East
    ChangeAnim
    
    If map(WorldData.TopCol + 8 + 1, WorldData.TopRow + 5).Walkon = true Then
        WorldData.Terreng = map(WorldData.TopCol + 8 + 1, WorldData.TopRow + 5).Tile
        WorldData.TopCol = WorldData.TopCol + 1
        WorldData.NPC = map(WorldData.TopCol + 8 + 1, WorldData.TopRow + 5).Tile
        WorldData.NPCcol = WorldData.TopCol + 8 + 1: WorldData.NPCrow = WorldData.TopRow + 5
        SX = -20
        move = 1
    else
        WorldData.Terreng = map(WorldData.TopCol + 8 + 1, WorldData.TopRow + 5).Tile
        WorldData.NPC = WorldData.Terreng
        WorldData.NPCcol = WorldData.TopCol + 8 + 1: WorldData.NPCrow = WorldData.TopRow + 5
    End If
    
    
End Sub

'-------------------------------------------
Sub MoveUp
    
    WorldData.Direc = North
    ChangeAnim
    
    If map(WorldData.TopCol + 8, WorldData.TopRow + 5 - 1).Walkon = true Then
        WorldData.Terreng = map(WorldData.TopCol + 8, WorldData.TopRow + 5 - 1).Tile
        WorldData.TopRow = WorldData.TopRow - 1
        WorldData.NPC = map(WorldData.TopCol + 8, WorldData.TopRow + 5 - 1).Tile
        WorldData.NPCcol = WorldData.TopCol + 8: WorldData.NPCrow = WorldData.TopRow + 5 - 1
        SY = 20
        move = 1
    else
        WorldData.Terreng = map(WorldData.TopCol + 8, WorldData.TopRow + 5 - 1).Tile
        WorldData.NPC = WorldData.Terreng
        WorldData.NPCcol = WorldData.TopCol + 8: WorldData.NPCrow = WorldData.TopRow + 5 - 1
    End If
    
End Sub


'-------------------------------------------
Sub NpcTalk (FileName$)
    dim as integer NPOI, TRAVEL, times, BLIPNUM, TRAVEL1, TRAVEL2, TRAVEL3
    dim as integer x, TextColor
    dim z$, mitter$, tx1$, tx2$, tx3$, tx4$, tx5$, RESPONSE1$, RESPONSE2$, RESPONSE3$
    
    TALKTONPC:
    NPOI = Val(mitter$)
    TRAVEL = 1
    SNIPER:
    box(38, 28, 282, 140)
    ReadNpcPage FileName$, TRAVEL, tx1$, tx2$, tx3$, tx4$, tx5$, RESPONSE1$, TRAVEL1, RESPONSE2$, TRAVEL2, RESPONSE3$, TRAVEL3
    Gosub SAYTEXT
    If RESPONSE1$ = "" Then Do: LoopMidi: Loop Until INKEY$ <> "": Cls : Exit Sub
    X = 1
    Do
        TextColor = 170
        If X = 1 Then TextColor = 239
        TEXT RESPONSE1$, TextColor, 43, 102, 1
        TextColor = 170
        If X = 2 Then TextColor = 239
        If RESPONSE2$ <> "" Then TEXT RESPONSE2$, TextColor, 43, 112, 1
        TextColor = 170
        If X = 3 Then TextColor = 239
        If RESPONSE3$ <> "" Then TEXT RESPONSE3$, TextColor, 43, 122, 1
        
        Do
            z$ = INKEY$
            LoopMidi
        Loop Until z$ <> ""
        If RESPONSE2$ <> "" Then
            If z$ = CHR$(255) + CHR$(72) And X <> 1 Then X = X - 1
            If z$ = CHR$(255) + CHR$(80) And RESPONSE3$ <> "" And X <> 3 Then X = X + 1
            If z$ = CHR$(255) + CHR$(80) And RESPONSE3$ = "" And X <> 2 Then X = X + 1
        End If
        LoopMidi
    Loop Until z$ = CHR$(13) Or z$ = " "
    
    If X = 1 Then TRAVEL = TRAVEL1
    If X = 2 Then TRAVEL = TRAVEL2
    If X = 3 Then TRAVEL = TRAVEL3
    If TRAVEL = 0 Then Exit Sub
    Goto SNIPER
    
    SAYTEXT:
    TEXT tx1$, 15, 43, 32, 1
    If tx2$ <> "" Then
        TEXT tx2$, 15, 43, 42, 1
    End If
    If tx3$ <> "" Then
        TEXT tx3$, 15, 43, 52, 1
    End If
    If tx4$ <> "" Then
        TEXT tx4$, 15, 43, 62, 1
    End If
    If tx5$ <> "" Then
        TEXT tx5$, 15, 43, 72, 1
    End If
    Return
    
End Sub

'-------------------------------------------
Sub putPlayerPic
    
    If WorldData.Terreng = 12 Or (WorldData.Terreng = 10 And WorldData.Direc = South) Or (WorldData.Terreng = 21 And WorldData.Direc = South) Then
        Exit Sub
    End If
    
    Select Case WorldData.Direc
    Case North
        If WorldData.AnimCycle = 1 Then
            Put (162, WorldData.PlayerY), PlayerUp1Mask, And
            Put (162, WorldData.PlayerY), PlayerUp1, Or
        Else
            Put (162, WorldData.PlayerY), PlayerUp2Mask, And
            Put (162, WorldData.PlayerY), PlayerUp2, Or
        End If
    Case East
        If WorldData.AnimCycle = 1 Then
            Put (162, WorldData.PlayerY), PlayerRight1Mask, And
            Put (162, WorldData.PlayerY), PlayerRight1, Or
        Else
            Put (162, WorldData.PlayerY), PlayerRight2Mask, And
            Put (162, WorldData.PlayerY), PlayerRight2, Or
        End If
    Case South
        If WorldData.AnimCycle = 1 Then
            Put (162, WorldData.PlayerY), PlayerDown1Mask, And
            Put (162, WorldData.PlayerY), PlayerDown1, Or
        Else
            Put (162, WorldData.PlayerY), PlayerDown2Mask, And
            Put (162, WorldData.PlayerY), PlayerDown2, Or
        End If
    Case West
        If WorldData.AnimCycle = 1 Then
            Put (162, WorldData.PlayerY), PlayerLeft1Mask, And
            Put (162, WorldData.PlayerY), PlayerLeft1, Or
        Else
            Put (162, WorldData.PlayerY), PlayerLeft2Mask, And
            Put (162, WorldData.PlayerY), PlayerLeft2, Or
        End If
    End Select
End Sub

'-------------------------------------------
Sub PutTile (Ico as integer, Jco as integer, MapNo as integer)
    
    Select Case MapNo
    Case -1
        Put (Ico , Jco ), water1, Pset
    Case -2
        Put (Ico , Jco ), tree1, Pset
    Case -3
        Put (Ico , Jco ), tree2, Pset
    Case -4
        Put (Ico , Jco ), sign1, Pset
    Case -5
        Put (Ico , Jco ), sign2, Pset
    Case -6
        Put (Ico , Jco ), tree3, Pset
    Case -7
        Put (Ico , Jco ), tree4, Pset
    Case -8
        Put (Ico , Jco ), door2, Pset
    Case -9
        Put (Ico , Jco ), door1, Pset
    Case 0
        Put (Ico , Jco ), black, Pset
    Case 1
        Put (Ico , Jco ), grass1, Pset
    Case 2
        Put (Ico , Jco ), grass2, Pset
    Case 3
        Put (Ico , Jco ), path01, Pset
    Case 4
        Put (Ico , Jco ), bush1, Pset
    Case 5
        Put (Ico , Jco ), path02, Pset
    Case 6
        Put (Ico , Jco ), path03, Pset
    Case 7
        Put (Ico , Jco ), rock1, Pset
    Case 10
        Put (Ico , Jco ), wall1, Pset
    Case 11, 15
        Put (Ico , Jco ), wall2, Pset
    Case 12
        Put (Ico , Jco ), roof1, Pset
    Case 13
        Put (Ico , Jco ), wind1, Pset
    Case 14
        Put (Ico , Jco ), firepc, Pset
    Case 16
        Put (Ico , Jco ), bed1, Pset
    Case 17
        Put (Ico , Jco ), bed2, Pset
    Case 18
        Put (Ico , Jco ), desk1, Pset
    Case 19
        Put (Ico , Jco ), torch1, Pset
    Case 20, 23
        Put (Ico , Jco ), wall02, Pset
    Case 21
        Put (Ico , Jco ), wall01, Pset
    Case 22
        Put (Ico , Jco ), wind2, Pset
    Case 24
        Put (Ico , Jco ), barrel1, Pset
    Case 25
        Put (Ico , Jco ), table1, Pset
    Case 26
        Put (Ico , Jco ), shelf1, Pset
    Case 27
        Put (Ico , Jco ), Table2, Pset
    Case 28, 30
        Put (Ico , Jco ), Desk2, Pset
    Case 29
        Put (Ico , Jco ), Clerk1, Pset
    Case 31
        Put (Ico , Jco ), Grass3, Pset
    Case 32
        Put (Ico , Jco ), Grass4, Pset
    Case 33
        Put (Ico , Jco ), Hedge01, Pset
    Case 34
        Put (Ico , Jco ), Hedge02, Pset
    Case 35
        Put (Ico , Jco ), dock1, Pset
    Case 36
        Put (Ico , Jco ), lamp1, Pset
    Case 37
        Put (Ico , Jco ), crate1, Pset
    Case 38
        Put (Ico , Jco ), dbarrel1, Pset
    Case 40
        Put (Ico , Jco ), dock2, Pset
    Case 41
        Put (Ico , Jco ), rope1, Pset
    Case 42
        Put (Ico , Jco ), well1, Pset
    Case 68, 94
        Put (Ico , Jco ), path01, Pset
        Put (Ico , Jco ), Man05m, And
        Put (Ico , Jco ), Man07, Or
    Case 69, 108
        Put (Ico , Jco ), path01, Pset
        Put (Ico , Jco ), Man05m, And
        Put (Ico , Jco ), Man06, Or
    Case 70
        Put (Ico , Jco ), path01, Pset
        Put (Ico , Jco ), Man05m, And
        Put (Ico , Jco ), Man05, Or
    Case 71
        Put (Ico , Jco ), path01, Pset
        Put (Ico , Jco ), Man01m, And
        Put (Ico , Jco ), Man04, Or
    Case 72
        Put (Ico , Jco ), path01, Pset
        Put (Ico , Jco ), Man01m, And
        Put (Ico , Jco ), Man03, Or
    Case 73
        Put (Ico , Jco ), path01, Pset
        Put (Ico , Jco ), Man01m, And
        Put (Ico , Jco ), Man02, Or
    Case 74
        Put (Ico , Jco ), path01, Pset
        Put (Ico , Jco ), Man01m, And
        Put (Ico , Jco ), Man01, Or
    Case 75
        Put (Ico , Jco ), path03, Pset
        Put (Ico , Jco ), Man05m, And
        Put (Ico , Jco ), Man07, Or
    Case 76
        Put (Ico , Jco ), path03, Pset
        Put (Ico , Jco ), Man05m, And
        Put (Ico , Jco ), Man06, Or
    Case 77
        Put (Ico , Jco ), path03, Pset
        Put (Ico , Jco ), Man05m, And
        Put (Ico , Jco ), Man05, Or
    Case 78, 98
        Put (Ico , Jco ), path03, Pset
        Put (Ico , Jco ), Man01m, And
        Put (Ico , Jco ), Man04, Or
    Case 79
        Put (Ico , Jco ), path03, Pset
        Put (Ico , Jco ), Man01m, And
        Put (Ico , Jco ), Man03, Or
    Case 80
        Put (Ico , Jco ), path03, Pset
        Put (Ico , Jco ), Man01m, And
        Put (Ico , Jco ), Man02, Or
    Case 81
        Put (Ico , Jco ), path03, Pset
        Put (Ico , Jco ), Man01m, And
        Put (Ico , Jco ), Man01, Or
    Case 83, 92, 104, 109
        If WorldData.Place >= 10 Then Put (Ico , Jco ), grass2, Pset
        If WorldData.Place <= 9 Then Put (Ico , Jco ), grass1, Pset
        Put (Ico , Jco ), Man05m, And
        Put (Ico , Jco ), Man07, Or
    Case 105
        If WorldData.Place >= 10 Then Put (Ico , Jco ), grass2, Pset
        If WorldData.Place <= 9 Then Put (Ico , Jco ), grass1, Pset
        Put (Ico , Jco ), rock1, Pset
    Case 84, 93, 103
        If WorldData.Place >= 10 Then Put (Ico , Jco ), grass2, Pset
        If WorldData.Place <= 9 Then Put (Ico , Jco ), grass1, Pset
        Put (Ico , Jco ), Man05m, And
        Put (Ico , Jco ), Man06, Or
    Case 82, 85
        If WorldData.Place >= 10 Then Put (Ico , Jco ), grass2, Pset
        If WorldData.Place <= 9 Then Put (Ico , Jco ), grass1, Pset
        Put (Ico , Jco ), Man05m, And
        Put (Ico , Jco ), Man05, Or
    Case 95
        Put (Ico , Jco ), path03, Pset
        Put (Ico , Jco ), Man01m, And
        Put (Ico , Jco ), Man04, Or
    Case 86, 102, 110
        If WorldData.Place >= 10 Then Put (Ico , Jco ), grass2, Pset
        If WorldData.Place <= 9 Then Put (Ico , Jco ), grass1, Pset
        Put (Ico , Jco ), Man01m, And
        Put (Ico , Jco ), Man04, Or
    Case 87, 91, 96, 101
        If WorldData.Place >= 10 Then Put (Ico , Jco ), grass2, Pset
        If WorldData.Place <= 9 Then Put (Ico , Jco ), grass1, Pset
        Put (Ico , Jco ), Man01m, And
        Put (Ico , Jco ), Man03, Or
    Case 88
        If WorldData.Place >= 10 Then Put (Ico , Jco ), grass2, Pset
        If WorldData.Place <= 9 Then Put (Ico , Jco ), grass1, Pset
        Put (Ico , Jco ), Man01m, And
        Put (Ico , Jco ), Man02, Or
    Case 107
        If WorldData.Place >= 10 Then Put (Ico , Jco ), grass2, Pset
        If WorldData.Place <= 9 Then Put (Ico , Jco ), grass1, Pset
        Put (Ico , Jco ), Man01m, And
        Put (Ico , Jco ), Man02, Or
    Case 56
        Put (Ico , Jco ), Lich, Pset
    Case 57
        Put (Ico , Jco ), path03, Pset
        Put (Ico , Jco ), Bhaulx, Trans
    Case 89, 90, 97, 99, 100
        If WorldData.Place >= 10 Then Put (Ico , Jco ), grass2, Pset
        If WorldData.Place <= 9 Then Put (Ico , Jco ), grass1, Pset
        Put (Ico , Jco ), Man01m, And
        Put (Ico , Jco ), Man01, Or
    Case 43
        Put (Ico , Jco ), AshyGround, Pset
    Case 44
        Put (Ico , Jco ), EmberPile, Pset
    Case 45
        Put (Ico , Jco ), GraveMound, Pset
    Case 46
        Put (Ico , Jco ), Tombstone, Pset
    Case 47
        Put (Ico , Jco ), Tombstone2, Pset
    Case 50
        Put (Ico , Jco ), IronFence, Pset
    Case 51
        Put (Ico , Jco ), WoodenFence, Pset
    Case Else
        Put (Ico , Jco), black, Pset
        
        
    End Select
    
End Sub

'-------------------------------------------
Sub quit
    dim a$
    box(80, 20, 270, 110)
    TEXT "Quit to title?", 14, 108, 30, 1
    TEXT "S = Save and Quit", 15, 95, 50, 1
    TEXT "Q = Quit, no save", 15, 95, 62, 1
    TEXT "C = Cancel", 15, 95, 74, 1
    Do
        a$ = UCase$(INKEY$)
        LoopMidi
    Loop Until a$ = "S" Or a$ = "Q" Or a$ = "C"
    
    If a$ = "C" Then ShowMap: Menu1: Exit Sub
    
    If a$ = "S" Then
        If WorldData.Inside = 1 Then
            Open "save.dat" For Output As #1
            Write #1, chrname, WorldData.Place, WorldData.TopCol, WorldData.TopRow, Hp, MaxHp, gold%, Fpot, SPot, PHerb, AHerb, Poisoned, Runa, Wep$, WepB, Arm$, ArmB, ItemWepB, ItemArmB, O1, O2, O3, O4, O5, Q1, Q2, Q3, Q4, Q5, kills, Level, PlayerExp, Trophies, Fish, RareFish, DeathQ, OwnWep2, OwnWep3, OwnWep4, OwnWep6, OwnArm2, OwnArm3, OwnArm4, OwnArm6
            Close #1
            Dim bi As Integer
            Open "beast.dat" For Output As #2
            For bi = 1 To 60: Write #2, Bestiary(bi): Next
            Close #2
            Dim As Integer fgZ, fgX, fgY
            Dim fgS As String
            Open "fog.dat" For Output As #3
            For fgZ = 1 To 4
                fgS = ""
                For fgY = -9 To 67
                    For fgX = -9 To 67
                        fgS = fgS + Chr$(48 + Fog(fgZ, fgX, fgY))
                    Next
                Next
                Write #3, fgS
            Next
            Close #3
            box(80, 20, 270, 60): TEXT "Game Saved!", 15, 120, 34, 1: waitkey
        Else
            box(80, 20, 270, 60): TEXT "Can only save inside - quitting.", 12, 84, 34, 1: waitkey
        End If
    End If
    
    Begin
End Sub


'-------------------------------------------
' One-time setup of the level curve. Cumulative XP needed to REACH each level.
' Tune pacing by hand here - not a formula, so any level can be sped up/slowed down.
Sub SetupLevels
    LvlXP(1)  = 0      ' start
    LvlXP(2)  = 20
    LvlXP(3)  = 50
    LvlXP(4)  = 90
    LvlXP(5)  = 140
    LvlXP(6)  = 200
    LvlXP(7)  = 270
    LvlXP(8)  = 350
    LvlXP(9)  = 440
    LvlXP(10) = 540
    LvlXP(11) = 650
    LvlXP(12) = 770
    LvlXP(13) = 900
    LvlXP(14) = 1040
    LvlXP(15) = 1190
    LvlXP(16) = 1350
    LvlXP(17) = 1520
    LvlXP(18) = 1700
    LvlXP(19) = 1890
    LvlXP(20) = 2090
End Sub

'-------------------------------------------
' Call after any PlayerExp gain. Handles multiple level-ups in one call (e.g. big kill).
Sub CheckLevelUp
    Do While Level < 20 And PlayerExp >= LvlXP(Level + 1)
        Level = Level + 1
        MaxHp = MaxHp + 5
        Hp = Hp + 5
        If Hp > MaxHp Then Hp = MaxHp

        Cls
        ' Must set NewMidi too — waitkey/LoopMidi calls MusicUpdate, which
        ' would immediately switch back to town/dungeon if NewMidi is still 1/2.
        NewMidi = 5
        PlayTrack(5)
        CurMidi = 5
        For n as integer = 1 To 15
            Line (n, n)-(319 - n, 199 - n), 16 + (n Mod 15), B
        Next n
        TEXT "LEVEL UP!", 14, 120, 80, 1
        TEXT "You are now Level " + Fixed$(Level), 15, 95, 100, 1
        TEXT "Max HP +5   Attack +1   Defense +1", 15, 70, 115, 1
        waitkey
        NewMidi = -1
        CurMidi = -1
        ShowMap
    Loop
End Sub

'-------------------------------------------
Sub SetupPalette
    dim as integer i
    
    Bload "nmedia.pal", varptr(Pal(0,0))
    For i = 0 To 255
        Palette i, Pal(i, 0) Shl 2, Pal(i, 1) Shl 2, Pal(i, 2) Shl 2
    Next
    
End Sub

'-------------------------------------------
Sub Shopkeeper
    ' Unified town shopkeeper: routes to the existing weapon/armor/potion
    ' shop menus. Opened by any clerk (tile 29) or desk (tile 30), so it
    ' works in every interior regardless of Place.
    ShopMenu:
    box(40, 20, 260, 190)
    TEXT " Gold:" + Fixed$(gold%), 14, 43, 130, 1
    TEXT " Welcome, traveler.", 2, 43, 30, 1
    TEXT " What are you after?", 15, 43, 44, 1
    TEXT " A) Weapons", 15, 43, 62, 1
    TEXT " B) Armor", 15, 43, 74, 1
    TEXT " C) Potions", 15, 43, 86, 1
    TEXT " D) Leave", 15, 43, 98, 1
    Do
        LoopMidi
        kbd$ = INKEY$
        If kbd$ = "A" Or kbd$ = "a" Then Shop2: Goto ShopMenu
        If kbd$ = "B" Or kbd$ = "b" Then Shop3: Goto ShopMenu
        If kbd$ = "C" Or kbd$ = "c" Then Shop1: Goto ShopMenu
        If kbd$ = "D" Or kbd$ = "d" Then Exit Sub
    Loop
End Sub

Sub Shop1
    Dim sel As Integer
    sel = 1
    Buy:
    box(40, 20, 260, 190)
    TEXT " Gold:" + Fixed$(gold%), 14, 43, 130, 1
    TEXT "Large Heal        -50 gold", IIf(sel = 1, 14, 15), 55, 30, 1
    TEXT "Small Heal        -10 gold", IIf(sel = 2, 14, 15), 55, 40, 1
    TEXT "Poison Antidote   -20 gold", IIf(sel = 3, 14, 15), 55, 50, 1
    TEXT "Agility Potion    -25 gold", IIf(sel = 4, 14, 15), 55, 60, 1
    TEXT "Sell loot", IIf(sel = 5, 14, 15), 55, 70, 1
    TEXT "Leave", IIf(sel = 6, 14, 15), 55, 80, 1
    TEXT ">", 14, 45, 20 + sel * 10, 1
    Do
        LoopMidi
        kbd$ = INKEY$
        If kbd$ = CHR$(255) + CHR$(72) Then
            sel = sel - 1: If sel < 1 Then sel = 6
            Goto Buy
        End If
        If kbd$ = CHR$(255) + CHR$(80) Then
            sel = sel + 1: If sel > 6 Then sel = 1
            Goto Buy
        End If
        If kbd$ = CHR$(13) Then
            Select Case sel
            Case 1
                If gold% < 50 Then TEXT " Not Enough Money ", 15, 43, 92, 1: waitkey: Goto Buy
                Fpot = Fpot + 1: gold% = gold% - 50: TEXT " You Bought a Large Heal", 15, 43, 92, 1
                waitkey: Goto Buy
            Case 2
                If gold% < 10 Then TEXT " Not Enough Money ", 15, 43, 92, 1: waitkey: Goto Buy
                SPot = SPot + 1: gold% = gold% - 10: TEXT " You Bought a Small Heal", 15, 43, 92, 1
                waitkey: Goto Buy
            Case 3
                If gold% < 20 Then TEXT " Not Enough Money ", 15, 43, 92, 1: waitkey: Goto Buy
                PHerb = PHerb + 1: gold% = gold% - 20: TEXT " You Bought a Poison Antidote", 15, 43, 92, 1
                waitkey: Goto Buy
            Case 4
                If gold% < 25 Then TEXT " Not Enough Money ", 15, 43, 92, 1: waitkey: Goto Buy
                AHerb = AHerb + 1: gold% = gold% - 25: TEXT " You Bought a Agility Potion", 15, 43, 92, 1
                waitkey: Goto Buy
            Case 5
                If BrokenDagger * 3 + BustedArmor * 5 + Trophies * 3 + Fish * 1 + RareFish * 5 = 0 Then
                    TEXT " You have nothing to sell ", 15, 43, 92, 1
                Else
                    gold% = gold% + BrokenDagger * 3 + BustedArmor * 5 + Trophies * 3 + Fish * 1 + RareFish * 5
                    BrokenDagger = 0: BustedArmor = 0: Trophies = 0: Fish = 0: RareFish = 0
                    TEXT " Sold your loot ", 15, 43, 92, 1
                End If
                waitkey: Goto Buy
            Case 6
                Exit Sub
            End Select
        End If
    Loop
End Sub

Sub Shop2
    Dim sel As Integer
    sel = 1
    Buy2:
    box(40, 20, 260, 190)
    TEXT " Gold:" + Fixed$(gold%), 14, 43, 130, 1
    TEXT "Broad Sword  (+2)   -200 gold", IIf(sel = 1, 14, 15), 55, 30, 1
    TEXT "Long Sword   (+3)   -400 gold", IIf(sel = 2, 14, 15), 55, 40, 1
    TEXT "Battle Axe   (+4)   -500 gold", IIf(sel = 3, 14, 15), 55, 50, 1
    TEXT "Jeweled Scimitar(+6)-1000 gold", IIf(sel = 4, 14, 15), 55, 60, 1
    TEXT "Sell Weapon", IIf(sel = 5, 14, 15), 55, 70, 1
    TEXT "Sell loot", IIf(sel = 6, 14, 15), 55, 80, 1
    TEXT "Leave", IIf(sel = 7, 14, 15), 55, 90, 1
    TEXT ">", 14, 45, 20 + sel * 10, 1
    Do
        LoopMidi
        kbd$ = INKEY$
        If kbd$ = CHR$(255) + CHR$(72) Then
            sel = sel - 1: If sel < 1 Then sel = 7
            Goto Buy2
        End If
        If kbd$ = CHR$(255) + CHR$(80) Then
            sel = sel + 1: If sel > 7 Then sel = 1
            Goto Buy2
        End If
        If kbd$ = CHR$(13) Then
            Select Case sel
            Case 1
                If gold% < 200 Then TEXT " Not Enough Money ", 15, 43, 110, 1: waitkey: Goto Buy2
                Wep$ = "Broad Sword": WepB = 2: OwnWep2 = 1: gold% = gold% - 200: TEXT " You Bought a Broad Sword", 15, 43, 110, 1
                waitkey: Goto Buy2
            Case 2
                If gold% < 400 Then TEXT " Not Enough Money ", 15, 43, 110, 1: waitkey: Goto Buy2
                Wep$ = "Long Sword": WepB = 3: OwnWep3 = 1: gold% = gold% - 400: TEXT " You Bought a Long Sword", 15, 43, 110, 1
                waitkey: Goto Buy2
            Case 3
                If gold% < 500 Then TEXT " Not Enough Money ", 15, 43, 110, 1: waitkey: Goto Buy2
                Wep$ = "Battle Axe": WepB = 4: OwnWep4 = 1: gold% = gold% - 500: TEXT " You Bought a Battle Axe", 15, 43, 110, 1
                waitkey: Goto Buy2
            Case 4
                If gold% < 1000 Then TEXT " Not Enough Money ", 15, 43, 110, 1: waitkey: Goto Buy2
                Wep$ = "Jeweled Scimitar": WepB = 6: OwnWep6 = 1: gold% = gold% - 1000: TEXT " You Bought a Jeweled Scimitar", 15, 43, 110, 1
                waitkey: Goto Buy2
            Case 5
                SellWeapon
                Goto Buy2
            Case 6
                If BrokenDagger * 3 + BustedArmor * 5 + Trophies * 3 + Fish * 1 + RareFish * 5 = 0 Then
                    TEXT " You have nothing to sell ", 15, 43, 110, 1
                Else
                    gold% = gold% + BrokenDagger * 3 + BustedArmor * 5 + Trophies * 3 + Fish * 1 + RareFish * 5
                    BrokenDagger = 0: BustedArmor = 0: Trophies = 0: Fish = 0: RareFish = 0
                    TEXT " Sold your loot ", 15, 43, 110, 1
                End If
                waitkey: Goto Buy2
            Case 7
                Exit Sub
            End Select
        End If
    Loop
End Sub

Sub Shop3
    Dim sel As Integer
    sel = 1
    Buy3:
    box(40, 20, 260, 190)
    TEXT " Gold:" + Fixed$(gold%), 14, 43, 130, 1
    TEXT "Leather Armor(+2)   -150 gold", IIf(sel = 1, 14, 15), 55, 30, 1
    TEXT "Chain Mail   (+3)   -350 gold", IIf(sel = 2, 14, 15), 55, 40, 1
    TEXT "Plate Mail   (+4)   -450 gold", IIf(sel = 3, 14, 15), 55, 50, 1
    TEXT "Jeweled Armor(+6)   -900 gold", IIf(sel = 4, 14, 15), 55, 60, 1
    TEXT "Sell Armor", IIf(sel = 5, 14, 15), 55, 70, 1
    TEXT "Sell loot", IIf(sel = 6, 14, 15), 55, 80, 1
    TEXT "Leave", IIf(sel = 7, 14, 15), 55, 90, 1
    TEXT ">", 14, 45, 20 + sel * 10, 1
    Do
        LoopMidi
        kbd$ = INKEY$
        If kbd$ = CHR$(255) + CHR$(72) Then
            sel = sel - 1: If sel < 1 Then sel = 7
            Goto Buy3
        End If
        If kbd$ = CHR$(255) + CHR$(80) Then
            sel = sel + 1: If sel > 7 Then sel = 1
            Goto Buy3
        End If
        If kbd$ = CHR$(13) Then
            Select Case sel
            Case 1
                If gold% < 150 Then TEXT " Not Enough Money ", 15, 43, 110, 1: waitkey: Goto Buy3
                Arm$ = "Leather Armor": ArmB = 2: OwnArm2 = 1: gold% = gold% - 150: TEXT " You Bought a Leather Armor", 15, 43, 110, 1
                waitkey: Goto Buy3
            Case 2
                If gold% < 350 Then TEXT " Not Enough Money ", 15, 43, 110, 1: waitkey: Goto Buy3
                Arm$ = "Chain Mail": ArmB = 3: OwnArm3 = 1: gold% = gold% - 350: TEXT " You Bought a Chain Mail", 15, 43, 110, 1
                waitkey: Goto Buy3
            Case 3
                If gold% < 450 Then TEXT " Not Enough Money ", 15, 43, 110, 1: waitkey: Goto Buy3
                Arm$ = "Plate Mail": ArmB = 4: OwnArm4 = 1: gold% = gold% - 450: TEXT " You Bought a Plate Mail", 15, 43, 110, 1
                waitkey: Goto Buy3
            Case 4
                If gold% < 900 Then TEXT " Not Enough Money ", 15, 43, 110, 1: waitkey: Goto Buy3
                Arm$ = "Jeweled Armor": ArmB = 6: OwnArm6 = 1: gold% = gold% - 900: TEXT " You Bought a Jeweled Armor", 15, 43, 110, 1
                waitkey: Goto Buy3
            Case 5
                SellArmor
                Goto Buy3
            Case 6
                If BrokenDagger * 3 + BustedArmor * 5 + Trophies * 3 + Fish * 1 + RareFish * 5 = 0 Then
                    TEXT " You have nothing to sell ", 15, 43, 110, 1
                Else
                    gold% = gold% + BrokenDagger * 3 + BustedArmor * 5 + Trophies * 3 + Fish * 1 + RareFish * 5
                    BrokenDagger = 0: BustedArmor = 0: Trophies = 0: Fish = 0: RareFish = 0
                    TEXT " Sold your loot ", 15, 43, 110, 1
                End If
                waitkey: Goto Buy3
            Case 7
                Exit Sub
            End Select
        End If
    Loop
End Sub

Sub Shop4
    Dim sel As Integer
    sel = 1
    InnMenu:
    box(40, 20, 260, 190)
    TEXT " Gold:" + Fixed$(gold%), 14, 43, 130, 1
    TEXT "       The Fuzzy Newt Inn", 2, 43, 30, 1
    TEXT " A warm bed restores you fully.", 15, 43, 48, 1
    TEXT "Stay the night  -30 gold", IIf(sel = 1, 14, 15), 55, 65, 1
    TEXT "Leave", IIf(sel = 2, 14, 15), 55, 78, 1
    TEXT ">", 14, 45, 52 + sel * 13, 1
    Do
        LoopMidi
        kbd$ = INKEY$
        If kbd$ = CHR$(255) + CHR$(72) Then
            sel = sel - 1: If sel < 1 Then sel = 2
            Goto InnMenu
        End If
        If kbd$ = CHR$(255) + CHR$(80) Then
            sel = sel + 1: If sel > 2 Then sel = 1
            Goto InnMenu
        End If
        If kbd$ = CHR$(13) Then
            If sel = 1 Then
                If gold% < 30 Then TEXT "Sorry, not enough Gold!", 15, 43, 92, 1: waitkey: Exit Sub
                TEXT "Thank's. Enjoy your sleep.", 15, 43, 92, 1
                Hp = MaxHp: Poisoned = 0
                gold% = gold% - 30
                waitkey
                Exit Sub
            End If
            If sel = 2 Then Exit Sub
        End If
    Loop
End Sub

'-------------------------------------------
Sub FightThrollux
    Dim As Integer thp, dmg, edmg
    Dim k$
    thp = 450
    NewMidi = 4                          ' Boss - same Bhaulx theme as Etheros
    Do
        Cls
        box(10, 8, 310, 58)
        TEXT "THROLLUX, TEMPLE TYRANT", 4, 80, 16, 1
        TEXT "HP: " + Fixed$(thp) + " / 450", 15, 20, 32, 1
        Line (20, 44)-(300, 50), 172, B
        If thp > 0 Then Line (21, 45)-(21 + Int((thp / 450) * 278), 49), 4, BF
        box(10, 147, 310, 197)
        TEXT "Your HP: " + Fixed$(Hp) + " / " + Fixed$(MaxHp), 14, 20, 155, 1
        TEXT "A) Attack", 14, 20, 172, 1
        TEXT "B) Item", 14, 140, 172, 1
        Do
            k$ = INKEY$: LoopMidi
        Loop Until k$ <> ""
        box(10, 60, 310, 145)
        If k$ = "B" Or k$ = "b" Then
            MenuItems
            Continue Do
        End If
        If k$ = "A" Or k$ = "a" Then
            dmg = Int(Rnd * 10 + Rnd * WepB + ItemWepB + (Level - 1)) + 5
            thp = thp - dmg
            TEXT "You strike Throllux for " + Fixed$(dmg) + "!", 15, 20, 80, 1
            waitkey
            If thp <= 0 Then GoTo ThrolluxWin
        End If
        ThrolluxTurn:
        If thp >= 1 Then
            box(10, 60, 310, 145)
            edmg = Int(Rnd * 25) + 12 - Int(Rnd * (ArmB + ItemArmB + 1))
            If edmg < 1 Then edmg = 1
            Hp = Hp - edmg
            TEXT "Throllux rakes you with black claws!", 4, 20, 80, 1
            TEXT "You take " + Fixed$(edmg) + " damage!", 15, 20, 96, 1
            waitkey
            If Hp <= 0 Then GoTo ThrolluxLose
        End If
    Loop
    ThrolluxWin:
    Cls
    box(20, 65, 300, 135)
    TEXT "Throllux collapses with an earth-", 15, 35, 82, 1
    TEXT "shaking roar and moves no more.", 15, 35, 96, 1
    TEXT "Return to Balthix to claim your due.", 14, 35, 112, 1
    waitkey
    DeathQ = 1
    Cls
    ShowMap
    Exit Sub
    ThrolluxLose:
    Cls
    box(20, 75, 300, 125)
    TEXT "Throllux's jaws close around you.", 4, 35, 92, 1
    TEXT "The temple keeps its secret...", 15, 35, 106, 1
    waitkey
    Exit Sub
End Sub

'-------------------------------------------
Sub FightEtheros
    Dim As Integer ehp, dmg, edmg, yy, db, hl
    Dim k$
    ehp = 800
    NewMidi = 4                          ' Boss - Bhaulx theme (shared with Throllux)
    Do
        Cls
        box(10, 8, 310, 58)
        TEXT "ETHEROS, THE CORRUPTOR", 4, 85, 16, 1
        TEXT "HP: " + Fixed$(ehp) + " / 800", 15, 20, 32, 1
        Line (20, 44)-(300, 50), 172, B
        If ehp > 0 Then Line (21, 45)-(21 + Int((ehp / 800) * 278), 49), 4, BF
        box(10, 147, 310, 197)
        TEXT "Your HP: " + Fixed$(Hp) + " / " + Fixed$(MaxHp), 14, 20, 155, 1
        TEXT "A) Attack", 14, 20, 172, 1
        TEXT "B) Item", 14, 140, 172, 1
        Do
            k$ = INKEY$: LoopMidi
        Loop Until k$ <> ""
        box(10, 60, 310, 145)
        If k$ = "B" Or k$ = "b" Then
            MenuItems
            Continue Do
        End If
        If k$ = "A" Or k$ = "a" Then
            yy = 66
            dmg = Int(Rnd * 10 + Rnd * WepB + ItemWepB + (Level - 1)) + 5
            ehp = ehp - dmg
            TEXT "You strike Etheros for " + Fixed$(dmg) + "!", 15, 20, yy, 1: yy = yy + 12
            If O1 = 1 Then ehp = ehp - 100: TEXT "The Sun-Winged Aegis blazes, blinding him!", 14, 20, yy, 1: yy = yy + 12
            If O2 = 1 Then ehp = ehp - 100: TEXT "The Aquamarine of Ran drowns him in holy tide!", 9, 20, yy, 1: yy = yy + 12
            If O3 = 1 Then ehp = ehp - 100: TEXT "The Root-Bound Ring binds him in living roots!", 10, 20, yy, 1: yy = yy + 12
            If O4 = 1 Then ehp = ehp - 100: TEXT "The Eye of Foresight sears through his shadow!", 11, 20, yy, 1: yy = yy + 12
            If O5 = 1 Then ehp = ehp - 100: TEXT "Orm's Seventh Eye sears away his dark form!", 12, 20, yy, 1: yy = yy + 12
            If Wep$ = "Deathbane" Then
                db = Int(Rnd * 6) + 1: ehp = ehp - db
                hl = Int(Rnd * 6) + 1: Hp = Hp + hl
                If Hp > MaxHp Then Hp = MaxHp
                TEXT "Deathbane drinks his unlife! +" + Fixed$(db) + " dmg / +" + Fixed$(hl) + " hp", 12, 20, yy, 1
                yy = yy + 12
            End If
            waitkey
            If ehp <= 0 Then GoTo BossWin
        End If
        EtherosTurn:
        If ehp >= 1 Then
            box(10, 60, 310, 145)
            edmg = Int(Rnd * 30) + 20 - Int(Rnd * (ArmB + ItemArmB + 1))
            If edmg < 1 Then edmg = 1
            Hp = Hp - edmg
            TEXT "Etheros unleashes a wave of shadow-fire!", 4, 20, 80, 1
            TEXT "You take " + Fixed$(edmg) + " damage!", 15, 20, 96, 1
            waitkey
            If Hp <= 0 Then GoTo BossLose
        End If
    Loop
    BossWin:
    Cls
    box(20, 65, 300, 135)
    TEXT "Etheros lets out a final, hollow wail", 15, 35, 82, 1
    TEXT "as his dark form crumbles to ash.", 15, 35, 96, 1
    TEXT "The shadow lifts from Araxia...", 14, 35, 112, 1
    waitkey
    NpcTalk("endgame.npc")
    O5 = 3
    Exit Sub
    BossLose:
    Cls
    box(20, 75, 300, 125)
    TEXT "Etheros's shadow swallows you whole.", 4, 35, 92, 1
    TEXT "Darkness spreads across Araxia...", 15, 35, 106, 1
    waitkey
    Exit Sub
End Sub

'-------------------------------------------
Sub GoFishing
    Dim As Integer sel, roll, amt
    Dim msg$
    sel = 1
    FishMenu:
    box(46, 60, 274, 120)
    TEXT "The water looks calm...", 15, 54, 68, 1
    TEXT "Fish", IIf(sel = 1, 14, 15), 62, 88, 1
    TEXT "Nothing", IIf(sel = 2, 14, 15), 62, 100, 1
    TEXT ">", 14, 52, 76 + sel * 12, 1
    Do
        LoopMidi
        kbd$ = INKEY$
        If kbd$ = CHR$(255) + CHR$(72) Then
            sel = sel - 1: If sel < 1 Then sel = 2
            Goto FishMenu
        End If
        If kbd$ = CHR$(255) + CHR$(80) Then
            sel = sel + 1: If sel > 2 Then sel = 1
            Goto FishMenu
        End If
        If kbd$ = CHR$(27) Then Exit Sub
        If kbd$ = CHR$(13) Then
            If sel = 2 Then Exit Sub
            roll = Int(Rnd * 100)
            If roll < 50 Then
                Fish = Fish + 1
                msg$ = "You caught a fish!"
            ElseIf roll < 60 Then
                RareFish = RareFish + 1
                msg$ = "A rare fish!"
            ElseIf roll < 65 Then
                amt = Int(Rnd * 41) + 10
                gold% = gold% + amt
                msg$ = "A bag of coins!  +" + Fixed$(amt) + " gold."
            Else
                msg$ = "The fish got away..."
            End If
            box(46, 60, 274, 120)
            TEXT "You cast your line...", 15, 54, 78, 1
            TEXT msg$, 14, 54, 94, 1
            Do: LoopMidi: Loop Until INKEY$ <> ""
            Exit Sub
        End If
    Loop
End Sub

' Fog-of-war zones: 1=Caves(3) 2=EversmokeWoods1(10) 3=EversmokeWoods2(11) 4=ThrolluxTemple(14)
' Everywhere else (towns, Lighthouse, YsirasRest, Balthix, Cemetary, Gate, Lair) = 0 = no fog
Function FogZone (ByVal p As Integer) As Integer
    Select Case p
    Case 3:  FogZone = 1
    Case 10: FogZone = 2
    Case 11: FogZone = 3
    Case 14: FogZone = 4
    Case Else: FogZone = 0
    End Select
End Function

'-------------------------------------------
Sub InitMiniColors
    ' mini-map colours matched to NMEDIA.PAL: grass 73, water 171, tree 70,
    ' path 184, wall 26, roof 243, rock 24. -1 = fall back to walkable/wall.
    Dim As Integer i
    For i = -9 To 120: TileColor(i) = -1: Next
    TileColor(0) = 0
    TileColor(-1) = 171
    TileColor(-2) = 70: TileColor(-3) = 70: TileColor(-6) = 70: TileColor(-7) = 70: TileColor(4) = 70
    TileColor(1) = 73: TileColor(2) = 73: TileColor(31) = 73: TileColor(32) = 73
    For i = 82 To 110: TileColor(i) = 73: Next
    TileColor(3) = 184: TileColor(5) = 184: TileColor(6) = 184
    For i = 68 To 81: TileColor(i) = 184: Next
    TileColor(94) = 184: TileColor(98) = 184: TileColor(108) = 184
    TileColor(10) = 26: TileColor(11) = 26: TileColor(15) = 26
    TileColor(20) = 26: TileColor(21) = 26: TileColor(23) = 26
    TileColor(12) = 243
    TileColor(7) = 24: TileColor(8) = 24: TileColor(105) = 24
    TileColor(46) = 24
End Sub

'-------------------------------------------
Sub ShowMap
    'dim as integer i, j
    ' 
    ' For i = 0 To 15
    '     For j = 0 To 9
    '         PutTile i, j, map(i + WorldData.TopCol, j + WorldData.TopRow).Tile
    '     Next j
    ' Next i
    ' 
    ' putPlayerPic
    
    dim as integer x, y, i
    dim as integer ShowX, ShowY, MapX, MapY, ScrollX, ScrollY, PutX, PutY
    dim as integer MaxX, MaxY, TileNr
    
    
    ShowX = (((WorldData.TopCol+7) * 20) + SX) - 160
    IF ShowX < 0 THEN ShowX = 0
    IF ShowX > (((WorldData.Cols) * 20) - 320) THEN ShowX = ((WorldData.Cols) * 20) - 320
    
    ShowY = (((WorldData.TopRow+4 ) * 20) + SY) - 100
    IF ShowY < 0 THEN ShowY = 0
    IF ShowY > (((WorldData.Rows) * 20) - 200) THEN ShowY = ((WorldData.Rows) * 20) - 200
    
    MapX = (ShowX \ 20) + 1
    MapY = (ShowY \ 20) + 1
    
    ScrollX = -(ShowX MOD 20)
    ScrollY = -(ShowY MOD 20)
    
    IF ScrollX THEN MaxX = 16 ELSE MaxX = 15
    IF ScrollY THEN MaxY = 10 ELSE MaxY = 9
    
    
    putY = scrolly
    FOR y = 0 TO MaxY
        putX = scrollx
        FOR x = 0 TO MaxX
            
            TileNr = Map(MapX + x, MapY + y).Tile
            if TileNr <> 12 then PUTTile putX, putY, TileNr
            putX = putX + 20
        NEXT
        putY = putY + 20
    NEXT
    
    
    put ((((WorldData.TopCol+7) * 20) + SX) - ShowX, (((WorldData.TopRow+4) * 20) + SY) - ShowY), HeroImg(Player.Dir, Player.Frame, 0), TRANS
    
    putY = scrolly
    FOR y = 0 TO MaxY
        putX = scrollx
        FOR x = 0 TO MaxX
            
            TileNr = Map(MapX + x, MapY + y).Tile
            if TileNr = 12 then PUTTile putX, putY, TileNr
            putX = putX + 20
        NEXT
        putY = putY + 20
    NEXT
    
    ' --- mini-map overlay (top-right corner) ---
    Dim As Integer mmw, mmh, mmx, mmy, mc, mr, pcx, pcy, mt, mcol, dd, fz, rx, ry
    If WorldData.Cols > 0 And WorldData.Rows > 0 And MiniTrans < 4 Then
        mmw = WorldData.Cols: If mmw > 62 Then mmw = 62
        mmh = WorldData.Rows: If mmh > 40 Then mmh = 40
        mmx = 317 - mmw
        mmy = 2
        fz = FogZone(WorldData.Place)
        If fz > 0 Then
            pcx = WorldData.TopCol + 8: pcy = WorldData.TopRow + 5
            For ry = pcy - 2 To pcy + 2
                For rx = pcx - 2 To pcx + 2
                    If rx >= -9 And rx <= 67 And ry >= -9 And ry <= 67 Then Fog(fz, rx, ry) = 1
                Next
            Next
        End If
        If MiniTrans = 0 Then Line (mmx - 1, mmy - 1)-(mmx + mmw, mmy + mmh), 0, BF
        Line (mmx - 1, mmy - 1)-(mmx + mmw, mmy + mmh), 8, B
        For mr = 1 To mmh
            For mc = 1 To mmw
                If fz > 0 And Fog(fz, mc, mr) = 0 Then
                    mcol = 0
                Else
                    mt = Map(mc, mr).Tile
                    If mt >= -9 And mt <= 120 Then mcol = TileColor(mt) Else mcol = -1
                    If mcol < 0 Then
                        If Map(mc, mr).Walkon Then mcol = 7 Else mcol = 8
                    End If
                End If
                dd = 0
                If MiniTrans = 0 Then dd = 1
                If MiniTrans = 1 And (mc + mr) Mod 4 <> 0 Then dd = 1
                If MiniTrans = 2 And (mc + mr) Mod 2 = 0 Then dd = 1
                If MiniTrans = 3 And (mc + mr) Mod 4 = 0 Then dd = 1
                If dd = 1 Then PSet (mmx + mc - 1, mmy + mr - 1), mcol
            Next
        Next
        pcx = WorldData.TopCol + 8: If pcx < 1 Then pcx = 1
        If pcx > mmw Then pcx = mmw
        pcy = WorldData.TopRow + 5: If pcy < 1 Then pcy = 1
        If pcy > mmh Then pcy = mmh
        PSet (mmx + pcx - 1, mmy + pcy - 1), 14
    End If
    'Music + scaled frame presentation (60 fps)
    PresentFrame
    MusicUpdate
End Sub


'-------------------------------------------
Sub Story
    dim as integer x, y
    
    Cls
    For X = 0 To 319 Step 20
        For y = 0 To 199 Step 20
            Put (X, y), wall01, Pset
        Next
    Next
    
    TEXT "Araxia", 15, 32, 2, 2
    TEXT "Shadow of Etheros", 15, 140, 10, 1
    
    NewMidi = 3
    NpcTalk("intro.npc")
End Sub

'-------------------------------------------
Sub TEXT (a$, C as integer, XCoordinate as integer, YCoordinate as integer, Size as integer)  
    dim as integer StartX, e, ascnr, x, y, col, PixelsRight
    dim b$
    
    Size = Int(Size)             'No decimals allowed!
    If Size > 10 Then Size = 10  'Check and fix invalid size calls
    If Size < 1 Then Size = 1    'likewise for <.
    
    YCoordinate = Int(YCoordinate / Size)     'Prevent ballooning of YCoordinates
    'that is a result of using
    'size values larger than 1 for size
    
    
    If XCoordinate = 999 Then XCoordinate = 160 - (Len(a$) * 3 * Size)
    
    StartX = XCoordinate               'set Starting X-Val for character drawing
    
    For e = 1 To Len(a$)
        
        B$ = MID$(a$, e, 1)     ' read each character of the string
        ascnr = Asc(B$)             ' get ASCII values of each character
        
        For X = 1 To 8
            
            For y = 1 To 6
                
                Select Case CharSet(ascnr, X, y)       'use ASCII value (a) to point
                    'to the correct element in
                    'the array
                    
                Case 0: col = 0                 ' Don't draw pixel
                    
                Case 1: col = C                 ' Draw pixel
                    
                Case Else: col = 0              ' Bad font data - skip pixel
                    
                End Select
                
                If col <> 0 Then        'Draw a pixel!
                    Line (StartX + PixelsRight, (X + YCoordinate) * Size)-(StartX + PixelsRight + (Size - 1), ((X + YCoordinate) * Size) + (Size - 1)), col, BF
                End If
                
                StartX = StartX + Size     'Set starting X-value for next pixel
                
            Next y
            
            StartX = XCoordinate          'reset startx for next line of pixels
            
        Next X
        PixelsRight = PixelsRight + (6 * Size)   ' add pixels for next character
        
    Next e
    
    
End Sub


'-------------------------------------------
Sub waitkey
    Do
        LoopMidi
    Loop Until INKEY$ <> ""
End Sub

'-------------------------------------------
Sub WhatsUp (FileName$)
    
    NpcFile$ = " "
    If WorldData.NPC = 24 Then SearchBarrel: Exit Sub
    ' Position-based dialogue override (from the .npcs companion file).
    ' Item/quest-giver tiles (94-99) must reach their hardcoded logic below,
    ' so the relic is granted - skip the override for those tiles.
    ' --- Gate of Relics: five wardens, each yields to one relic ---
    If WorldData.Place = 19 Then
        If WorldData.NPCcol = 11 And WorldData.NPCrow = 15 Then
            If O1 = 1 Then
                NpcTalk("gatepass.npc")
                map(11, 15).Tile = 6: map(11, 15).Walkon = true
            Else
                NpcTalk("gate1.npc")
            End If
            Exit Sub
        End If
        If WorldData.NPCcol = 10 And WorldData.NPCrow = 12 Then
            If O2 = 1 Then
                NpcTalk("gatepass.npc")
                map(10, 12).Tile = 6: map(10, 12).Walkon = true
            Else
                NpcTalk("gate2.npc")
            End If
            Exit Sub
        End If
        If WorldData.NPCcol = 11 And WorldData.NPCrow = 9 Then
            If O3 = 1 Then
                NpcTalk("gatepass.npc")
                map(11, 9).Tile = 6: map(11, 9).Walkon = true
            Else
                NpcTalk("gate3.npc")
            End If
            Exit Sub
        End If
        If WorldData.NPCcol = 10 And WorldData.NPCrow = 6 Then
            If O4 = 1 Then
                NpcTalk("gatepass.npc")
                map(10, 6).Tile = 6: map(10, 6).Walkon = true
            Else
                NpcTalk("gate4.npc")
            End If
            Exit Sub
        End If
        If WorldData.NPCcol = 11 And WorldData.NPCrow = 3 Then
            If O5 = 1 Then
                NpcTalk("gatepass.npc")
                map(11, 3).Tile = 6: map(11, 3).Walkon = true
            Else
                NpcTalk("gate5.npc")
            End If
            Exit Sub
        End If
    End If
    Dim ov$
    Dim shopdone As Integer
    ' BNPC02 (Balthix, grid 20,28) - Deathbane quest turn-in
    If WorldData.Place = 12 And WorldData.NPCcol = 20 And WorldData.NPCrow = 28 Then
        If DeathQ = 1 Then NpcTalk("deathbane.npc"): Wep$ = "Deathbane": WepB = 8: DeathQ = 2: Exit Sub
        If DeathQ = 2 Then NpcTalk("quest2.npc"): Exit Sub
    End If
    If (WorldData.NPC < 94 Or WorldData.NPC > 99) And WorldData.NPC <> 56 And WorldData.NPC <> 57 Then
        ov$ = NpcAt$(WorldData.NPCcol, WorldData.NPCrow)
        If ov$ <> "" Then NpcTalk(ov$): Exit Sub
    End If
    If WorldData.NPC = -1 Or WorldData.NPC = 48 Or WorldData.NPC = 49 Then
        GoFishing
        Exit Sub
    End If
    If WorldData.NPC = 42 Then
        Hp = Hp + 5
        If Hp > MaxHp Then Hp = MaxHp
        box(46, 66, 274, 106)
        TEXT "The fountain's water is refreshing.", 15, 54, 70, 1
        TEXT "You sip, and recover 5 HP.", 14, 54, 84, 1
        Do: LoopMidi: Loop Until INKEY$ <> ""
        Exit Sub
    End If
    If WorldData.NPC = 55 Then
        box(80, 78, 240, 100)
        TEXT "Weapon Shop", 14, 160 - Len("Weapon Shop") * 3, 84, 1
        Do: LoopMidi: Loop Until INKEY$ <> ""
        Exit Sub
    End If
    If WorldData.NPC = 52 Then
        box(80, 78, 240, 100)
        TEXT "Armor Shop", 14, 160 - Len("Armor Shop") * 3, 84, 1
        Do: LoopMidi: Loop Until INKEY$ <> ""
        Exit Sub
    End If
    If WorldData.NPC = 54 Then
        box(80, 78, 240, 100)
        TEXT "Potion Shop", 14, 160 - Len("Potion Shop") * 3, 84, 1
        Do: LoopMidi: Loop Until INKEY$ <> ""
        Exit Sub
    End If
    If WorldData.NPC = 53 Then
        box(80, 78, 240, 100)
        TEXT "Inn", 14, 160 - Len("Inn") * 3, 84, 1
        Do: LoopMidi: Loop Until INKEY$ <> ""
        Exit Sub
    End If
    Select Case WorldData.NPC
    Case 28, 29, 30
        ' shop counters (28/30) and clerks (29): pick shop by interior + counter
        ' position. NPCcol/NPCrow are grid coords (editor cell + 1).
        shopdone = 0
        If CurMap = "yellowseedin.map" Then
            If WorldData.NPCrow <= 3 Then
                If WorldData.NPCcol <= 4 Then Shop2: shopdone = 1
                If WorldData.NPCcol >= 5 And WorldData.NPCcol <= 9 Then Shop3: shopdone = 1
                If WorldData.NPCcol >= 10 Then Shop1: shopdone = 1
            Else
                Shop4: shopdone = 1
            End If
        ElseIf CurMap = "turnsteadin.map" Then
            If WorldData.NPCrow <= 12 Then
                If WorldData.NPCcol <= 5 Then Shop2: shopdone = 1
                If WorldData.NPCcol >= 6 And WorldData.NPCcol <= 9 Then Shop3: shopdone = 1
                If WorldData.NPCcol >= 10 Then Shop1: shopdone = 1
            Else
                Shop4: shopdone = 1
            End If
        ElseIf CurMap = "thunderbaywestin.map" Then
            Shop4: shopdone = 1
        ElseIf CurMap = "thunderbaysouthdocksin.map" Then
            Shop3: shopdone = 1
        ElseIf CurMap = "thunderbaynorthwestin.map" Then
            Shop2: shopdone = 1
        ElseIf CurMap = "startingzonein.map" Then
            Shop1: shopdone = 1
        ElseIf CurMap = "balthixin.map" Then
            If WorldData.NPCcol <= 6 Then Shop2: shopdone = 1
            If WorldData.NPCcol >= 7 And WorldData.NPCcol <= 12 Then Shop3: shopdone = 1
            If WorldData.NPCcol >= 40 Then Shop4: shopdone = 1
        End If
        If shopdone = 0 Then Shopkeeper
    Case 68
    Case 69
    Case 70
    Case 71
    Case 72
    Case 73
    Case 74
    Case 75
    Case 76
    Case 77
    Case 78
    Case 79
    Case 80
    Case 81
    Case 83
    Case 84
    Case 85
    Case 86
    Case 87
    Case 88
    Case 89
        If WorldData.Place = 8 Then killer: NpcFile$ = " "
    Case 82
    Case 107
    Case 108
    Case 109
    Case 110
    Case 100
    Case 101
    Case 102
    Case 103
    Case 104
    Case 90
    Case 91
    Case 92
    Case 93
    Case 94
        If Q1 = 0 Then
            NpcTalk("ORENTIDEWATCHER.NPC")
            O1 = 1: GotAItem: Q1 = 1
            Exit Sub
        End If
    Case 95
        If Q2 = 0 Then
            NpcTalk("AldericTidecaller.npc")
            O2 = 1: GotAItem: Q2 = 1
            Exit Sub
        End If
    Case 96
        If Q3 = 0 Then
            NpcTalk("Dryleaf.npc")
            O3 = 1: GotAItem: Q3 = 1
            Exit Sub
        End If
    Case 97
        If Q4 = 0 And kills >= 5 Then
            NpcTalk("MorgulDacul.npc")
            O4 = 1: GotAItem: Q4 = 1: kills = kills - 5
            Exit Sub
        End If
        If Q4 = 0 And kills <= 4 Then NpcFile$ = "MorgulDaculWait.npc"
    Case 98
        If Q5 = 1 Then Exit Sub
        ' Dolgan grants Orm's Seventh Eye only if 3 of the other relics are held
        If O1 + O2 + O3 + O4 >= 3 Then
            NpcTalk("dolgan.npc")
            O5 = 1: GotAItem: Q5 = 1
            Exit Sub
        End If
        NpcFile$ = "dolgan2.npc"
    Case 56
        If WorldData.Place = 20 Then NpcTalk("etheros.npc"): FightEtheros
        Exit Sub
    Case 57
        If WorldData.Place = 14 And DeathQ = 0 Then NpcTalk("throllux.npc"): FightThrollux
        Exit Sub
    End Select
    If NpcFile$ = " " Then Exit Sub
    NpcTalk(NpcFile$)
End Sub

'-------------------------------------------
' Music track switching driven by NewMidi/CurMidi (as before)
Sub MusicUpdate
    if nomidi = 0 then
        if NewMidi <> CurMidi then
            PlayTrack(NewMidi)
            CurMidi = NewMidi
        end if
    end if
    Static As Integer cnt
    Dim As ZString * 64 ret
    ' LevelUp (5) is a one-shot fanfare — do not loop it while the player reads.
    If MusicOpen = 1 And nomidi = 0 And CurMidi <> 5 Then
        cnt = cnt + 1
        If cnt >= 30 Then
            cnt = 0
            mciSendString("status araxmus mode", @ret, 64, 0)
            If ret = "stopped" Then
                mciSendString("seek araxmus to start", 0, 0, 0)
                mciSendString("play araxmus", 0, 0, 0)
            End If
        End If
    End If
End Sub

'-------------------------------------------
' Called inside every wait loop: keeps music going, screen fresh, CPU cool
Sub LoopMIDI
    Present
    MusicUpdate
    Sleep 5, 1
End Sub

'-------------------------------------------
' Register the 5 music tracks (played via MCI straight from the .mid files)
Sub LoadMusic
    dim as integer i

    MusicName(0) = "Battle"
    MusicName(1) = "Town"
    MusicName(2) = "Dungeons"
    MusicName(3) = "INTRO"
    MusicName(4) = "Boss"
    MusicName(5) = "LevelUp"

    For i = 0 To 5
        If Dir(MusicName(i) + ".mid") = "" Then
            Print "Warning: missing " + MusicName(i) + ".mid"
        End If
    Next
End Sub

'-------------------------------------------
' Play track t (0-4). t = -1 stops all music.
' background thread: does the slow MCI close/open off the main loop
' Play track t (0-4). t = -1 stops all music.
Sub PlayTrack (t As Integer)
    If MusicOpen = 1 Then
        mciSendString("close araxmus", 0, 0, 0)
        MusicOpen = 0
    End If
    If t < 0 Or t > 5 Then Exit Sub
    If mciSendString("open " + MusicName(t) + ".mid type sequencer alias araxmus", 0, 0, 0) = 0 Then
        MusicOpen = 1
        mciSendString("play araxmus", 0, 0, 0)
        ApplyVolume
    End If
End Sub

'-------------------------------------------
Sub ApplyVolume
    Dim As ULong v

    v = (MusicVol * 65535) \ 10
    midiOutSetVolume(0, (v Shl 16) Or v)   ' left = low word, right = high word
End Sub

'-------------------------------------------
' Tolerant .NPC page reader. A page is:
'   "pagenumber"        (a quoted number on its own line)
'   1 to 5 quoted text lines
'   0 to 3 response lines:  "text",page-to-jump-to
' Missing lines are simply treated as blank.
Sub ReadNpcPage (FileName$, pageno, tx1$, tx2$, tx3$, tx4$, tx5$, r1$, t1, r2$, t2, r3$, t3)
    dim as integer f, pagecount, collecting, ntx, nresp, q2, jump, i, isnum
    dim ln$, inner$, rest$, c$
    
    tx1$ = "": tx2$ = "": tx3$ = "": tx4$ = "": tx5$ = ""
    r1$ = "": r2$ = "": r3$ = "": t1 = 0: t2 = 0: t3 = 0
    
    f = FreeFile
    If Open(FileName$ For Input As #f) <> 0 Then Exit Sub
    
    Do Until EOF(f)
        Line Input #f, ln$
        If Right$(ln$, 1) = CHR$(13) Then ln$ = Left$(ln$, Len(ln$) - 1)
        ln$ = Trim$(ln$)
        If ln$ <> "" Then
            ' split a quoted line into inner text + whatever follows the quotes
            inner$ = ln$: rest$ = ""
            If Left$(ln$, 1) = CHR$(34) Then
                q2 = Instr(2, ln$, CHR$(34))
                If q2 > 0 Then
                    inner$ = Mid$(ln$, 2, q2 - 2)
                    rest$ = LTrim$(Mid$(ln$, q2 + 1))
                Else
                    inner$ = Mid$(ln$, 2)
                End If
            End If
            
            If Left$(rest$, 1) = "," Then
                ' response line
                jump = Val(Mid$(rest$, 2))
                If collecting = 1 Then
                    nresp = nresp + 1
                    If nresp = 1 Then r1$ = inner$: t1 = jump
                    If nresp = 2 Then r2$ = inner$: t2 = jump
                    If nresp = 3 Then r3$ = inner$: t3 = jump
                End If
            Else
                ' page header (a pure number) or a text line
                isnum = 0
                If Len(inner$) > 0 Then
                    isnum = 1
                    For i = 1 To Len(inner$)
                        c$ = Mid$(inner$, i, 1)
                        If c$ < "0" Or c$ > "9" Then isnum = 0
                    Next
                End If
                If isnum = 1 Then
                    If collecting = 1 Then Exit Do        ' next page starts
                    pagecount = pagecount + 1
                    If pagecount = pageno Then collecting = 1
                ElseIf collecting = 1 Then
                    ntx = ntx + 1
                    If ntx = 1 Then tx1$ = inner$
                    If ntx = 2 Then tx2$ = inner$
                    If ntx = 3 Then tx3$ = inner$
                    If ntx = 4 Then tx4$ = inner$
                    If ntx = 5 Then tx5$ = inner$
                End If
            End If
        End If
    Loop
    Close #f
End Sub

'-------------------------------------------
' Encode/decode a key (INKEY$ string) to a number for settings.cfg
Function KeyCode (k$)
    If Len(k$) = 2 And Left$(k$, 1) = CHR$(255) Then
        KeyCode = 65280 + Asc(Right$(k$, 1))
    ElseIf Len(k$) >= 1 Then
        KeyCode = Asc(k$)
    Else
        KeyCode = 0
    End If
End Function

Function CodeKey$ (c)
    If c >= 65280 Then
        CodeKey$ = CHR$(255) + CHR$(c - 65280)
    ElseIf c > 0 Then
        CodeKey$ = CHR$(c)
    Else
        CodeKey$ = ""
    End If
End Function

' Human-readable key name
Function KeyName$ (k$)
    dim as integer sc
    If k$ = " " Then KeyName$ = "SPACE": Exit Function
    If k$ = CHR$(27) Then KeyName$ = "ESC": Exit Function
    If k$ = CHR$(13) Then KeyName$ = "ENTER": Exit Function
    If k$ = CHR$(9) Then KeyName$ = "TAB": Exit Function
    If k$ = CHR$(8) Then KeyName$ = "BACKSP": Exit Function
    If Len(k$) = 2 And Left$(k$, 1) = CHR$(255) Then
        sc = Asc(Right$(k$, 1))
        If sc >= 59 And sc <= 68 Then KeyName$ = "F" + Fixed$(sc - 58): Exit Function
        If sc = 71 Then KeyName$ = "HOME": Exit Function
        If sc = 79 Then KeyName$ = "END": Exit Function
        If sc = 73 Then KeyName$ = "PGUP": Exit Function
        If sc = 81 Then KeyName$ = "PGDN": Exit Function
        If sc = 82 Then KeyName$ = "INS": Exit Function
        If sc = 83 Then KeyName$ = "DEL": Exit Function
        KeyName$ = "KEY" + Fixed$(sc): Exit Function
    End If
    KeyName$ = UCase$(k$)
End Function

'-------------------------------------------
' Controls screen: view and rebind Interact / Inventory / Menu
Sub ControlsMenu
    dim as integer sel, sc, bad
    dim z$, nk$
    
    sel = 1
    Do
        box(40, 35, 280, 155)
        TEXT "CONTROLS", 9, 128, 42, 1
        TEXT "Move:      Arrow Keys", 15, 55, 56, 1
        TEXT "Interact:  " + KeyName$(KeyInteract$), IIf(sel = 1, 9, 15), 55, 68, 1
        TEXT "Inventory: " + KeyName$(KeyInv$), IIf(sel = 2, 9, 15), 55, 80, 1
        TEXT "Menu:      " + KeyName$(KeyMenu$), IIf(sel = 3, 9, 15), 55, 92, 1
        TEXT "Music: M   Help: H   Quit: Q", 15, 55, 104, 1
        TEXT "Reset Defaults", IIf(sel = 4, 9, 15), 55, 118, 1
        TEXT "Back", IIf(sel = 5, 9, 15), 55, 130, 1
        TEXT "Enter: change key   Esc: back", 170, 50, 143, 1
        
        Do
            z$ = INKEY$
            LoopMidi
        Loop Until z$ <> ""
        
        Select Case z$
        Case CHR$(27)
            Exit Do
        Case CHR$(255) + CHR$(72)
            sel = sel - 1: If sel < 1 Then sel = 5
        Case CHR$(255) + CHR$(80)
            sel = sel + 1: If sel > 5 Then sel = 1
        Case CHR$(13)
            If sel = 5 Then Exit Do
            If sel = 4 Then
                KeyInteract$ = " ": KeyInv$ = "I": KeyMenu$ = CHR$(27)
                SaveSettings
            End If
            If sel >= 1 And sel <= 3 Then
                TEXT "Press a new key (Esc cancels)   ", 12, 50, 143, 1
                Do: LoopMidi: Loop Until INKEY$ = ""       ' small settle
                Do
                    nk$ = INKEY$
                    LoopMidi
                Loop Until nk$ <> ""
                
                bad = 0
                If nk$ = CHR$(27) Then bad = 1                       ' cancel
                If Len(nk$) = 2 Then
                    sc = Asc(Right$(nk$, 1))
                    If sc = 72 Or sc = 75 Or sc = 77 Or sc = 80 Then bad = 1   ' arrows = movement
                End If
                If Len(nk$) = 1 Then nk$ = UCase$(nk$)
                If nk$ = "H" Or nk$ = "M" Or nk$ = "Q" Or nk$ = "?" Then bad = 1
                If sel <> 1 And nk$ = KeyInteract$ Then bad = 1
                If sel <> 2 And nk$ = KeyInv$ Then bad = 1
                If sel <> 3 And nk$ = KeyMenu$ Then bad = 1
                
                If bad = 0 Then
                    If sel = 1 Then KeyInteract$ = nk$
                    If sel = 2 Then KeyInv$ = nk$
                    If sel = 3 Then KeyMenu$ = nk$
                    SaveSettings
                End If
            End If
        End Select
    Loop
End Sub

'-------------------------------------------
' Load a map's NPC dialogue overrides from <mapname>.npcs
' Each line:  col,row,filename.npc   (blank/# lines ignored)
Sub LoadNpcMap (mapfile$)
    dim as integer f, c, r, p1, p2
    dim ln$, stem$, path$, fn$
    
    NpcMapN = 0
    stem$ = mapfile$
    p1 = Instr(stem$, ".")
    If p1 > 0 Then stem$ = Left$(stem$, p1 - 1)
    path$ = stem$ + ".npcs"
    If Dir(path$) = "" Then Exit Sub
    
    f = FreeFile
    If Open(path$ For Input As #f) <> 0 Then Exit Sub
    Do Until EOF(f)
        Line Input #f, ln$
        If Right$(ln$, 1) = CHR$(13) Then ln$ = Left$(ln$, Len(ln$) - 1)
        ln$ = Trim$(ln$)
        If ln$ <> "" And Left$(ln$, 1) <> "#" Then
            p1 = Instr(ln$, ",")
            If p1 > 0 Then
                p2 = Instr(p1 + 1, ln$, ",")
                If p2 > 0 Then
                    c = Val(Left$(ln$, p1 - 1))
                    r = Val(Mid$(ln$, p1 + 1, p2 - p1 - 1))
                    fn$ = Trim$(Mid$(ln$, p2 + 1))
                    If NpcMapN < 200 And fn$ <> "" Then
                        NpcMapN = NpcMapN + 1
                        NpcMapCol(NpcMapN) = c
                        NpcMapRow(NpcMapN) = r
                        NpcMapFile$(NpcMapN) = fn$
                    End If
                End If
            End If
        End If
    Loop
    Close #f
End Sub

' Return the override dialogue file for a map cell, or "" if none
Function NpcAt$ (col, row)
    dim as integer i
    NpcAt$ = ""
    For i = 1 To NpcMapN
        If NpcMapCol(i) = col And NpcMapRow(i) = row Then
            NpcAt$ = NpcMapFile$(i)
            Exit Function
        End If
    Next
End Function

'-------------------------------------------
' Search the barrel the player is facing. Each barrel can be
' searched once per map visit; low chance of gold or heals.
Sub SearchBarrel
    dim as integer bx, by, i, roll, amt
    dim msg$
    
    bx = WorldData.TopCol + 8
    by = WorldData.TopRow + 5
    Select Case Player.Dir
    Case 0: by = by + 1
    Case 1: bx = bx + 1
    Case 2: by = by - 1
    Case 3: bx = bx - 1
    End Select
    
    For i = 1 To BarrelN
        If BarrelX(i) = bx And BarrelY(i) = by Then
            msg$ = "Nothing here but splinters."
            Goto barreldone
        End If
    Next
    If BarrelN < 100 Then
        BarrelN = BarrelN + 1
        BarrelX(BarrelN) = bx
        BarrelY(BarrelN) = by
    End If
    
    roll = Int(Rnd * 100)
    If roll < 8 Then                    ' 8% rare find
        amt = Int(Rnd * 100)
        If amt < 60 Then
            amt = Int(Rnd * 11) + 1     ' 1..11 gold max
            gold% = gold% + amt
            msg$ = "You found " + Fixed$(amt) + " gold!"
        ElseIf amt < 85 Then
            SPot = SPot + 1
            msg$ = "You found a Small Heal!"
        Else
            Fpot = Fpot + 1
            msg$ = "You found a Large Heal!"
        End If
    Else
        msg$ = "You rummage around... nothing useful."
    End If
    
    barreldone:
    box(46, 66, 274, 106)
    TEXT "You search the barrel...", 15, 54, 70, 1
    TEXT msg$, 14, 54, 84, 1
    Do: LoopMidi: Loop Until INKEY$ <> ""
End Sub

'-------------------------------------------
' m: 0=fullscreen (desktop res), 1=1920x1080, 2=1280x720, 3=640x360
' The game always renders internally at 320x200 (work page) and is
' scaled up to the visible page by DoPresent.
Sub SetVideoMode (m As Integer)
    dim as integer x, y
    
    VideoMode = m
    Select Case m
    Case 0
        ScrW = DeskW: ScrH = DeskH
    Case 1
        ScrW = 1920: ScrH = 1080
    Case 2
        ScrW = 1280: ScrH = 720
    Case Else
        ScrW = 640: ScrH = 360
    End Select
    If ScrW < 320 Then ScrW = 320
    If ScrH < 200 Then ScrH = 200
    
    If m = 0 Then
        ScreenRes ScrW, ScrH, 8, 2, &h1
        If ScreenPtr = 0 Then ScreenRes ScrW, ScrH, 8, 2   ' fullscreen failed: window
    Else
        ScreenRes ScrW, ScrH, 8, 2
    End If
    
    ScreenSet 1, 0        ' draw on page 1, show page 0
    WindowTitle "Araxia: Shadow of Etheros"
    
    Redim XMap(ScrW - 1), YMap(ScrH - 1)
    For x = 0 To ScrW - 1: XMap(x) = x * 320 \ ScrW: Next
    For y = 0 To ScrH - 1: YMap(y) = y * 200 \ ScrH: Next
    
    SetupPalette
    LastPresent = 0
End Sub

'-------------------------------------------
' Scale the 320x200 work page up onto the visible page
Sub DoPresent
    Static frame(320 * 200 - 1) As UByte
    dim as ubyte ptr p, srow, drow
    dim as integer x, y
    dim as long pitch
    
    ScreenInfo , , , , pitch
    p = ScreenPtr                        ' work page (1): 320x200 game frame
    If p = 0 Then Exit Sub
    For y = 0 To 199
        memcpy(@frame(y * 320), p + y * pitch, 320)
    Next
    
    ScreenSet 0, 0                       ' target the visible page
    ScreenLock
    p = ScreenPtr
    If p <> 0 Then
        For y = 0 To ScrH - 1
            srow = @frame(YMap(y) * 320)
            drow = p + y * pitch
            For x = 0 To ScrW - 1
                drow[x] = srow[XMap(x)]
            Next
        Next
    End If
    ScreenUnlock
    ScreenSet 1, 0                       ' back to the work page
End Sub

'-------------------------------------------
' Throttled present for wait loops (max ~60 Hz)
Sub Present
    If Timer - LastPresent < 1.0 / 60 Then Exit Sub
    LastPresent = Timer
    DoPresent
End Sub

'-------------------------------------------
' Frame-paced present for the game loop (locks to ~60 fps)
Sub PresentFrame
    Do While Timer - LastPresent < 1.0 / 60
        Sleep 1, 1
    Loop
    LastPresent = Timer
    DoPresent
End Sub

'-------------------------------------------
Sub LoadSettings
    dim as integer f
    
    VideoMode = 2: MusicVol = 8                     ' defaults: 720p window
    MiniTrans = 2
    KeyInteract$ = " ": KeyInv$ = "I": KeyMenu$ = CHR$(27)
    f = FreeFile
    If Open("settings.cfg" For Input As #f) = 0 Then
        Input #f, VideoMode, MusicVol
        If Not EOF(f) Then
            Input #f, k1, k2, k3
            If CodeKey$(k1) <> "" Then KeyInteract$ = CodeKey$(k1)
            If CodeKey$(k2) <> "" Then KeyInv$ = CodeKey$(k2)
            If CodeKey$(k3) <> "" Then KeyMenu$ = CodeKey$(k3)
            If Not EOF(f) Then Input #f, MiniTrans
            If MiniTrans < 0 Or MiniTrans > 4 Then MiniTrans = 2
        End If
        Close #f
    End If
    If VideoMode < 0 Or VideoMode > 3 Then VideoMode = 2
    If MusicVol < 0 Then MusicVol = 0
    If MusicVol > 10 Then MusicVol = 10
End Sub

'-------------------------------------------
Sub SaveSettings
    dim as integer f
    
    f = FreeFile
    If Open("settings.cfg" For Output As #f) = 0 Then
        Write #f, VideoMode, MusicVol, KeyCode(KeyInteract$), KeyCode(KeyInv$), KeyCode(KeyMenu$), MiniTrans
        Close #f
    End If
End Sub

'-------------------------------------------
' Options screen: display size, volume slider, stereo/mono
Sub MenuOptions
    dim as integer sel
    dim z$
    dim minilbl$
    dim modes(0 to 3) as string = {"Fullscreen", "1920x1080 ", "1280x720  ", "640x360   "}
    
    sel = 1
    Do
        box(40, 35, 280, 162)
        TEXT "OPTIONS", 9, 132, 42, 1
        If MiniTrans = 0 Then minilbl$ = "Solid "
        If MiniTrans = 1 Then minilbl$ = "Light "
        If MiniTrans = 2 Then minilbl$ = "Medium"
        If MiniTrans = 3 Then minilbl$ = "Heavy "
        If MiniTrans = 4 Then minilbl$ = "Off   "
        TEXT "Display: < " + modes(VideoMode) + " >", IIf(sel = 1, 9, 15), 55, 62, 1
        TEXT "Volume:", IIf(sel = 2, 9, 15), 55, 80, 1
        Line (110, 83)-(215, 92), 172, B
        Line (111, 84)-(214, 91), 0, BF
        If MusicVol > 0 Then Line (112, 85)-Step(MusicVol * 10 - 1, 5), 77, BF
        TEXT Fixed$(MusicVol * 10) + "%", 15, 224, 80, 1
        TEXT "Controls...", IIf(sel = 3, 9, 15), 55, 98, 1
        TEXT "Mini-map: < " + minilbl$ + " >", IIf(sel = 4, 9, 15), 55, 112, 1
        TEXT "Back", IIf(sel = 5, 9, 15), 55, 126, 1
        TEXT "Up/Down: select  Left/Right: change", 170, 50, 140, 1
        TEXT "Esc: return to game menu", 170, 50, 149, 1
        
        Do
            z$ = INKEY$
            LoopMidi
        Loop Until z$ <> ""
        
        Select Case z$
        Case CHR$(27)
            Exit Do
        Case CHR$(13)
            If sel = 3 Then ControlsMenu
            If sel = 5 Then Exit Do
        Case CHR$(255) + CHR$(72)                  ' up
            sel = sel - 1: If sel < 1 Then sel = 5
        Case CHR$(255) + CHR$(80)                  ' down
            sel = sel + 1: If sel > 5 Then sel = 1
        Case CHR$(255) + CHR$(75)                  ' left
            Select Case sel
            Case 1
                VideoMode = VideoMode - 1: If VideoMode < 0 Then VideoMode = 3
                SetVideoMode VideoMode
                SaveSettings
                Cls: ShowMap
            Case 2
                If MusicVol > 0 Then MusicVol = MusicVol - 1: ApplyVolume: SaveSettings
            Case 4
                MiniTrans = MiniTrans - 1: If MiniTrans < 0 Then MiniTrans = 4
                SaveSettings
            End Select
        Case CHR$(255) + CHR$(77)                  ' right
            Select Case sel
            Case 1
                VideoMode = VideoMode + 1: If VideoMode > 3 Then VideoMode = 0
                SetVideoMode VideoMode
                SaveSettings
                Cls: ShowMap
            Case 2
                If MusicVol < 10 Then MusicVol = MusicVol + 1: ApplyVolume: SaveSettings
            Case 4
                MiniTrans = MiniTrans + 1: If MiniTrans > 4 Then MiniTrans = 0
                SaveSettings
            End Select
        End Select
    Loop
    
    SaveSettings
End Sub

'-------------------------------------------
' In-game text entry for the hero name (Input can't be used with paging)
Function GetName () As String
    dim s as string, k as string
    
    Do
        Line (58, 54)-(205, 66), 0, BF
        TEXT s + "_", 12, 60, 56, 1
        Do
            k = INKEY$
            LoopMidi
        Loop Until k <> ""
        
        Select Case k
        Case CHR$(13)
            If LTrim(RTrim(s)) <> "" Then Exit Do
        Case CHR$(8)
            If Len(s) > 0 Then s = Left(s, Len(s) - 1)
        Case Else
            If Len(k) = 1 And Len(s) < 13 Then
                If k >= " " And k <= "~" Then s = s + k
            End If
        End Select
    Loop
    
    GetName = s
End Function

'-------------------------------------------
Sub TheEnd
    Chdir ".."
    PlayTrack(-1)
    mciSendString("close all", 0, 0, 0)
    END
End sub

Sub FixLanding
    ' After an edge transition, if the landing cell is off-map or on a wall
    ' (happens when the destination map is a different size or its opening
    ' doesn't align), snap the player to the nearest walkable tile on the
    ' correct edge. Does nothing when the landing is already valid, so
    ' standard 30x50 aligned transitions are untouched.
    dim as integer pc, pr, i, best, bestd, tc, tr
    pc = WorldData.TopCol + 8
    pr = WorldData.TopRow + 5
    If pc >= 1 And pc <= WorldData.Cols And pr >= 1 And pr <= WorldData.Rows Then
        If map(pc, pr).Walkon Then Exit Sub
    End If
    best = -1: bestd = 9999
    Select Case WorldData.Direc
    Case West
        tc = WorldData.Cols
        For i = 1 To WorldData.Rows
            If map(tc, i).Walkon Then
                If Abs(i - pr) < bestd Then bestd = Abs(i - pr): best = i
            End If
        Next i
        If best > 0 Then WorldData.TopCol = tc - 8: WorldData.TopRow = best - 5
    Case East
        tc = 1
        For i = 1 To WorldData.Rows
            If map(tc, i).Walkon Then
                If Abs(i - pr) < bestd Then bestd = Abs(i - pr): best = i
            End If
        Next i
        If best > 0 Then WorldData.TopCol = tc - 8: WorldData.TopRow = best - 5
    Case North
        tr = WorldData.Rows
        For i = 1 To WorldData.Cols
            If map(i, tr).Walkon Then
                If Abs(i - pc) < bestd Then bestd = Abs(i - pc): best = i
            End If
        Next i
        If best > 0 Then WorldData.TopRow = tr - 5: WorldData.TopCol = best - 8
    Case South
        tr = 1
        For i = 1 To WorldData.Cols
            If map(i, tr).Walkon Then
                If Abs(i - pc) < bestd Then bestd = Abs(i - pc): best = i
            End If
        Next i
        If best > 0 Then WorldData.TopRow = tr - 5: WorldData.TopCol = best - 8
    End Select
End Sub
