# dxSimpleUninstaller - Simple GUI script to uninstall your Windows applications. Author: Dmitry Hrabrov a.k.a. DeXPeriX
# License: This software is dual-licensed to the public domain and under the following license: you are granted a perpetual, irrevocable license to copy, modify, publish and distribute this file as you see fit.

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
$WindowBgColor, $BgColor, $AltBgColor, $FgColor = "#444444", "#333333", "#3D3D3D", "#EFEFEF"

$dxSimpleUninstaller             = New-Object system.Windows.Forms.Form
$dxSimpleUninstaller.ClientSize  = '800,600'
$dxSimpleUninstaller.text        = "dx Simple Uninstaller"
$dxSimpleUninstaller.BackColor   = $WindowBgColor
$dxSimpleUninstaller.ShowIcon    = $false
$dxSimpleUninstaller.add_Load({ Get-InstalledList })

$FilterTextBox                   = New-Object system.Windows.Forms.TextBox
$FilterTextBox.multiline         = $false
$FilterTextBox.width             = 780
$FilterTextBox.Anchor            = 'top,right,left'
$FilterTextBox.location          = New-Object System.Drawing.Point(10,5)
$FilterTextBox.Font              = 'Microsoft Sans Serif,10'
$FilterTextBox.ForeColor         = $FgColor
$FilterTextBox.BackColor         = $BgColor
$FilterTextBox.BorderStyle       = "None"
$FilterTextBox.Add_KeyUp({ Get-InstalledList })

$ProgramsGrid                    = New-Object system.Windows.Forms.DataGridView
$ProgramsGrid.width              = 780
$ProgramsGrid.height             = 560
$ProgramsGrid.Anchor             = 'top,right,bottom,left'
$ProgramsGrid.location           = New-Object System.Drawing.Point(10,30)
$ProgramsGrid.ReadOnly           = $true
$ProgramsGrid.MultiSelect        = $false
$ProgramsGrid.SelectionMode      = "FullRowSelect"
$ProgramsGrid.RowHeadersVisible  = $false
$ProgramsGrid.CellBorderStyle    = "None"
$ProgramsGrid.ForeColor          = $FgColor
$ProgramsGrid.BackgroundColor    = $BgColor
$ProgramsGrid.AutoGenerateColumns = $false
$ProgramsGrid.ColumnHeadersBorderStyle   = "None"
$ProgramsGrid.AllowUserToResizeRows      = $false
$ProgramsGrid.EnableHeadersVisualStyles  = $false
$ProgramsGrid.DefaultCellStyle.BackColor = $BgColor
$ProgramsGrid.AlternatingRowsDefaultCellStyle.BackColor = $AltBgColor
$ProgramsGrid.ColumnHeadersDefaultCellStyle.BackColor   = $WindowBgColor
$ProgramsGrid.ColumnHeadersDefaultCellStyle.ForeColor   = $FgColor
$ProgramsGrid.ColumnCount = 5
$ProgramsGrid.Columns | Foreach-Object { $_.AutoSizeMode = "AllCells" }
$ProgramsGrid.Columns[0].Visible = $false;
$ProgramsGrid.Columns[1].AutoSizeMode = "Fill"
$ProgramsGrid.Columns[1].Name = "Name"
$ProgramsGrid.Columns[2].Name = "Version"
$ProgramsGrid.Columns[3].Name = "Publisher"
$ProgramsGrid.Columns[4].Name = "Date"
$ProgramsGrid.add_DoubleClick({ Uninstall-Click })

$dxSimpleUninstaller.controls.AddRange(@($FilterTextBox,$ProgramsGrid))

$Script:installedSoftware = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName | Sort-Object -Property DisplayName

function Get-InstalledList {
    $filter = $FilterTextBox.Text
    $Script:filteredSoftware = $installedSoftware | Where-Object { $_.DisplayName -LIKE "*$filter*" -OR $_.DisplayName -LIKE "$filter*" }

    $ProgramsGrid.Rows.Clear()
    foreach ($row in $filteredSoftware) {
        $date = ""
        if ($row.InstallDate) {
            $date = (Get-Date -Date ([datetime]::ParseExact($row.InstallDate, "yyyymmdd", $null)) -Format "d").ToString()
        }

        $ProgramsGrid.Rows.Add(@($row.UninstallString, $row.DisplayName, $row.DisplayVersion, $row.Publisher, $date))
    }

    $dxSimpleUninstaller.refresh()
}

function Uninstall-Click {
    $uninstallStringRaw = $ProgramsGrid.Rows[$ProgramsGrid.SelectedCells[0].RowIndex].Cells[0].Value
    $process = $uninstallString = $uninstallStringRaw.replace("MsiExec.exe /I", "MsiExec.exe /X")
    $arguments = ""

    if ($uninstallString.StartsWith('"')) {
        $tmp, $process, $arguments = $uninstallString -split '"', 3
    }
    else {
        if ($uninstallString.Contains(' ')) {
            $process, $arguments = $uninstallString -split ' ', 2
        }
    }

    if ($arguments) {
        Start-Process $process -ArgumentList $arguments
    }
    else {
        Start-Process $process
    }
}

[void]$dxSimpleUninstaller.ShowDialog() 