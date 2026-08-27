<#
==============================================================================
  ARAXIA Map Editor  (PowerShell / WinForms)   v2 - with NPC dialogue linking
  ---------------------------------------------------------------------------
  Point-and-click editor for ARAXIA's .MAP files, PLUS an RPG-Maker-style
  way to attach a specific dialogue file to a specific NPC on the map.

  TILE PAINTING
  * Left panel : tile palette. Click a tile to pick it as your "brush".
  * Middle     : the map. Left-click / drag to paint. Right-click = eyedropper.
  * Toolbar    : Open, Save, Save As, New, Load Tile Art, Fill, view toggles.

  NPC DIALOGUE  (the new part)
  * Click "NPC Link: Off" to turn on NPC mode. In NPC mode, LEFT-CLICK a cell
    that holds a person/clerk/sign tile to choose which .npc file it says.
  * A little yellow dot marks every cell that has dialogue assigned.
  * Assignments are saved next to the map as  <mapname>.npcs  (plain text:
    one "col,row,file.npc" line per NPC). The game reads this file and shows
    that dialogue when the player talks to that exact NPC - no matter what
    tile number it uses. Old maps without a .npcs file behave exactly as before.
  * "Edit Text..." in the NPC dialog opens a simple page editor so you can
    write the actual conversation without leaving the app.

  .MAP format (unchanged):  line 1 = Rows,Cols ; then Rows lines of Cols IDs.

  RUN on Windows 11:  Right-click -> "Run with PowerShell"
     or:   .\AraxiaMapEditor.ps1
     if blocked once:   Unblock-File .\AraxiaMapEditor.ps1
==============================================================================
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

# ----------------------------------------------------------------------------
#  Tile table  (extracted from ARAXIA.BAS: PutTile + LoadTiles + LoadMap)
# ----------------------------------------------------------------------------
$blocked = @(0,-1,-2,-3,-4,-5,-6,-7,7,21,22,20,10,11,14,16,17,13,4,18,19,24,25,26,27,28,29,30,33,34,36,37,38,39,42,44,45,46,47,48,49,50,51,52,53,54,55)
68..99 | ForEach-Object { $blocked += $_ }

$tileDefs = @(
    @{ id = 1;  name='Grass 1';   file='grass1.mdt'; c='#3FA33F' }
    @{ id = 2;  name='Grass 2';   file='grass2.mdt'; c='#4CB84C' }
    @{ id = 31; name='Grass 3';   file='grass3.mdt'; c='#58C258' }
    @{ id = 32; name='Grass 4';   file='grass4.mdt'; c='#66D066' }
    @{ id = 4;  name='Bush';      file='bush1.mdt';  c='#4E7A34' }
    @{ id = 33; name='Hedge 1';   file='hedge1.mdt'; c='#205E20' }
    @{ id = 34; name='Hedge 2';   file='hedge2.mdt'; c='#1E561E' }
    @{ id = 3;  name='Path 1';    file='floor1.mdt'; c='#C9A46A' }
    @{ id = 5;  name='Path 2';    file='path01.mdt'; c='#D2B072' }
    @{ id = 6;  name='Path 3';    file='floor2.mdt'; c='#BE9A5E' }
    @{ id = 35; name='Dock';      file='dock1.mdt';  c='#B08A50' }
    @{ id = 36; name='Lamp Post'; file='lamp1.mdt';  c='#F2C33C' }
    @{ id = 37; name='Dock Crate';file='crate1.mdt'; c='#A6742E' }
    @{ id = 38; name='Dock Barrel';file='dbarrel1.mdt';c='#86592E' }
    @{ id = 40; name='Dock Plank v2';file='dock2.mdt';c='#C29A5E' }
    @{ id = 41; name='Rope Coil'; file='rope1.mdt';  c='#B8935A' }
    @{ id = 42; name='Fountain';  file='well1.mdt';  c='#7FC8E6' }
    @{ id = -1; name='Water';     file='water1.mdt'; c='#2E5BE0' }
    @{ id = -2; name='Tree 1';    file='tree1.mdt';  c='#22902F' }
    @{ id = -3; name='Tree 2';    file='tree2.mdt';  c='#1B7A2A' }
    @{ id = -6; name='Tree 3';    file='tree3.mdt';  c='#1E6B27' }
    @{ id = -7; name='Tree 4';    file='tree4.mdt';  c='#17591F' }
    @{ id = 7;  name='Rock 1';    file='rock1.mdt';  c='#8C8C8C' }
    @{ id = 0;  name='Black';     file='black.mdt';  c='#000000' }
    @{ id = 10; name='Wall 1';    file='wall1.mdt';  c='#6E6E6E' }
    @{ id = 11; name='Wall 2';    file='wall2.mdt';  c='#7A6E5E' }
    @{ id = 20; name='Wall 02';   file='wall02.mdt'; c='#8A8577' }
    @{ id = 21; name='Wall 01';   file='wall01.mdt'; c='#948E7E' }
    @{ id = 12; name='Roof';      file='roof1.mdt';  c='#A6472E' }
    @{ id = 13; name='Window 1';  file='wind01.mdt'; c='#7FC8E6' }
    @{ id = 22; name='Window 2';  file='wind02.mdt'; c='#6FB8D6' }
    @{ id = -9; name='Door 1';    file='door1.mdt';  c='#7A4B2B' }
    @{ id = -8; name='Door 2';    file='door2.mdt';  c='#5A3B22' }
    @{ id = 14; name='Fireplace'; file='firepc.mdt'; c='#E8791F' }
    @{ id = 19; name='Torch';     file='torch1.mdt'; c='#F2C33C' }
    @{ id = 16; name='Bed 1';     file='bed1.mdt';   c='#C23B3B' }
    @{ id = 17; name='Bed 2';     file='bed2.mdt';   c='#A83232' }
    @{ id = 18; name='Desk 1';    file='desk1.mdt';  c='#7A5230' }
    @{ id = 28; name='Desk 2';    file='desk2.mdt';  c='#6A4526' }
    @{ id = 30; name='Shop Desk'; file='desk2.mdt';  c='#B8862A' }
    @{ id = 25; name='Table 1';   file='table1.mdt'; c='#8A5A30' }
    @{ id = 27; name='Table 2';   file='table2.mdt'; c='#7A4E28' }
    @{ id = 24; name='Barrel';    file='barrel1.mdt';c='#86592E' }
    @{ id = 26; name='Shelf';     file='shelf1.mdt'; c='#7A5230' }
    @{ id = -4; name='Sign 1';    file='sign1.mdt';  c='#8A6A3A' }
    @{ id = -5; name='Sign 2';    file='sign2.mdt';  c='#7A5A2E' }
    @{ id = 29; name='Clerk NPC'; file='clerk1.mdt'; c='#C24BC2' }
    @{ id = 43; name='Ashy Ground'; file='ashyground.mdt'; c='#6B6459' }
    @{ id = 44; name='Ember Pile'; file='emberpile.mdt'; c='#B5451F' }
    @{ id = 45; name='Grave Mound'; file='gravemound.mdt'; c='#5A4A38' }
    @{ id = 46; name='Tombstone'; file='tombstone.mdt'; c='#8A8A8A' }
    @{ id = 47; name='Tombstone 2'; file='tombstone2.mdt'; c='#7C7C7C' }
    @{ id = 50; name='Iron Fence'; file='ironfence.mdt'; c='#3C3C42' }
    @{ id = 51; name='Wooden Fence'; file='woodenfence.mdt'; c='#7A5230' }
    @{ id = 56; name='Lich (Etheros)'; file='lich.mdt'; c='#1C2020' }
    @{ id = 57; name='Bhaulx (Lizardfolk Shaman)'; file='bhaulx.mdt'; c='#2C6432' }
)
68..99 | ForEach-Object {
    $tileDefs += @{ id = $_; name = "NPC $_"; file = 'man01.mdt'; c = '#B24BD6' }
}

$defById = @{}
foreach ($t in $tileDefs) { $defById[[int]$t.id] = $t }

# tiles that represent something the player TALKS to (person / sign / shop / clerk)
$script:npcTileIds = @(-4,-5,29,30,46,47,52,53,54,55)
68..99 | ForEach-Object { $script:npcTileIds += $_ }

function Is-NpcTile([int]$id) { return ($script:npcTileIds -contains $id) }

function Get-TileColor([int]$id) {
    if ($defById.ContainsKey($id)) { return [System.Drawing.ColorTranslator]::FromHtml($defById[$id].c) }
    return [System.Drawing.Color]::FromArgb(90,90,90)
}
function Get-TileName([int]$id) {
    if ($defById.ContainsKey($id)) { return $defById[$id].name }
    return "id $id"
}
function Is-Solid([int]$id) { return ($blocked -contains $id) }

# ----------------------------------------------------------------------------
#  .MDT decoder + palette loader
# ----------------------------------------------------------------------------
function Load-Palette([string]$palPath) {
    try {
        $b = [System.IO.File]::ReadAllBytes($palPath)
        $body = $b[7..($b.Length-1)]
        $pal = New-Object 'System.Drawing.Color[]' 256
        for ($i=0; $i -lt 256; $i++) {
            $o = $i*4
            if ($o+2 -ge $body.Length) { $pal[$i] = [System.Drawing.Color]::Black; continue }
            $r = [int]$body[$o]   * 255 / 63
            $g = [int]$body[$o+1] * 255 / 63
            $bl= [int]$body[$o+2] * 255 / 63
            $pal[$i] = [System.Drawing.Color]::FromArgb([int]$r,[int]$g,[int]$bl)
        }
        return $pal
    } catch { return $null }
}
function Decode-Mdt([string]$path, $pal) {
    try {
        $d = [System.IO.File]::ReadAllBytes($path)
        if ($d.Length -lt 11) { return $null }
        $wbits = [int]$d[7]  -bor ([int]$d[8]  -shl 8)
        $h     = [int]$d[9]  -bor ([int]$d[10] -shl 8)
        $w     = [int]($wbits / 8)
        if ($w -le 0 -or $h -le 0 -or $w -gt 256 -or $h -gt 256) { return $null }
        if ($d.Length -lt (11 + $w*$h)) { return $null }
        $bmp = New-Object System.Drawing.Bitmap $w, $h
        $k = 11
        for ($y=0; $y -lt $h; $y++) {
            for ($x=0; $x -lt $w; $x++) { $bmp.SetPixel($x, $y, $pal[[int]$d[$k]]); $k++ }
        }
        return $bmp
    } catch { return $null }
}

# ============================================================================
#  Shared state
# ============================================================================
$script:rows    = 30
$script:cols    = 50
$script:grid    = $null
$script:brush   = 1
$script:ts      = 22
$script:file    = $null
$script:showIds = $false
$script:showGrid= $true
$script:bucket  = $false
$script:npcMode = $false          # NPC-link mode
$script:tilesDir= $null
$script:tileImg = @{}
$script:tileSrc = @{}
$script:bmp     = $null
$script:gfx     = $null
$script:swatches= @()
$script:dirty   = $false
$script:npc     = @{}             # "col,row" -> @{ id=..; name=..; file=.. }   (dialogue overrides)
$script:nextNpcId = 1
$script:selectedNpcKey = $null    # highlighted from the NPC list
$script:moveMode = $false
$script:movingKey = $null         # NPC currently picked up in Move mode
$script:warpBlock = ""            # raw #WARPS / [Warps] section, preserved verbatim across a save

function New-Grid([int]$r,[int]$c,[int]$fill) {
    $g = New-Object 'System.Int32[][]' $r
    for ($i=0;$i -lt $r;$i++){
        $row = New-Object 'int[]' $c
        for ($j=0;$j -lt $c;$j++){ $row[$j]=$fill }
        $g[$i]=$row
    }
    return $g
}

# ============================================================================
#  Form + controls
# ============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "ARAXIA Map Editor"
$form.Size = New-Object System.Drawing.Size(1180, 760)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(45,45,48)

$bar = New-Object System.Windows.Forms.FlowLayoutPanel
$bar.Dock = "Top"; $bar.Height = 40; $bar.Padding = '4,4,4,4'
$bar.BackColor = [System.Drawing.Color]::FromArgb(60,60,63)
$form.Controls.Add($bar)

function New-ToolButton($text) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text; $b.AutoSize = $true; $b.Height = 30
    $b.FlatStyle = "Flat"; $b.ForeColor = "White"
    $b.BackColor = [System.Drawing.Color]::FromArgb(80,80,84)
    $bar.Controls.Add($b)
    return $b
}
$btnNew   = New-ToolButton "New"
$btnOpen  = New-ToolButton "Open"
$btnSave  = New-ToolButton "Save"
$btnSaveAs= New-ToolButton "Save As"
$btnArt   = New-ToolButton "Load Tile Art"
$btnResize= New-ToolButton "Resize"
$btnBucket= New-ToolButton "Bucket: Off"
$btnNpc   = New-ToolButton "NPC Link: Off"
$btnIds   = New-ToolButton "IDs: Off"
$btnZoomIn= New-ToolButton "Zoom +"
$btnZoomOut=New-ToolButton "Zoom -"
$btnWorld = New-ToolButton "World View"
$btnWorld.BackColor = [System.Drawing.Color]::FromArgb(50,90,130)
$btnTeleport = New-ToolButton "Teleport Table"
$btnTeleport.BackColor = [System.Drawing.Color]::FromArgb(130,60,110)
$btnNpc.BackColor = [System.Drawing.Color]::FromArgb(120,90,30)

$status = New-Object System.Windows.Forms.Label
$status.Dock = "Bottom"; $status.Height = 26; $status.TextAlign = "MiddleLeft"
$status.ForeColor = "White"; $status.BackColor = [System.Drawing.Color]::FromArgb(60,60,63)
$status.Text = "  Ready."
$form.Controls.Add($status)

$palHost = New-Object System.Windows.Forms.Panel
$palHost.Dock = "Left"; $palHost.Width = 250
$palHost.BackColor = [System.Drawing.Color]::FromArgb(55,55,58)
$form.Controls.Add($palHost)

$palTitle = New-Object System.Windows.Forms.Label
$palTitle.Dock = "Top"; $palTitle.Height = 24; $palTitle.Text = "  Palette (click to pick)"
$palTitle.ForeColor = "White"; $palTitle.TextAlign = "MiddleLeft"
$palHost.Controls.Add($palTitle)

$pal = New-Object System.Windows.Forms.FlowLayoutPanel
$pal.Dock = "Fill"; $pal.AutoScroll = $true; $pal.Padding = '6,6,6,6'
$pal.BackColor = [System.Drawing.Color]::FromArgb(55,55,58)
$palHost.Controls.Add($pal)
$pal.BringToFront()

# ---- NPC list (right) ------------------------------------------------------
$npcHost = New-Object System.Windows.Forms.Panel
$npcHost.Dock = "Right"; $npcHost.Width = 230
$npcHost.BackColor = [System.Drawing.Color]::FromArgb(55,55,58)
$form.Controls.Add($npcHost)

$npcTitle = New-Object System.Windows.Forms.Label
$npcTitle.Dock = "Top"; $npcTitle.Height = 24; $npcTitle.Text = "  NPCs on this map"
$npcTitle.ForeColor = "White"; $npcTitle.TextAlign = "MiddleLeft"
$npcHost.Controls.Add($npcTitle)

$npcHint = New-Object System.Windows.Forms.Label
$npcHint.Dock = "Top"; $npcHint.Height = 40
$npcHint.Text = "  Click a name to jump to it.`r`n  Double-click to edit."
$npcHint.ForeColor = "#B9B9C0"; $npcHint.TextAlign = "MiddleLeft"
$npcHost.Controls.Add($npcHint)

$npcList = New-Object System.Windows.Forms.ListBox
$npcList.Dock = "Fill"
$npcList.BackColor = [System.Drawing.Color]::FromArgb(30,30,32)
$npcList.ForeColor = "White"; $npcList.BorderStyle = "None"
$npcHost.Controls.Add($npcList)
$npcList.BringToFront()

$script:npcListKeys = @()   # parallel array: listbox index -> "col,row" key

function Refresh-NpcList {
    $npcList.Items.Clear()
    $script:npcListKeys = @()
    foreach ($k in ($script:npc.Keys | Sort-Object)) {
        $o = $script:npc[$k]
        [void]$npcList.Items.Add("$($o.name)  -  $($o.file)")
        $script:npcListKeys += $k
    }
}

$npcList.Add_Click({
    if ($npcList.SelectedIndex -lt 0) { return }
    $key = $script:npcListKeys[$npcList.SelectedIndex]
    $script:selectedNpcKey = $key
    $cr = $key -split ','
    $c = [int]$cr[0]; $r = [int]$cr[1]
    $px = [Math]::Max(0, $c * $script:ts - 100)
    $py = [Math]::Max(0, $r * $script:ts - 100)
    $canvasHost.AutoScrollPosition = New-Object System.Drawing.Point($px, $py)
    Rebuild-Canvas
})
$npcList.Add_DoubleClick({
    if ($npcList.SelectedIndex -lt 0) { return }
    $key = $script:npcListKeys[$npcList.SelectedIndex]
    $cr = $key -split ','
    Assign-Npc ([int]$cr[1]) ([int]$cr[0])
    Refresh-NpcList
})

$canvasHost = New-Object System.Windows.Forms.Panel
$canvasHost.Dock = "Fill"; $canvasHost.AutoScroll = $true
$canvasHost.BackColor = [System.Drawing.Color]::FromArgb(30,30,32)
$form.Controls.Add($canvasHost)
$canvasHost.BringToFront()

$canvas = New-Object System.Windows.Forms.PictureBox
$canvas.SizeMode = "AutoSize"
$canvas.Location = New-Object System.Drawing.Point(0,0)
$canvasHost.Controls.Add($canvas)

$tip = New-Object System.Windows.Forms.ToolTip

# ============================================================================
#  Palette swatches
# ============================================================================
function Build-Palette {
    $pal.Controls.Clear()
    $script:swatches = @()
    foreach ($t in $tileDefs) {
        $sw = New-Object System.Windows.Forms.Panel
        $sw.Width = 46; $sw.Height = 46; $sw.Margin = '3,3,3,3'
        $sw.Tag = [int]$t.id
        $tip.SetToolTip($sw, ("{0}  (id {1}){2}" -f $t.name, $t.id, $(if(Is-Solid([int]$t.id)){"  [solid]"}else{""})))
        $sw.Add_Paint({
            param($s,$e)
            $id = [int]$s.Tag
            if ($script:tileImg.ContainsKey($id)) {
                $e.Graphics.DrawImage($script:tileImg[$id], 3, 3, 40, 40)
            } else {
                $br = New-Object System.Drawing.SolidBrush (Get-TileColor $id)
                $e.Graphics.FillRectangle($br, 3, 3, 40, 40); $br.Dispose()
                $f = New-Object System.Drawing.Font("Segoe UI", 7)
                $tb = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
                $e.Graphics.DrawString([string]$id, $f, $tb, 4, 30)
                $f.Dispose(); $tb.Dispose()
            }
            $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::Black), 1
            $e.Graphics.DrawRectangle($pen, 3, 3, 40, 40); $pen.Dispose()
            if ($id -eq $script:brush) {
                $hp = New-Object System.Drawing.Pen ([System.Drawing.Color]::Red), 3
                $e.Graphics.DrawRectangle($hp, 1, 1, 43, 43); $hp.Dispose()
            }
        })
        $sw.Add_Click({
            param($s,$e)
            $script:brush = [int]$s.Tag
            foreach ($w in $script:swatches) { $w.Invalidate() }
            Update-Status
        })
        $pal.Controls.Add($sw)
        $script:swatches += $sw
    }
}

# ============================================================================
#  Rendering
# ============================================================================
function Rebuild-TileArt {
    $script:tileImg = @{}
    if ($script:tileSrc.Count -eq 0) { return }
    foreach ($id in $script:tileSrc.Keys) {
        $src = $script:tileSrc[$id]
        $scaled = New-Object System.Drawing.Bitmap ($script:ts), ($script:ts)
        $g = [System.Drawing.Graphics]::FromImage($scaled)
        $g.InterpolationMode = 'NearestNeighbor'
        $g.PixelOffsetMode   = 'HighQuality'
        $g.DrawImage($src, 0, 0, $script:ts, $script:ts)
        $g.Dispose()
        $script:tileImg[$id] = $scaled
    }
    foreach ($w in $script:swatches) { $w.Invalidate() }
}

function Draw-Cell([int]$r,[int]$c) {
    if ($null -eq $script:gfx) { return }
    $x = $c * $script:ts; $y = $r * $script:ts
    $id = $script:grid[$r][$c]
    if ($script:tileImg.ContainsKey($id)) {
        $script:gfx.DrawImage($script:tileImg[$id], $x, $y, $script:ts, $script:ts)
    } else {
        $br = New-Object System.Drawing.SolidBrush (Get-TileColor $id)
        $script:gfx.FillRectangle($br, $x, $y, $script:ts, $script:ts); $br.Dispose()
    }
    if ($script:showGrid) {
        $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(70,0,0,0)), 1
        $script:gfx.DrawRectangle($pen, $x, $y, $script:ts, $script:ts); $pen.Dispose()
    }
    # NPC dialogue marker
    $key = "$c,$r"
    if ($script:npc.ContainsKey($key)) {
        $d = [Math]::Max(6, [int]($script:ts/3))
        $mb = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(230,255,215,0))
        $script:gfx.FillEllipse($mb, $x + $script:ts - $d - 1, $y + 1, $d, $d); $mb.Dispose()
        $mp = New-Object System.Drawing.Pen ([System.Drawing.Color]::Black), 1
        $script:gfx.DrawEllipse($mp, $x + $script:ts - $d - 1, $y + 1, $d, $d); $mp.Dispose()
    }
    if ($key -eq $script:selectedNpcKey) {
        $hp = New-Object System.Drawing.Pen ([System.Drawing.Color]::Red), 2
        $script:gfx.DrawRectangle($hp, $x+1, $y+1, $script:ts-2, $script:ts-2); $hp.Dispose()
    }
    if ($key -eq $script:movingKey) {
        $hp = New-Object System.Drawing.Pen ([System.Drawing.Color]::Cyan), 2
        $script:gfx.DrawRectangle($hp, $x+1, $y+1, $script:ts-2, $script:ts-2); $hp.Dispose()
    }
    if ($script:showIds) {
        $f = New-Object System.Drawing.Font("Segoe UI", 7)
        $tb = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(230,255,255,255))
        $script:gfx.DrawString([string]$id, $f, $tb, $x+1, $y+1)
        $f.Dispose(); $tb.Dispose()
    }
}

function Rebuild-Canvas {
    if ($script:gfx) { $script:gfx.Dispose(); $script:gfx = $null }
    if ($script:bmp) { $script:bmp.Dispose() }
    $w = [Math]::Max(1, $script:cols * $script:ts)
    $h = [Math]::Max(1, $script:rows * $script:ts)
    $script:bmp = New-Object System.Drawing.Bitmap $w, $h
    $script:gfx = [System.Drawing.Graphics]::FromImage($script:bmp)
    for ($r=0; $r -lt $script:rows; $r++) {
        for ($c=0; $c -lt $script:cols; $c++) { Draw-Cell $r $c }
    }
    $canvas.Image = $script:bmp
    $canvas.Refresh()
}

function Update-Status {
    $f = if ($script:file) { Split-Path $script:file -Leaf } else { "(unsaved)" }
    $art = if ($script:tileSrc.Count -gt 0) { "art:on" } else { "art:off" }
    $d = if ($script:dirty) { "*" } else { "" }
    $mode = if ($script:npcMode) { "NPC-LINK (click an NPC)" } else { "brush: $(Get-TileName $script:brush) (id $($script:brush))" }
    $nc = $script:npc.Count
    $status.Text = ("  {0}{1}   |   {2}x{3}   |   {4}   |   NPCs linked: {5}   |   {6}" -f `
        $f, $d, $script:rows, $script:cols, $mode, $nc, $art)
}

# ============================================================================
#  Editing
# ============================================================================
function Paint-Cell([int]$r,[int]$c,[int]$id) {
    if ($r -lt 0 -or $c -lt 0 -or $r -ge $script:rows -or $c -ge $script:cols) { return }
    if ($script:grid[$r][$c] -eq $id) { return }
    $script:grid[$r][$c] = $id
    Draw-Cell $r $c
    $rect = New-Object System.Drawing.Rectangle ($c*$script:ts), ($r*$script:ts), $script:ts, $script:ts
    $canvas.Invalidate($rect)
    $script:dirty = $true
}

function Flood-Fill([int]$r,[int]$c,[int]$id) {
    $target = $script:grid[$r][$c]
    if ($target -eq $id) { return }
    $stack = New-Object System.Collections.Stack
    $stack.Push(@($r,$c))
    while ($stack.Count -gt 0) {
        $p = $stack.Pop(); $pr=$p[0]; $pc=$p[1]
        if ($pr -lt 0 -or $pc -lt 0 -or $pr -ge $script:rows -or $pc -ge $script:cols) { continue }
        if ($script:grid[$pr][$pc] -ne $target) { continue }
        $script:grid[$pr][$pc] = $id
        $stack.Push(@($pr+1,$pc)); $stack.Push(@($pr-1,$pc))
        $stack.Push(@($pr,$pc+1)); $stack.Push(@($pr,$pc-1))
    }
    $script:dirty = $true
    Rebuild-Canvas
}

# ============================================================================
#  NPC dialogue linking
# ============================================================================
function Get-DataDir {
    if ($script:file) { return (Split-Path $script:file -Parent) }
    if ($script:tilesDir) { return $script:tilesDir }
    return (Get-Location).Path
}

# List existing .npc files in the map's folder (so you can pick one)
function Get-NpcChoices {
    $dir = Get-DataDir
    $list = @()
    try {
        $list = Get-ChildItem -Path $dir -Filter *.npc -File -ErrorAction SilentlyContinue |
                Sort-Object Name | ForEach-Object { $_.Name }
    } catch {}
    return $list
}

# --- simple .npc text editor (pages of text + up to 3 responses) -------------
function Edit-NpcFile([string]$dir, [string]$fname) {
    $path = Join-Path $dir $fname
    $existing = ""
    if (Test-Path $path) { $existing = [System.IO.File]::ReadAllText($path) }

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "Edit dialogue - $fname"
    $dlg.Size = New-Object System.Drawing.Size(560, 560)
    $dlg.StartPosition = "CenterParent"
    $dlg.BackColor = [System.Drawing.Color]::FromArgb(45,45,48)

    $help = New-Object System.Windows.Forms.Label
    $help.Text = "One page per conversation screen. Put the lines the NPC says (up to 5), then`r`noptional replies as:   Reply text | jumpToPage   (0 or blank = close).`r`nSeparate pages with a line of only ---.  Keep to plain letters/numbers."
    $help.Dock = "Top"; $help.Height = 60; $help.ForeColor = "White"
    $dlg.Controls.Add($help)

    $box = New-Object System.Windows.Forms.TextBox
    $box.Multiline = $true; $box.ScrollBars = "Vertical"
    $box.Dock = "Fill"; $box.Font = New-Object System.Drawing.Font("Consolas", 10)
    $box.AcceptsReturn = $true
    $box.BackColor = [System.Drawing.Color]::FromArgb(30,30,32); $box.ForeColor = "White"
    $dlg.Controls.Add($box)
    $box.BringToFront()

    # Convert existing raw .npc into the friendly format, if any
    if ($existing.Trim() -ne "") {
        $box.Text = ConvertFrom-Npc $existing
    } else {
        $box.Text = "Hello there, traveler." + [Environment]::NewLine + "What brings you here?" + [Environment]::NewLine + [Environment]::NewLine + "Just passing through. | 0"
    }

    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.Dock = "Bottom"; $pnl.Height = 44; $pnl.BackColor = [System.Drawing.Color]::FromArgb(60,60,63)
    $dlg.Controls.Add($pnl)
    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = "Save dialogue"; $ok.Width = 130; $ok.Height = 32; $ok.Left = 300; $ok.Top = 6
    $ok.FlatStyle="Flat"; $ok.ForeColor="White"; $ok.BackColor=[System.Drawing.Color]::FromArgb(70,120,70)
    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = "Cancel"; $cancel.Width = 90; $cancel.Height = 32; $cancel.Left = 440; $cancel.Top = 6
    $cancel.FlatStyle="Flat"; $cancel.ForeColor="White"; $cancel.BackColor=[System.Drawing.Color]::FromArgb(90,90,94)
    $pnl.Controls.Add($ok); $pnl.Controls.Add($cancel)

    $ok.Add_Click({
        $raw = ConvertTo-Npc $box.Text
        try {
            [System.IO.File]::WriteAllText($path, $raw, [System.Text.Encoding]::ASCII)
            $dlg.Tag = "saved"; $dlg.Close()
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Could not save:`n$($_.Exception.Message)","Edit",'OK','Error')|Out-Null
        }
    })
    $cancel.Add_Click({ $dlg.Tag = $null; $dlg.Close() })
    [void]$dlg.ShowDialog($form)
    return ($dlg.Tag -eq "saved")
}

# Friendly text  ->  raw .npc  ("page" / 5 text / 3 responses, quoted, CRLF)
function ConvertTo-Npc([string]$friendly) {
    $nl = "`r`n"
    $lines = $friendly -split "`r?`n"
    # split into pages on lines that are only dashes
    $pages = @(); $cur = @()
    foreach ($ln in $lines) {
        if ($ln.Trim() -match '^-{3,}$') { $pages += ,$cur; $cur = @() }
        else { $cur += $ln }
    }
    $pages += ,$cur
    $sb = New-Object System.Text.StringBuilder
    $pnum = 0
    foreach ($pg in $pages) {
        # skip fully empty trailing page
        if (($pg -join "").Trim() -eq "" -and $pnum -gt 0) { continue }
        $pnum++
        $texts = @(); $resps = @()
        foreach ($raw in $pg) {
            $t = $raw.TrimEnd()
            if ($t.Trim() -eq "") { continue }
            if ($t -match '\|') {
                $parts = $t -split '\|', 2
                $rtext = ($parts[0]).Trim()
                $jump = 0; [void][int]::TryParse(($parts[1]).Trim(), [ref]$jump)
                $resps += @{ text = $rtext; jump = $jump }
            } else {
                $texts += $t
            }
        }
        # clamp to engine limits: 5 text, 3 responses
        while ($texts.Count -lt 5) { $texts += " " }
        if ($texts.Count -gt 5) { $texts = $texts[0..4] }
        [void]$sb.Append('"' + $pnum + '"' + $nl)
        foreach ($tx in $texts) { [void]$sb.Append('"' + (Clean-Ascii $tx) + '"' + $nl) }
        for ($i=0; $i -lt 3; $i++) {
            if ($i -lt $resps.Count) {
                [void]$sb.Append('"' + (Clean-Ascii $resps[$i].text) + '",' + $resps[$i].jump + $nl)
            } else {
                [void]$sb.Append('"",0' + $nl)
            }
        }
    }
    return $sb.ToString()
}

# raw .npc  ->  friendly text  (best-effort, for re-editing)
function ConvertFrom-Npc([string]$raw) {
    $nl = [Environment]::NewLine
    $lines = ($raw -split "`r?`n") | Where-Object { $_.Trim() -ne "" }
    $out = @()
    $i = 0
    $firstPage = $true
    while ($i -lt $lines.Count) {
        $ln = $lines[$i].Trim()
        # page header = a quoted pure number
        if ($ln -match '^"?\d+"?$') {
            if (-not $firstPage) { $out += "---" }
            $firstPage = $false
            $i++
            # collect up to 5 text lines (quoted, no comma-jump)
            $tcount = 0
            while ($i -lt $lines.Count -and $tcount -lt 5) {
                $l = $lines[$i]
                if ($l -match '^\s*"[^"]*"\s*,') { break }         # a response
                if ($l.Trim() -match '^"?\d+"?$') { break }        # next page
                $inner = $l.Trim()
                if ($inner.StartsWith('"')) {
                    $q2 = $inner.IndexOf('"',1)
                    if ($q2 -ge 1) { $inner = $inner.Substring(1, $q2-1) }
                }
                if ($inner.Trim() -ne "") { $out += $inner }
                $i++; $tcount++
            }
            # collect up to 3 responses
            $rcount = 0
            while ($i -lt $lines.Count -and $rcount -lt 3) {
                $l = $lines[$i]
                if ($l -match '^\s*"([^"]*)"\s*,\s*(-?\d+)') {
                    $rt = $Matches[1]; $rj = $Matches[2]
                    if ($rt.Trim() -ne "") { $out += ("{0} | {1}" -f $rt, $rj) }
                    $i++; $rcount++
                } else { break }
            }
        } else { $i++ }
    }
    return ($out -join $nl)
}

function Clean-Ascii([string]$s) {
    if ($null -eq $s) { return "" }
    $s = $s -replace [char]0x2019, "'" -replace [char]0x2018, "'"
    $s = $s -replace [char]0x201C, '"' -replace [char]0x201D, '"'
    $s = $s -replace [char]0x2014, '-' -replace [char]0x2013, '-'
    $s = $s -replace [char]0x2026, '...'
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $s.ToCharArray()) {
        if ([int]$ch -ge 32 -and [int]$ch -le 126) { [void]$sb.Append($ch) }
    }
    return $sb.ToString()
}

# --- the dialog that appears when you click an NPC in NPC mode ---------------
function Assign-Npc([int]$r,[int]$c) {
    $key = "$c,$r"
    $tileId = $script:grid[$r][$c]
    $dir = Get-DataDir
    $existing = $null
    if ($script:npc.ContainsKey($key)) { $existing = $script:npc[$key] }

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "NPC at column $c, row $r  (tile $tileId - $(Get-TileName $tileId))"
    $dlg.Size = New-Object System.Drawing.Size(460, 340)
    $dlg.StartPosition = "CenterParent"
    $dlg.BackColor = [System.Drawing.Color]::FromArgb(45,45,48)
    $dlg.FormBorderStyle = "FixedDialog"; $dlg.MaximizeBox=$false; $dlg.MinimizeBox=$false

    $lblName = New-Object System.Windows.Forms.Label
    $lblName.Text = "Name (how it shows in the NPC list):"
    $lblName.Left=16; $lblName.Top=14; $lblName.Width=400; $lblName.ForeColor="White"
    $dlg.Controls.Add($lblName)

    $nameBox = New-Object System.Windows.Forms.TextBox
    $nameBox.Left=16; $nameBox.Top=38; $nameBox.Width=410
    if ($existing) { $nameBox.Text = $existing.name } else { $nameBox.Text = "" }
    $dlg.Controls.Add($nameBox)

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Dialogue file this NPC should say:"
    $lbl.Left=16; $lbl.Top=70; $lbl.Width=400; $lbl.ForeColor="White"
    $dlg.Controls.Add($lbl)

    $combo = New-Object System.Windows.Forms.ComboBox
    $combo.Left=16; $combo.Top=94; $combo.Width=410; $combo.DropDownStyle="DropDown"
    foreach ($n in (Get-NpcChoices)) { [void]$combo.Items.Add($n) }
    if ($existing) { $combo.Text = $existing.file }
    $dlg.Controls.Add($combo)

    $hint = New-Object System.Windows.Forms.Label
    $hint.Text = "Pick an existing file, or type a new name (e.g. mytalk.npc) and click Edit Text."
    $hint.Left=16; $hint.Top=124; $hint.Width=410; $hint.Height=28; $hint.ForeColor="#B9B9C0"
    $dlg.Controls.Add($hint)

    $btnEdit = New-Object System.Windows.Forms.Button
    $btnEdit.Text="Edit Text..."; $btnEdit.Left=16; $btnEdit.Top=156; $btnEdit.Width=130; $btnEdit.Height=34
    $btnEdit.FlatStyle="Flat"; $btnEdit.ForeColor="White"; $btnEdit.BackColor=[System.Drawing.Color]::FromArgb(70,90,130)
    $dlg.Controls.Add($btnEdit)

    $btnPreview = New-Object System.Windows.Forms.Button
    $btnPreview.Text="Preview"; $btnPreview.Left=156; $btnPreview.Top=156; $btnPreview.Width=100; $btnPreview.Height=34
    $btnPreview.FlatStyle="Flat"; $btnPreview.ForeColor="White"; $btnPreview.BackColor=[System.Drawing.Color]::FromArgb(80,80,84)
    $dlg.Controls.Add($btnPreview)

    $btnMove = New-Object System.Windows.Forms.Button
    $btnMove.Text="Move..."; $btnMove.Left=266; $btnMove.Top=156; $btnMove.Width=100; $btnMove.Height=34
    $btnMove.FlatStyle="Flat"; $btnMove.ForeColor="White"; $btnMove.BackColor=[System.Drawing.Color]::FromArgb(60,110,120)
    $btnMove.Enabled = ($null -ne $existing)
    $dlg.Controls.Add($btnMove)

    $btnAssign = New-Object System.Windows.Forms.Button
    $btnAssign.Text="Assign"; $btnAssign.Left=210; $btnAssign.Top=250; $btnAssign.Width=100; $btnAssign.Height=34
    $btnAssign.FlatStyle="Flat"; $btnAssign.ForeColor="White"; $btnAssign.BackColor=[System.Drawing.Color]::FromArgb(70,120,70)
    $dlg.Controls.Add($btnAssign)

    $btnClear = New-Object System.Windows.Forms.Button
    $btnClear.Text="Remove link"; $btnClear.Left=16; $btnClear.Top=250; $btnClear.Width=110; $btnClear.Height=34
    $btnClear.FlatStyle="Flat"; $btnClear.ForeColor="White"; $btnClear.BackColor=[System.Drawing.Color]::FromArgb(130,70,70)
    $dlg.Controls.Add($btnClear)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text="Cancel"; $btnCancel.Left=326; $btnCancel.Top=250; $btnCancel.Width=100; $btnCancel.Height=34
    $btnCancel.FlatStyle="Flat"; $btnCancel.ForeColor="White"; $btnCancel.BackColor=[System.Drawing.Color]::FromArgb(90,90,94)
    $dlg.Controls.Add($btnCancel)

    $btnEdit.Add_Click({
        $fn = $combo.Text.Trim()
        if ($fn -eq "") { [System.Windows.Forms.MessageBox]::Show("Type or pick a file name first.","Edit",'OK','Information')|Out-Null; return }
        if ($fn -notmatch '\.npc$') { $fn = $fn + ".npc"; $combo.Text = $fn }
        if (Edit-NpcFile $dir $fn) {
            if (-not $combo.Items.Contains($fn)) { [void]$combo.Items.Add($fn) }
        }
    })
    $btnPreview.Add_Click({
        $fn = $combo.Text.Trim()
        $pp = Join-Path $dir $fn
        if (Test-Path $pp) {
            $raw = [System.IO.File]::ReadAllText($pp)
            [System.Windows.Forms.MessageBox]::Show((ConvertFrom-Npc $raw), "Preview - $fn",'OK','Information')|Out-Null
        } else {
            [System.Windows.Forms.MessageBox]::Show("That file doesn't exist yet. Use Edit Text to create it.","Preview",'OK','Information')|Out-Null
        }
    })
    $btnMove.Add_Click({
        $script:moveMode = $true
        $script:movingKey = $key
        $btnNpc2 = $null
        $status.Text = "  Click the cell you want to move '$($nameBox.Text)' to. Esc on canvas... (just click NPC Link off to cancel)"
        $dlg.Close()
    })
    $btnAssign.Add_Click({
        $fn = $combo.Text.Trim()
        if ($fn -eq "") { [System.Windows.Forms.MessageBox]::Show("Pick or type a dialogue file.","Assign",'OK','Information')|Out-Null; return }
        if ($fn -notmatch '\.npc$') { $fn = $fn + ".npc" }
        $nm = $nameBox.Text.Trim()
        if ($nm -eq "") { $nm = [System.IO.Path]::GetFileNameWithoutExtension($fn) }
        $id = if ($existing) { $existing.id } else { $newId = "npc_$($script:nextNpcId)"; $script:nextNpcId++; $newId }
        $script:npc[$key] = @{ id = $id; name = $nm; file = $fn.ToLower() }
        $script:dirty = $true
        if ($script:file) { Save-Npcs $script:file }   # persist the link immediately - don't rely on a later Save click
        $dlg.Close()
        Rebuild-Canvas; Refresh-NpcList; Update-Status
    })
    $btnClear.Add_Click({
        if ($script:npc.ContainsKey($key)) { $script:npc.Remove($key); $script:dirty=$true }
        if ($script:file) { Save-Npcs $script:file }
        $dlg.Close(); Rebuild-Canvas; Refresh-NpcList; Update-Status
    })
    $btnCancel.Add_Click({ $dlg.Close() })

    [void]$dlg.ShowDialog($form)
}

# Finish a pick-up-and-drop move: relocate the tile + its dialogue link together
function Complete-NpcMove([int]$destRow,[int]$destCol) {
    $oldKey = $script:movingKey
    $cr = $oldKey -split ','
    $oldCol = [int]$cr[0]; $oldRow = [int]$cr[1]
    $newKey = "$destCol,$destRow"

    if ($newKey -eq $oldKey) {
        $script:moveMode=$false; $script:movingKey=$null; Rebuild-Canvas; Update-Status; return
    }
    if ($script:npc.ContainsKey($newKey)) {
        [System.Windows.Forms.MessageBox]::Show("That cell already has a linked NPC. Pick an empty cell.","Move",'OK','Warning')|Out-Null
        return
    }
    $npcTileId = $script:grid[$oldRow][$oldCol]
    $vac = [Microsoft.VisualBasic.Interaction]::InputBox("Tile ID to leave behind at the old spot (3=Path 1, 1=Grass 1, 0=Black):","Move NPC - vacate old spot","3")
    if ($vac -eq "") { return }
    $vacId = 3
    [void][int]::TryParse($vac,[ref]$vacId)

    $script:grid[$oldRow][$oldCol] = $vacId
    $script:grid[$destRow][$destCol] = $npcTileId
    $script:npc[$newKey] = $script:npc[$oldKey]
    $script:npc.Remove($oldKey)
    $script:selectedNpcKey = $newKey
    $script:dirty = $true
    $script:moveMode = $false
    $script:movingKey = $null
    if ($script:file) { Save-Npcs $script:file }
    Rebuild-Canvas
    Refresh-NpcList
    Update-Status
    $status.Text = "  NPC moved. Dialogue link saved - click the main Save button too, to save the tile move itself."
}

# ============================================================================
#  File I/O   (.map  +  .npcs companion)
# ============================================================================
function NpcsPathFor([string]$mapPath) {
    $dir = Split-Path $mapPath -Parent
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($mapPath)
    return (Join-Path $dir ($stem + ".npcs"))
}

function Load-Npcs([string]$mapPath) {
    $script:npc = @{}
    $script:nextNpcId = 1
    $p = NpcsPathFor $mapPath
    if (-not (Test-Path $p)) { return }

    # first pass: read #meta lines -> lookup by 1-based "col,row" => id,name
    $meta = @{}
    foreach ($line in [System.IO.File]::ReadAllLines($p)) {
        $t = $line.Trim()
        if ($t.StartsWith("#meta ")) {
            $body = $t.Substring(6)
            $mp = $body -split ',', 4
            if ($mp.Count -ge 4) {
                $meta["$($mp[0]),$($mp[1])"] = @{ id = $mp[2]; name = $mp[3] }
            }
        }
    }

    # second pass: read real col,row,file lines (these are what the game reads)
    foreach ($line in [System.IO.File]::ReadAllLines($p)) {
        $t = $line.Trim()
        if ($t -eq "" -or $t.StartsWith("#")) { continue }
        $parts = $t -split ',', 3
        if ($parts.Count -ge 3) {
            $col=0;$row=0
            if ([int]::TryParse($parts[0].Trim(),[ref]$col) -and [int]::TryParse($parts[1].Trim(),[ref]$row)) {
                $file = $parts[2].Trim().ToLower()
                $mkey = "$col,$row"
                $id = $null; $name = $null
                if ($meta.ContainsKey($mkey)) { $id = $meta[$mkey].id; $name = $meta[$mkey].name }
                if (-not $id) { $id = "npc_$($script:nextNpcId)" }
                if (-not $name -or $name -eq "") { $name = [System.IO.Path]::GetFileNameWithoutExtension($file) }
                $numPart = ($id -replace '[^\d]','')
                if ($numPart -ne "" -and [int]$numPart -ge $script:nextNpcId) { $script:nextNpcId = [int]$numPart + 1 }
                # .npcs stores 1-based col/row (matching the game's array indices).
                # The editor's grid is 0-based, so convert on the way in.
                $script:npc["$($col-1),$($row-1)"] = @{ id = $id; name = $name; file = $file }
            }
        }
    }
}

function Save-Npcs([string]$mapPath) {
    $p = NpcsPathFor $mapPath
    if ($script:npc.Count -eq 0) {
        if (Test-Path $p) { Remove-Item $p -ErrorAction SilentlyContinue }
        return
    }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("# ARAXIA NPC dialogue links for $(Split-Path $mapPath -Leaf)`r`n")
    [void]$sb.Append("# format: col,row,dialoguefile.npc  (1-based - matches the game's map array)`r`n")
    [void]$sb.Append("# #meta lines are editor-only bookkeeping (id/name); the game ignores all # lines.`r`n")
    foreach ($k in ($script:npc.Keys | Sort-Object)) {
        $cr = $k -split ','
        $wcol = [int]$cr[0] + 1
        $wrow = [int]$cr[1] + 1
        $obj = $script:npc[$k]
        [void]$sb.Append(("#meta {0},{1},{2},{3}`r`n" -f $wcol, $wrow, $obj.id, $obj.name))
        [void]$sb.Append(("{0},{1},{2}`r`n" -f $wcol, $wrow, $obj.file))
    }
    [System.IO.File]::WriteAllText($p, $sb.ToString(), [System.Text.Encoding]::ASCII)
}

function Load-Map([string]$path) {
    try {
        # Reads BOTH the plain format (one id per tile) and the new RLE + #WARPS
        # format. RLE token is "V:N" (N copies of V); a bare "V" is one tile.
        # The warp section (#WARPS or [Warps] .. EOF) is stashed verbatim so a
        # later Save writes it back unchanged instead of dropping it.
        $lines = [System.IO.File]::ReadAllLines($path)
        if ($lines.Count -lt 1) { throw "Empty file." }

        $hdr = $lines[0].Trim() -split ','
        if ($hdr.Count -lt 2) { throw "No dimensions on line 1." }
        $r = [int]$hdr[0].Trim(); $c = [int]$hdr[1].Trim()
        if ($r -le 0 -or $c -le 0 -or $r -gt 500 -or $c -gt 500) { throw "Bad dimensions: $r x $c" }

        $g = New-Grid $r $c 0
        $total = $r * $c
        $filled = 0; $ci = 0; $cj = 0
        $li = 1
        $script:warpBlock = ""

        # ---- tile section (stop at the warp marker or once the grid is full) ----
        while ($li -lt $lines.Count -and $filled -lt $total) {
            $ln = $lines[$li].Trim()
            if ($ln -eq "#WARPS" -or $ln.ToUpper() -eq "[WARPS]") { break }
            $li++
            if ($ln -eq "" -or $ln[0] -eq '#' -or $ln[0] -eq "'") { continue }
            foreach ($tok in ($ln -split ',')) {
                $tok = $tok.Trim()
                if ($tok -eq "" -or $filled -ge $total) { continue }
                if ($tok.Contains(':')) {
                    $pair = $tok -split ':'
                    $v = [int]$pair[0]; $cnt = [int]$pair[1]
                } else { $v = [int]$tok; $cnt = 1 }
                for ($n=0; $n -lt $cnt -and $filled -lt $total; $n++) {
                    $g[$ci][$cj] = $v
                    $cj++; if ($cj -ge $c) { $cj = 0; $ci++ }
                    $filled++
                }
            }
        }

        # ---- find the warp marker (if any) and stash from there to EOF ----
        while ($li -lt $lines.Count) {
            $t = $lines[$li].Trim()
            if ($t -eq "#WARPS" -or $t.ToUpper() -eq "[WARPS]") { break }
            $li++
        }
        if ($li -lt $lines.Count) {
            $rest = @()
            for ($x = $li; $x -lt $lines.Count; $x++) { $rest += $lines[$x] }
            $script:warpBlock = (($rest -join "`r`n").TrimEnd() + "`r`n")
        }

        $script:rows=$r; $script:cols=$c; $script:grid=$g
        $script:file=$path; $script:dirty=$false
        $script:selectedNpcKey=$null; $script:moveMode=$false; $script:movingKey=$null
        Load-Npcs $path
        Rebuild-Canvas; Refresh-NpcList; Update-Status
        $wn = 0; if ($script:warpBlock -ne "") { $wn = (($script:warpBlock -split "`r`n") | Where-Object { $_ -ne "" -and $_[0] -ne '#' -and $_[0] -ne "'" -and $_.Trim().ToUpper() -ne "[WARPS]" }).Count }
        $status.Text = "  Loaded $([System.IO.Path]::GetFileName($path))  ($r x $c), $($script:npc.Count) NPC link(s), $wn warp(s) preserved"
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Could not read map:`n$($_.Exception.Message)","Open",'OK','Error') | Out-Null
    }
}

function Read-WarpsSection([string]$path) {
    # Returns the existing warp block (#WARPS or [Warps], marker + lines to EOF)
    # verbatim, or "" if there isn't one.
    if (-not (Test-Path $path)) { return "" }
    $lines = [System.IO.File]::ReadAllLines($path)
    $out = @()
    $inWarps = $false
    foreach ($ln in $lines) {
        if (-not $inWarps -and ($ln.Trim() -eq "#WARPS" -or $ln.Trim().ToUpper() -eq "[WARPS]")) {
            $inWarps = $true; $out += $ln.Trim(); continue
        }
        if ($inWarps) { $out += $ln }
    }
    if ($out.Count -eq 0) { return "" }
    return (($out -join "`r`n").TrimEnd() + "`r`n")
}

function Save-Map([string]$path) {
    try {
        # Prefer the warp section we stashed when this map was loaded. If the map
        # on disk has one we didn't capture (e.g. Save As over another file), fall
        # back to whatever is already in the target so warps are never lost.
        $warps = $script:warpBlock
        if (($warps -eq $null) -or ($warps.Trim() -eq "")) { $warps = Read-WarpsSection $path }

        $sb = New-Object System.Text.StringBuilder
        [void]$sb.Append("$($script:rows),$($script:cols)`r`n")
        for ($i=0; $i -lt $script:rows; $i++) {
            [void]$sb.Append(([string]::Join(",", $script:grid[$i])))
            [void]$sb.Append("`r`n")
        }
        if ($warps -and $warps.Trim() -ne "") {
            if (-not $warps.StartsWith("#WARPS") -and $warps.Trim().ToUpper() -notlike "`[WARPS`]*") {
                [void]$sb.Append("#WARPS`r`n")
            }
            [void]$sb.Append($warps)
        }
        [System.IO.File]::WriteAllText($path, $sb.ToString(), [System.Text.Encoding]::ASCII)
        $script:file=$path; $script:dirty=$false
        Save-Npcs $path
        Update-Status
        $warpNote = if ($warps -and $warps.Trim() -ne "") { " (+ warps preserved)" } else { "" }
        $status.Text = "  Saved $([System.IO.Path]::GetFileName($path))  (+ .npcs with $($script:npc.Count) link(s))$warpNote"
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Could not save:`n$($_.Exception.Message)","Save",'OK','Error') | Out-Null
    }
}

# ============================================================================
#  Toolbar actions
# ============================================================================
$btnNew.Add_Click({
    $rIn = [Microsoft.VisualBasic.Interaction]::InputBox("Rows (height):","New Map","30")
    if ($rIn -eq "") { return }
    $cIn = [Microsoft.VisualBasic.Interaction]::InputBox("Cols (width):","New Map","50")
    if ($cIn -eq "") { return }
    $r = 0; $c = 0
    if (-not [int]::TryParse($rIn,[ref]$r) -or -not [int]::TryParse($cIn,[ref]$c)) { return }
    if ($r -le 0 -or $c -le 0 -or $r -gt 500 -or $c -gt 500) {
        [System.Windows.Forms.MessageBox]::Show("Use 1..500 for rows and cols.","New",'OK','Warning')|Out-Null; return
    }
    $script:rows=$r; $script:cols=$c
    $script:grid = New-Grid $r $c 1
    $script:file=$null; $script:dirty=$false; $script:npc=@{}; $script:warpBlock=""
    $script:selectedNpcKey=$null; $script:moveMode=$false; $script:movingKey=$null
    Rebuild-Canvas; Refresh-NpcList; Update-Status
})

$btnOpen.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "Map files (*.map)|*.map|All files (*.*)|*.*"
    if ($dlg.ShowDialog() -eq "OK") { Load-Map $dlg.FileName }
})

$btnSave.Add_Click({
    if ($script:file) { Save-Map $script:file } else { $btnSaveAs.PerformClick() }
})

$btnSaveAs.Add_Click({
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = "Map files (*.map)|*.map|All files (*.*)|*.*"
    $dlg.FileName = if ($script:file) { Split-Path $script:file -Leaf } else { "map01.map" }
    if ($dlg.ShowDialog() -eq "OK") { Save-Map $dlg.FileName }
})

$btnArt.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Pick the folder that holds the game's .mdt tiles (and a .pal)."
    if ($dlg.ShowDialog() -ne "OK") { return }
    $dir = $dlg.SelectedPath
    $palFile = Get-ChildItem -Path $dir -Filter *.pal -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $palFile) {
        [System.Windows.Forms.MessageBox]::Show("No .pal palette file found in that folder.`nTile art needs the game's palette (e.g. nmedia.pal).","Load Tile Art",'OK','Warning')|Out-Null
        return
    }
    $palette = Load-Palette $palFile.FullName
    if ($null -eq $palette) {
        [System.Windows.Forms.MessageBox]::Show("Could not read the palette file.","Load Tile Art",'OK','Error')|Out-Null; return
    }
    $script:tilesDir = $dir
    $script:tileSrc = @{}
    $loaded = 0
    foreach ($t in $tileDefs) {
        $p = Join-Path $dir $t.file
        if (Test-Path $p) {
            $bmp = Decode-Mdt $p $palette
            if ($bmp) { $script:tileSrc[[int]$t.id] = $bmp; $loaded++ }
        }
    }
    Rebuild-TileArt
    Rebuild-Canvas
    Update-Status
    $status.Text = "  Loaded art for $loaded tiles from $(Split-Path $dir -Leaf) (palette: $($palFile.Name))"
})

$btnResize.Add_Click({
    $rIn = [Microsoft.VisualBasic.Interaction]::InputBox("Rows (height):","Resize",[string]$script:rows)
    if ($rIn -eq "") { return }
    $cIn = [Microsoft.VisualBasic.Interaction]::InputBox("Cols (width):","Resize",[string]$script:cols)
    if ($cIn -eq "") { return }
    $r=0;$c=0
    if (-not [int]::TryParse($rIn,[ref]$r) -or -not [int]::TryParse($cIn,[ref]$c)) { return }
    if ($r -le 0 -or $c -le 0 -or $r -gt 500 -or $c -gt 500) { return }
    $ng = New-Grid $r $c 1
    for ($i=0; $i -lt [Math]::Min($r,$script:rows); $i++){
        for ($j=0; $j -lt [Math]::Min($c,$script:cols); $j++){ $ng[$i][$j] = $script:grid[$i][$j] }
    }
    $script:rows=$r; $script:cols=$c; $script:grid=$ng; $script:dirty=$true
    Rebuild-Canvas; Update-Status
})

$btnBucket.Add_Click({
    $script:bucket = -not $script:bucket
    $btnBucket.Text = if ($script:bucket) { "Bucket: On" } else { "Bucket: Off" }
    if ($script:bucket -and $script:npcMode) {
        $script:npcMode = $false; $btnNpc.Text = "NPC Link: Off"
    }
    Update-Status
})

$btnNpc.Add_Click({
    $script:npcMode = -not $script:npcMode
    $btnNpc.Text = if ($script:npcMode) { "NPC Link: ON" } else { "NPC Link: Off" }
    if ($script:npcMode) {
        $script:bucket = $false; $btnBucket.Text = "Bucket: Off"
    }
    Update-Status
})

$btnIds.Add_Click({
    $script:showIds = -not $script:showIds
    $btnIds.Text = if ($script:showIds) { "IDs: On" } else { "IDs: Off" }
    Rebuild-Canvas
})

$btnZoomIn.Add_Click({
    if ($script:ts -lt 48) { $script:ts += 4; Rebuild-TileArt; Rebuild-Canvas; Update-Status }
})
$btnZoomOut.Add_Click({
    if ($script:ts -gt 8) { $script:ts -= 4; Rebuild-TileArt; Rebuild-Canvas; Update-Status }
})

$btnWorld.Add_Click({ Show-WorldView })
$btnTeleport.Add_Click({ Show-TeleportTable })

# ============================================================================
#  Canvas mouse handling
# ============================================================================
$script:painting = $false

#-----------------------------------------------------------------------------
#  World View: parses ARAXIA.BAS for the compass edge-scroll grid and the
#  AddPortal warp points, lays out every map geographically, and shows it
#  all in one window. Click a box to load that map into the main editor.
#-----------------------------------------------------------------------------
function Parse-CompassGraph([string]$basPath) {
    $content = [System.IO.File]::ReadAllText($basPath)
    # find every "Select Case WorldData.Place ... End Select" block, then use
    # the one that actually contains lmap$ assignments (the edge-scroll table) -
    # the file has other unrelated Select Case WorldData.Place blocks too.
    $blockMatches = [regex]::Matches($content, '(?s)Select Case WorldData\.Place\r?\n(.*?)\r?\n\s*End Select')
    $target = $null
    foreach ($bm in $blockMatches) {
        if ($bm.Groups[1].Value -match 'lmap\$\s*=') { $target = $bm.Groups[1].Value; break }
    }
    $graph = @{}   # place -> @{ N=place; S=place; E=place; W=place }
    $placeFiles = @{}   # place -> actual map filename, parsed from lmap$ (not guessed)
    if (-not $target) { return @{ Graph = $graph; Files = $placeFiles } }

    $caseMatches = [regex]::Matches($target, '(?s)Case\s+(\d+)\s*\r?\n(.*?)(?=\r?\n\s*Case\s+\d|\z)')
    foreach ($cm in $caseMatches) {
        $place = [int]$cm.Groups[1].Value
        $body = $cm.Groups[2].Value
        $dirs = @{}
        foreach ($lm in [regex]::Matches($body, 'Direc\s*=\s*(North|South|East|West)\s+Then\s+lmap\$\s*=\s*"([^"]+)"\s*:\s*Place\s*=\s*(\d+)')) {
            $d = $lm.Groups[1].Value; $destFile = $lm.Groups[2].Value; $destPlace = [int]$lm.Groups[3].Value
            $key = switch ($d) { 'North'{'N'} 'South'{'S'} 'East'{'E'} 'West'{'W'} }
            $dirs[$key] = $destPlace
            $placeFiles[$destPlace] = $destFile
        }
        $graph[$place] = $dirs
    }
    return @{ Graph = $graph; Files = $placeFiles }
}

function Parse-Portals([string]$basPath) {
    $content = [System.IO.File]::ReadAllText($basPath)
    $portals = @()
    foreach ($m in [regex]::Matches($content, 'AddPortal\(\s*"([^"]+)"\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*"([^"]+)"\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*\)')) {
        $portals += [PSCustomObject]@{
            FromMap = $m.Groups[1].Value; FX = [int]$m.Groups[2].Value; FY = [int]$m.Groups[3].Value
            ToMap   = $m.Groups[4].Value; TX = [int]$m.Groups[5].Value; TY = [int]$m.Groups[6].Value
            ToPlace = [int]$m.Groups[7].Value; ToInside = [int]$m.Groups[8].Value
        }
    }
    return $portals
}

function Show-WorldView {
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = "Pick your ARAXIA.BAS (to read the map connections)"
    $dlg.Filter = "FreeBASIC source (*.bas)|*.bas|All files (*.*)|*.*"
    if ($script:file) {
        try { $dlg.InitialDirectory = Split-Path $script:file -Parent } catch {}
    }
    if ($dlg.ShowDialog() -ne "OK") { return }
    $basPath = $dlg.FileName
    $mapDir = Split-Path $basPath -Parent

    $parsed = Parse-CompassGraph $basPath
    $graph = $parsed.Graph
    $placeFiles = $parsed.Files
    $portals = Parse-Portals $basPath
    if ($graph.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Couldn't find the map connection table in that file.","World View",'OK','Warning')|Out-Null
        return
    }

    # ---- BFS layout of every compass-connected place, starting at Place 1 ----
    $pos = @{}                 # place -> @{col=;row=}
    $pos[1] = @{ col=0; row=0 }
    $queue = New-Object System.Collections.Queue
    $queue.Enqueue(1)
    $deltas = @{ N=@(0,-1); S=@(0,1); E=@(1,0); W=@(-1,0) }
    while ($queue.Count -gt 0) {
        $p = $queue.Dequeue()
        if (-not $graph.ContainsKey($p)) { continue }
        foreach ($dir in $graph[$p].Keys) {
            $np = $graph[$p][$dir]
            if (-not $pos.ContainsKey($np)) {
                $d = $deltas[$dir]
                $pos[$np] = @{ col = $pos[$p].col + $d[0]; row = $pos[$p].row + $d[1] }
                $queue.Enqueue($np)
            }
        }
    }

    # ---- places mentioned only via AddPortal (never reached by compass BFS) ----
    # e.g. quest zones like map12->map20->map21 that link only via a single door/warp
    $warpOnly = @()
    foreach ($por in $portals) {
        foreach ($mapName in @($por.FromMap, $por.ToMap)) {
            if ($mapName -notmatch '^mapin') {
                if ($mapName -match 'map0*(\d+)\.map') {
                    $pl = [int]$Matches[1]
                    if (-not $pos.ContainsKey($pl) -and ($warpOnly -notcontains $pl)) { $warpOnly += $pl }
                }
            }
        }
    }
    $wx = 0
    foreach ($pl in ($warpOnly | Sort-Object)) {
        $pos[$pl] = @{ col = 99; row = $wx }   # far right column, stacked - these aren't geographically adjacent
        $wx++
    }

    # ---- interiors: attach each mapinNN as a satellite of its outdoor Place ----
    $interiors = @{}   # place -> list of interior map names
    foreach ($por in $portals) {
        if ($por.ToMap -match '^mapin') {
            if (-not $interiors.ContainsKey($por.ToPlace)) { $interiors[$por.ToPlace] = @() }
            if ($interiors[$por.ToPlace] -notcontains $por.ToMap) { $interiors[$por.ToPlace] += $por.ToMap }
        }
    }

    # ---- warp arrows: portal links between two DIFFERENT outdoor places (not doors) ----
    $warpLinks = @()
    foreach ($por in $portals) {
        if ($por.FromMap -notmatch '^mapin' -and $por.ToMap -notmatch '^mapin') {
            if ($por.FromMap -match 'map0*(\d+)\.map') {
                $fromPl = [int]$Matches[1]
                if ($fromPl -ne $por.ToPlace) { $warpLinks += @{ from=$fromPl; to=$por.ToPlace } }
            }
        }
    }

    # ================= render =================
    $wf = New-Object System.Windows.Forms.Form
    $wf.Text = "Araxia World View - click a map to open it"
    $wf.Size = New-Object System.Drawing.Size(1000, 720)
    $wf.StartPosition = "CenterScreen"
    $wf.BackColor = [System.Drawing.Color]::FromArgb(28,28,30)

    $wHint = New-Object System.Windows.Forms.Label
    $wHint.Dock = "Top"; $wHint.Height = 26
    $wHint.Text = "  Layout follows the game's actual N/S/E/W map connections. Dashed lines = one-way warp portals. Small squares = building interiors. Click a box to open that map."
    $wHint.ForeColor = "#CFCFD6"; $wHint.BackColor = [System.Drawing.Color]::FromArgb(45,45,48)
    $wf.Controls.Add($wHint)

    $wScroll = New-Object System.Windows.Forms.Panel
    $wScroll.Dock = "Fill"; $wScroll.AutoScroll = $true
    $wScroll.BackColor = [System.Drawing.Color]::FromArgb(28,28,30)
    $wf.Controls.Add($wScroll)

    $cell = 130; $gap = 30; $pad = 60
    $minCol = ($pos.Values | ForEach-Object { $_.col } | Measure-Object -Minimum).Minimum
    $maxCol = ($pos.Values | ForEach-Object { $_.col } | Measure-Object -Maximum).Maximum
    $minRow = ($pos.Values | ForEach-Object { $_.row } | Measure-Object -Minimum).Minimum
    $maxRow = ($pos.Values | ForEach-Object { $_.row } | Measure-Object -Maximum).Maximum

    function GX([int]$col) { return $pad + ($col - $minCol) * ($cell + $gap) }
    function GY([int]$row) { return $pad + ($row - $minRow) * ($cell + $gap) }

    $picW = (GX $maxCol) + $cell + $pad
    $picH = (GY $maxRow) + $cell + $pad
    $pic = New-Object System.Windows.Forms.PictureBox
    $pic.Size = New-Object System.Drawing.Size([Math]::Max(400,$picW), [Math]::Max(400,$picH))
    $pic.BackColor = [System.Drawing.Color]::FromArgb(28,28,30)
    $wScroll.Controls.Add($pic)

    $bmp = New-Object System.Drawing.Bitmap $pic.Width, $pic.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $fontSmall = New-Object System.Drawing.Font("Segoe UI", 7)
    $penEdge = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(90,120,150)), 2
    $penWarp = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(200,120,50)), 2
    $penWarp.DashStyle = 'Dash'

    # draw compass edges
    foreach ($p in $graph.Keys) {
        if (-not $pos.ContainsKey($p)) { continue }
        foreach ($dir in $graph[$p].Keys) {
            $np = $graph[$p][$dir]
            if (-not $pos.ContainsKey($np)) { continue }
            if ($pos[$p].col -eq 99 -or $pos[$np].col -eq 99) { continue }  # skip warp-column fake edges
            $x1 = (GX $pos[$p].col) + $cell/2; $y1 = (GY $pos[$p].row) + $cell/2
            $x2 = (GX $pos[$np].col) + $cell/2; $y2 = (GY $pos[$np].row) + $cell/2
            $g.DrawLine($penEdge, $x1, $y1, $x2, $y2)
        }
    }
    # draw warp links (curved-ish: just a straight dashed line, labeled)
    foreach ($wl in $warpLinks) {
        if (-not ($pos.ContainsKey($wl.from) -and $pos.ContainsKey($wl.to))) { continue }
        $x1 = (GX $pos[$wl.from].col) + $cell/2; $y1 = (GY $pos[$wl.from].row) + $cell/2
        $x2 = (GX $pos[$wl.to].col) + $cell/2; $y2 = (GY $pos[$wl.to].row) + $cell/2
        $g.DrawLine($penWarp, $x1, $y1, $x2, $y2)
    }

    $boxes = @()   # for click hit-testing: @{rect=;file=}
    foreach ($p in ($pos.Keys | Sort-Object)) {
        $x = GX $pos[$p].col; $y = GY $pos[$p].row
        $mapFile = if ($placeFiles.ContainsKey($p)) { $placeFiles[$p] } else { "map{0:D2}.map" -f $p }
        $exists = Test-Path (Join-Path $mapDir $mapFile)
        $fillColor = if ($pos[$p].col -eq 99) { [System.Drawing.Color]::FromArgb(90,60,40) } else { [System.Drawing.Color]::FromArgb(50,70,95) }
        if (-not $exists) { $fillColor = [System.Drawing.Color]::FromArgb(60,60,60) }
        $br = New-Object System.Drawing.SolidBrush $fillColor
        $g.FillRectangle($br, $x, $y, $cell, $cell)
        $bp = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(160,180,200)), 1
        $g.DrawRectangle($bp, $x, $y, $cell, $cell)
        $tb = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
        $g.DrawString("Place $p", $font, $tb, $x+8, $y+8)
        $g.DrawString($mapFile, $fontSmall, $tb, $x+8, $y+26)
        if (-not $exists) { $g.DrawString("(file not found)", $fontSmall, $tb, $x+8, $y+40) }

        if ($interiors.ContainsKey($p)) {
            $iy = $y + $cell - 22
            foreach ($im in $interiors[$p]) {
                $ib = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(180,140,90))
                $g.FillRectangle($ib, $x+8, $iy, 14, 14)
                $g.DrawString($im, $fontSmall, $tb, $x+26, $iy)
                $iy -= 16
            }
        }
        $boxes += @{ rect = New-Object System.Drawing.Rectangle $x,$y,$cell,$cell; file = $mapFile; exists = $exists }
    }
    $g.Dispose()
    $pic.Image = $bmp

    $pic.Add_Click({
        param($s,$e)
    })
    $pic.Add_MouseClick({
        param($s,$e)
        foreach ($b in $boxes) {
            if ($b.rect.Contains($e.X, $e.Y)) {
                if ($b.exists) {
                    Load-Map (Join-Path $mapDir $b.file)
                    $wf.Close()
                } else {
                    [System.Windows.Forms.MessageBox]::Show("$($b.file) isn't in that folder.","World View",'OK','Information')|Out-Null
                }
                return
            }
        }
    })

    [void]$wf.ShowDialog($form)
}

#-----------------------------------------------------------------------------
#  Teleport Table: load several maps side by side, click a tile on one and a
#  tile on another to define a portal link between them, then export ready
#  AddPortal(...) lines to paste into ARAXIA.BAS. Links are also saved to a
#  small text file (TeleportTable.txt) so you can come back and keep editing.
#-----------------------------------------------------------------------------
$script:tpSlots = @()        # @{ path=; name=; rows=; cols=; grid=; pic=; bmp=; ts= }
$script:tpPlace = 4
$script:tpSlotsPanel = $null # the FlowLayoutPanel holding all map slots (set when the window opens)
$script:tpListView = $null   # the links ListView (set when the window opens)
$script:tpLinks = @()        # @{ fromFile=; fromCol=; fromRow=; toFile=; toCol=; toRow=; place=; inside=; label= }
$script:tpPending = $null    # @{ slotIndex=; col=; row= } - first click, waiting for the second

function Load-TpMap([string]$path) {
    $text = [System.IO.File]::ReadAllText($path)
    $nums = [System.Text.RegularExpressions.Regex]::Matches($text, '-?\d+') | ForEach-Object { [int]$_.Value }
    if ($nums.Count -lt 2) { return $null }
    $r = $nums[0]; $c = $nums[1]
    $g = New-Grid $r $c 0
    $k = 2
    for ($i=0; $i -lt $r; $i++) {
        for ($j=0; $j -lt $c; $j++) {
            if ($k -lt $nums.Count) { $g[$i][$j] = $nums[$k] }
            $k++
        }
    }
    return @{ rows=$r; cols=$c; grid=$g }
}

function Render-TpSlot($slot) {
    $ts = $slot.ts
    $w = $slot.cols * $ts; $h = $slot.rows * $ts
    if ($slot.bmp) { $slot.bmp.Dispose() }
    $bmp = New-Object System.Drawing.Bitmap ([Math]::Max(1,$w)), ([Math]::Max(1,$h))
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    for ($r=0; $r -lt $slot.rows; $r++) {
        for ($c=0; $c -lt $slot.cols; $c++) {
            $id = $slot.grid[$r][$c]
            $x = $c*$ts; $y = $r*$ts
            if ($script:tileImg.ContainsKey($id)) {
                $g.DrawImage($script:tileImg[$id], $x, $y, $ts, $ts)
            } else {
                $br = New-Object System.Drawing.SolidBrush (Get-TileColor $id)
                $g.FillRectangle($br, $x, $y, $ts, $ts); $br.Dispose()
            }
        }
    }
    # draw existing link markers (endpoints touching this file)
    for ($li=0; $li -lt $script:tpLinks.Count; $li++) {
        $lk = $script:tpLinks[$li]
        if ($lk.fromFile -eq $slot.name) { Draw-TpMarker $g $lk.fromCol $lk.fromRow $ts ([System.Drawing.Color]::FromArgb(255,215,0)) }
        if ($lk.toFile   -eq $slot.name) { Draw-TpMarker $g $lk.toCol   $lk.toRow   $ts ([System.Drawing.Color]::FromArgb(80,200,255)) }
    }
    # draw pending selection marker
    if ($script:tpPending -and $script:tpSlots[$script:tpPending.slotIndex].name -eq $slot.name) {
        Draw-TpMarker $g $script:tpPending.col $script:tpPending.row $ts ([System.Drawing.Color]::Red)
    }
    $g.Dispose()
    $slot.bmp = $bmp
    $slot.pic.Image = $bmp
    $slot.pic.Width = $w; $slot.pic.Height = $h
}

function Draw-TpMarker($g, [int]$c, [int]$r, [int]$ts, $color) {
    $d = [Math]::Max(4, [int]($ts*0.6))
    $x = $c*$ts + ($ts-$d)/2; $y = $r*$ts + ($ts-$d)/2
    $b = New-Object System.Drawing.SolidBrush $color
    $g.FillEllipse($b, $x, $y, $d, $d); $b.Dispose()
    $p = New-Object System.Drawing.Pen ([System.Drawing.Color]::Black), 1
    $g.DrawEllipse($p, $x, $y, $d, $d); $p.Dispose()
}

function Refresh-AllTpSlots { foreach ($s in $script:tpSlots) { Render-TpSlot $s } }

function TeleportTablePath {
    $dir = Get-DataDir
    return (Join-Path $dir "TeleportTable.txt")
}

function Save-TpLinks {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("# ARAXIA Teleport Table - editor bookkeeping, not read by the game`r`n")
    [void]$sb.Append("# fromFile,fromCol,fromRow,toFile,toCol,toRow,place,inside,label`r`n")
    foreach ($lk in $script:tpLinks) {
        [void]$sb.Append("$($lk.fromFile),$($lk.fromCol),$($lk.fromRow),$($lk.toFile),$($lk.toCol),$($lk.toRow),$($lk.place),$($lk.inside),$($lk.label)`r`n")
    }
    [System.IO.File]::WriteAllText((TeleportTablePath), $sb.ToString(), [System.Text.Encoding]::ASCII)
}

function Load-TpLinks {
    $p = TeleportTablePath
    $script:tpLinks = @()
    if (-not (Test-Path $p)) { return }
    foreach ($line in [System.IO.File]::ReadAllLines($p)) {
        $t = $line.Trim()
        if ($t -eq "" -or $t.StartsWith("#")) { continue }
        $parts = $t -split ',', 9
        if ($parts.Count -ge 8) {
            $script:tpLinks += @{
                fromFile = $parts[0]; fromCol = [int]$parts[1]; fromRow = [int]$parts[2]
                toFile   = $parts[3]; toCol   = [int]$parts[4]; toRow   = [int]$parts[5]
                place    = [int]$parts[6]; inside = [int]$parts[7]
                label    = if ($parts.Count -ge 9) { $parts[8] } else { "" }
            }
        }
    }
}

function Refresh-TpList($listView) {
    $listView.Items.Clear()
    foreach ($lk in $script:tpLinks) {
        $item = New-Object System.Windows.Forms.ListViewItem($lk.fromFile)
        [void]$item.SubItems.Add("($($lk.fromCol),$($lk.fromRow))")
        [void]$item.SubItems.Add($lk.toFile)
        [void]$item.SubItems.Add("($($lk.toCol),$($lk.toRow))")
        [void]$item.SubItems.Add([string]$lk.place)
        [void]$item.SubItems.Add([string]$lk.inside)
        [void]$item.SubItems.Add($lk.label)
        [void]$listView.Items.Add($item)
    }
}

# Friendly-name helper: strip path, keep just the filename for matching/display
function TpName([string]$path) { return (Split-Path $path -Leaf) }

function AddSlotPanel($name, $slotData) {
    $slotHost = New-Object System.Windows.Forms.Panel
    $slotHost.BorderStyle = "FixedSingle"; $slotHost.Margin = '6,6,6,6'
    $slotHost.AutoSize = $false
    $slotHost.Width = 420; $slotHost.Height = 460
    $slotHost.BackColor = [System.Drawing.Color]::FromArgb(35,35,38)

    $title = New-Object System.Windows.Forms.Label
    $title.Dock = "Top"; $title.Height = 22; $title.Text = "  $name"
    $title.ForeColor = "White"; $title.BackColor = [System.Drawing.Color]::FromArgb(55,55,60)
    $slotHost.Controls.Add($title)

    $scroller = New-Object System.Windows.Forms.Panel
    $scroller.Dock = "Fill"; $scroller.AutoScroll = $true
    $slotHost.Controls.Add($scroller)
    $scroller.BringToFront()

    $pic = New-Object System.Windows.Forms.PictureBox
    $pic.SizeMode = "AutoSize"
    $scroller.Controls.Add($pic)

    $ts = 8   # small tile size so a whole map is visible at once
    $slot = @{ path=$slotData.path; name=$name; rows=$slotData.rows; cols=$slotData.cols; grid=$slotData.grid; pic=$pic; bmp=$null; ts=$ts }
    $script:tpSlots += $slot
    $idx = $script:tpSlots.Count - 1

    $pic.Add_Click({
        param($s,$e)
    })
    $pic.Add_MouseClick({
        param($s,$e)
        $mySlot = $script:tpSlots | Where-Object { $_.pic -eq $s } | Select-Object -First 1
        if (-not $mySlot) { return }
        $myIndex = [array]::IndexOf($script:tpSlots, $mySlot)
        $c = [int][Math]::Floor($e.X / $mySlot.ts)
        $r = [int][Math]::Floor($e.Y / $mySlot.ts)
        if ($r -lt 0 -or $c -lt 0 -or $r -ge $mySlot.rows -or $c -ge $mySlot.cols) { return }

        if (-not $script:tpPending) {
            $script:tpPending = @{ slotIndex = $myIndex; col = $c; row = $r }
            Refresh-AllTpSlots
            return
        }
        if ($script:tpPending.slotIndex -eq $myIndex) {
            # clicked the same map again - just move the pending point
            $script:tpPending = @{ slotIndex = $myIndex; col = $c; row = $r }
            Refresh-AllTpSlots
            return
        }

        # second click on a DIFFERENT map: build BOTH directions at once.
        # You click the door on each side; the player lands on the tile just
        # past each door so stepping through never re-triggers the warp.
        $fromSlot = $script:tpSlots[$script:tpPending.slotIndex]
        $aCol = $script:tpPending.col; $aRow = $script:tpPending.row
        $bCol = $c;                    $bRow = $r
        $place = $script:tpPlace

        # entering: land one tile ABOVE the far door (inside the room)
        $script:tpLinks += @{
            fromFile = $fromSlot.name; fromCol = $aCol; fromRow = $aRow
            toFile   = $mySlot.name;   toCol   = $bCol; toRow   = $bRow - 1
            place = $place; inside = 1; label = "to $($mySlot.name)"
        }
        # leaving: land one tile BELOW the near door (outside the building)
        $script:tpLinks += @{
            fromFile = $mySlot.name;   fromCol = $bCol; fromRow = $bRow
            toFile   = $fromSlot.name; toCol   = $aCol; toRow   = $aRow + 1
            place = $place; inside = 0; label = "back to $($fromSlot.name)"
        }
        $script:tpPending = $null
        Save-TpLinks
        Refresh-TpList $script:tpListView
        Refresh-AllTpSlots
    })

    Render-TpSlot $slot
    $script:tpSlotsPanel.Controls.Add($slotHost)
    $slotHost.Refresh()
    $script:tpSlotsPanel.Refresh()
    return $slotHost
}

function Show-TeleportTable {
    Load-TpLinks
    $script:tpSlots = @()
    $script:tpPending = $null

    $wf = New-Object System.Windows.Forms.Form
    $wf.Text = "Teleport Table - click a tile on one map, then a tile on another, to link them"
    $wf.Size = New-Object System.Drawing.Size(1200, 800)
    $wf.StartPosition = "Manual"
    try {
        $wf.Location = New-Object System.Drawing.Point(($form.Location.X + 60), ($form.Location.Y + 60))
    } catch {
        $wf.StartPosition = "CenterScreen"
    }
    $wf.BackColor = [System.Drawing.Color]::FromArgb(28,28,30)

    $bar = New-Object System.Windows.Forms.FlowLayoutPanel
    $bar.Dock = "Top"; $bar.Height = 40; $bar.BackColor = [System.Drawing.Color]::FromArgb(45,45,48)
    $wf.Controls.Add($bar)

    function NewBtn($text) {
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $text; $b.AutoSize = $true; $b.Height = 30
        $b.FlatStyle = "Flat"; $b.ForeColor = "White"
        $b.BackColor = [System.Drawing.Color]::FromArgb(75,75,80)
        $bar.Controls.Add($b)
        return $b
    }
    $btnAddSlot = NewBtn "Add Map..."
    $btnRemoveSlot = NewBtn "Remove Selected Map"
    $btnImportBas = NewBtn "Import Links from ARAXIA.BAS"
    $btnExport = NewBtn "Export AddPortal Code"
    $lblPlace = New-Object System.Windows.Forms.Label
    $lblPlace.Text = "Place:"; $lblPlace.AutoSize = $true; $lblPlace.ForeColor = "White"
    $lblPlace.Margin = '12,10,2,0'
    $bar.Controls.Add($lblPlace)
    $txtPlace = New-Object System.Windows.Forms.TextBox
    $txtPlace.Width = 40; $txtPlace.Text = [string]$script:tpPlace
    $txtPlace.Add_TextChanged({ $v=0; if([int]::TryParse($txtPlace.Text,[ref]$v)){ $script:tpPlace = $v } })
    $bar.Controls.Add($txtPlace)

    $btnWriteWarps = NewBtn "Write [Warps] into Map Files"
    $btnWriteWarps.BackColor = [System.Drawing.Color]::FromArgb(60,110,70)
    $btnCancelPick = NewBtn "Cancel Selection"
    $btnRemoveLink = NewBtn "Remove Selected Link"

    $hint = New-Object System.Windows.Forms.Label
    $hint.Dock = "Top"; $hint.Height = 22
    $hint.Text = "  Click the DOOR on one map, then the DOOR on the other. Both directions are created automatically."
    $hint.ForeColor = "#CFCFD6"; $hint.BackColor = [System.Drawing.Color]::FromArgb(45,45,48)
    $wf.Controls.Add($hint)

    $split = New-Object System.Windows.Forms.SplitContainer
    $split.Dock = "Fill"; $split.Orientation = "Horizontal"
    $split.SplitterDistance = 480
    $wf.Controls.Add($split)

    $slotsPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $slotsPanel.Dock = "Fill"; $slotsPanel.AutoScroll = $true
    $slotsPanel.BackColor = [System.Drawing.Color]::FromArgb(20,20,22)
    $split.Panel1.Controls.Add($slotsPanel)

    $listView = New-Object System.Windows.Forms.ListView
    $listView.Dock = "Fill"; $listView.View = "Details"; $listView.FullRowSelect = $true
    $listView.BackColor = [System.Drawing.Color]::FromArgb(30,30,32); $listView.ForeColor = "White"
    foreach ($col in @("From Map","From (col,row)","To Map","To (col,row)","Place","Inside","Label")) {
        [void]$listView.Columns.Add($col, 150)
    }
    $split.Panel2.Controls.Add($listView)
    $script:tpSlotsPanel = $slotsPanel
    $script:tpListView = $listView

    $script:tpSlots = @()
    Refresh-TpList $listView

    $btnAddSlot.Add_Click({
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Filter = "Map files (*.map)|*.map|All files (*.*)|*.*"
        $dlg.Multiselect = $true
        if ($script:file) { try { $dlg.InitialDirectory = Split-Path $script:file -Parent } catch {} }
        if ($dlg.ShowDialog() -ne "OK") { return }
        foreach ($f in $dlg.FileNames) {
            try {
                $name = Split-Path $f -Leaf
                if ($script:tpSlots | Where-Object { $_.name -eq $name }) { continue }
                $data = Load-TpMap $f
                if (-not $data) {
                    [System.Windows.Forms.MessageBox]::Show("Could not read $name (file may not be a valid .map).","Teleport Table",'OK','Warning')|Out-Null
                    continue
                }
                $data.path = $f
                [void](AddSlotPanel $name $data)
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Error adding $f`:`r`n`r`n$($_.Exception.Message)`r`n`r`n$($_.ScriptStackTrace)","Teleport Table - Add Map failed",'OK','Error')|Out-Null
            }
        }
    })

    $btnRemoveSlot.Add_Click({
        if ($slotsPanel.Controls.Count -eq 0) { return }
        $lastHost = $slotsPanel.Controls[$slotsPanel.Controls.Count - 1]
        $slotsPanel.Controls.Remove($lastHost)
        if ($script:tpSlots.Count -le 1) {
            $script:tpSlots = @()
        } else {
            $script:tpSlots = $script:tpSlots[0..($script:tpSlots.Count-2)]
        }
        $script:tpPending = $null
    })

    $btnCancelPick.Add_Click({
        $script:tpPending = $null
        Refresh-AllTpSlots
    })

    $btnRemoveLink.Add_Click({
        if ($listView.SelectedIndices.Count -eq 0) { return }
        $i = $listView.SelectedIndices[0]
        $newLinks = @()
        for ($k=0; $k -lt $script:tpLinks.Count; $k++) {
            if ($k -ne $i) { $newLinks += $script:tpLinks[$k] }
        }
        $script:tpLinks = $newLinks
        Save-TpLinks
        Refresh-TpList $listView
        Refresh-AllTpSlots
    })

    $btnImportBas.Add_Click({
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Filter = "FreeBASIC source (*.bas)|*.bas|All files (*.*)|*.*"
        if ($dlg.ShowDialog() -ne "OK") { return }
        $basDir = Split-Path $dlg.FileName -Parent
        $portals = Parse-Portals $dlg.FileName
        $added = 0
        $mapNames = New-Object System.Collections.Generic.HashSet[string]
        foreach ($p in $portals) {
            [void]$mapNames.Add($p.FromMap)
            [void]$mapNames.Add($p.ToMap)
            $exists = $script:tpLinks | Where-Object {
                $_.fromFile -eq $p.FromMap -and $_.fromCol -eq $p.FX -and $_.fromRow -eq $p.FY -and $_.toFile -eq $p.ToMap
            }
            if ($exists) { continue }
            # AddPortal coordinates are 1-based (game); the editor's own grid is 0-based -
            # store 0-based internally so on-screen markers land in the right cell.
            $script:tpLinks += @{
                fromFile = $p.FromMap; fromCol = $p.FX; fromRow = $p.FY
                toFile   = $p.ToMap;   toCol   = $p.TX; toRow   = $p.TY
                place = $p.ToPlace; inside = $p.ToInside; label = "(imported)"
            }
            $added++
        }

        # also load a visual slot for every map referenced, if not already open
        $searchDirs = @($basDir, (Join-Path $basDir "data"))
        $loadedMaps = 0
        foreach ($mapName in $mapNames) {
            if ($script:tpSlots | Where-Object { $_.name -eq $mapName }) { continue }
            $found = $null
            foreach ($sd in $searchDirs) {
                $candidate = Join-Path $sd $mapName
                if (Test-Path $candidate) { $found = $candidate; break }
                # case-insensitive fallback (map files are often uppercase on disk)
                if (Test-Path $sd) {
                    $hit = Get-ChildItem -Path $sd -Filter $mapName -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($hit) { $found = $hit.FullName; break }
                }
            }
            if ($found) {
                $data = Load-TpMap $found
                if ($data) {
                    $data.path = $found
                    [void](AddSlotPanel $mapName $data)
                    $loadedMaps++
                }
            }
        }

        Save-TpLinks
        Refresh-TpList $listView
        Refresh-AllTpSlots
        [System.Windows.Forms.MessageBox]::Show("Imported $added new link(s) and loaded $loadedMaps map(s) from $(Split-Path $dlg.FileName -Leaf).`r`n`r`nIf a map isn't showing, click Add Map... and browse to it manually (it wasn't found automatically next to the .bas file or in its data\ folder).","Import",'OK','Information')|Out-Null
    })

    $btnWriteWarps.Add_Click({
        if ($script:tpLinks.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No links defined yet.","Write Warps",'OK','Information')|Out-Null
            return
        }
        # every link needs to be written into the file it STARTS from
        $byMap = @{}
        foreach ($lk in $script:tpLinks) {
            if (-not $byMap.ContainsKey($lk.fromFile)) { $byMap[$lk.fromFile] = @() }
            $byMap[$lk.fromFile] += $lk
        }

        # find each map file on disk: prefer an open slot's path, else the data dir
        $written = 0; $missing = @()
        foreach ($mapName in $byMap.Keys) {
            $slot = $script:tpSlots | Where-Object { $_.name -eq $mapName } | Select-Object -First 1
            $path = $null
            if ($slot) { $path = $slot.path }
            if (-not $path) {
                $cand = Join-Path (Get-DataDir) $mapName
                if (Test-Path $cand) { $path = $cand }
            }
            if (-not $path -or -not (Test-Path $path)) { $missing += $mapName; continue }

            # rebuild the file: everything up to (but not including) any old [Warps], then ours
            $lines = [System.IO.File]::ReadAllLines($path)
            $keep = @()
            foreach ($ln in $lines) {
                if ($ln.Trim().ToUpper() -eq "[WARPS]") { break }
                $keep += $ln
            }
            while ($keep.Count -gt 0 -and $keep[$keep.Count-1].Trim() -eq "") {
                $keep = $keep[0..($keep.Count-2)]
            }

            $sb = New-Object System.Text.StringBuilder
            foreach ($ln in $keep) { [void]$sb.Append($ln + "`r`n") }
            [void]$sb.Append("[Warps]`r`n")
            foreach ($lk in $byMap[$mapName]) {
                # editor grid is 0-based; the game reads 1-based coordinates
                # The engine compares warps against (TopCol+7, TopRow+4), which is
                # exactly the 0-based cell this editor displays. Write it unchanged.
                $fc = $lk.fromCol; $fr = $lk.fromRow
                $tc = $lk.toCol;   $tr = $lk.toRow
                $comment = if ($lk.label) { "   ' $($lk.label)" } else { "" }
                [void]$sb.Append("$fc,$fr,$($lk.toFile),$tc,$tr,$($lk.place),$($lk.inside)$comment`r`n")
            }
            [System.IO.File]::WriteAllText($path, $sb.ToString(), [System.Text.Encoding]::ASCII)
            $written++
        }

        $msg = "Wrote [Warps] sections into $written map file(s)."
        if ($missing.Count -gt 0) {
            $msg += "`r`n`r`nCouldn't find these on disk (add them with Add Map... so I know where they live):`r`n" + ($missing -join ", ")
        }
        [System.Windows.Forms.MessageBox]::Show($msg,"Write Warps",'OK','Information')|Out-Null
    })

    $btnExport.Add_Click({
        if ($script:tpLinks.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No links defined yet.","Export",'OK','Information')|Out-Null
            return
        }
        $sb = New-Object System.Text.StringBuilder
        [void]$sb.Append("' ---- Teleport Table export - paste into SetupPortals ----`r`n")
        foreach ($lk in $script:tpLinks) {
            # convert 0-based editor coords to 1-based game coords
            $fc = $lk.fromCol; $fr = $lk.fromRow
            $tc = $lk.toCol;   $tr = $lk.toRow
            $comment = if ($lk.label) { "   ' $($lk.label)" } else { "" }
            [void]$sb.Append("AddPortal(`"$($lk.fromFile)`", $fc, $fr,  `"$($lk.toFile)`", $tc, $tr, $($lk.place), $($lk.inside))$comment`r`n")
        }
        $code = $sb.ToString()

        $out = New-Object System.Windows.Forms.Form
        $out.Text = "AddPortal code - copy this into SetupPortals"
        $out.Size = New-Object System.Drawing.Size(700,500)
        $out.StartPosition = "CenterParent"
        $box = New-Object System.Windows.Forms.TextBox
        $box.Multiline = $true; $box.ScrollBars = "Both"; $box.Dock = "Fill"
        $box.Font = New-Object System.Drawing.Font("Consolas", 10)
        $box.Text = $code
        $box.ReadOnly = $false
        $out.Controls.Add($box)
        [void]$out.ShowDialog($wf)
    })

    $wf.Show($form)
}

function Cell-FromMouse($e) {
    $c = [int][Math]::Floor($e.X / $script:ts)
    $r = [int][Math]::Floor($e.Y / $script:ts)
    return ,@($r,$c)
}

$canvas.Add_MouseDown({
    param($s,$e)
    $rc = Cell-FromMouse $e; $r=$rc[0]; $c=$rc[1]
    if ($r -lt 0 -or $c -lt 0 -or $r -ge $script:rows -or $c -ge $script:cols) { return }

    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
        $script:brush = $script:grid[$r][$c]
        foreach ($w in $script:swatches) { $w.Invalidate() }
        Update-Status
        return
    }

    if ($script:npcMode) {
        if ($script:moveMode -and $script:movingKey) {
            Complete-NpcMove $r $c
            return
        }
        $id = $script:grid[$r][$c]
        if (-not (Is-NpcTile $id)) {
            $status.Text = "  Cell ($c,$r) is '$(Get-TileName $id)' - not a person/sign/shop tile. Click an NPC, clerk, sign, or shop desk."
            return
        }
        $script:selectedNpcKey = "$c,$r"
        Assign-Npc $r $c
        Refresh-NpcList
        return
    }

    if ($script:bucket) { Flood-Fill $r $c $script:brush; return }
    $script:painting = $true
    Paint-Cell $r $c $script:brush
})

$canvas.Add_MouseMove({
    param($s,$e)
    $rc = Cell-FromMouse $e; $r=$rc[0]; $c=$rc[1]
    if ($r -ge 0 -and $c -ge 0 -and $r -lt $script:rows -and $c -lt $script:cols) {
        $cur = $script:grid[$r][$c]
        $key = "$c,$r"
        $extra = ""
        if ($script:npc.ContainsKey($key)) { $o = $script:npc[$key]; $extra = "  ->  $($o.name)  says: " + $o.file }
        if ($script:moveMode -and $script:movingKey) { $extra += "   [click here to drop the NPC]" }
        $status.Text = ("  cell (col {0}, row {1}) = {2} (id {3}){4}{5}" -f `
            $c, $r, (Get-TileName $cur), $cur, $(if(Is-Solid($cur)){" [solid]"}else{""}), $extra)
    }
    if ($script:painting -and (-not $script:npcMode) -and $e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        Paint-Cell $r $c $script:brush
    }
})

$canvas.Add_MouseUp({ param($s,$e); $script:painting = $false; Update-Status })

$form.Add_FormClosing({
    param($s,$e)
    if ($script:dirty) {
        $res = [System.Windows.Forms.MessageBox]::Show("You have unsaved changes. Close anyway?","ARAXIA Map Editor",'YesNo','Warning')
        if ($res -ne 'Yes') { $e.Cancel = $true }
    }
})

# ============================================================================
#  Boot
# ============================================================================
Build-Palette
$script:grid = New-Grid $script:rows $script:cols 1
Rebuild-Canvas
Refresh-NpcList
Update-Status

if ($args.Count -ge 1 -and (Test-Path $args[0])) { Load-Map $args[0] }

[void]$form.ShowDialog()
