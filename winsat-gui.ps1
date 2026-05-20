<#
    .SYNOPSIS
    winsat-gui v1.1
    A modern WPF-based graphical interface for the Windows System Assessment Tool (WinSAT).

    .DESCRIPTION
    This script generates a native Windows Desktop GUI using WPF (XAML) embedded directly 
    in PowerShell. It dynamically builds commands, executes them asynchronously without 
    blocking the UI, and streams output directly to the console view.

    Author: Joshua Dwight
    Refactored to WPF by Gemini
#>

# Requires PowerShell 5.1+ and Windows
#Requires -Version 5.1

# Ensure required assemblies are loaded
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==========================================
# 1. XAML GUI DEFINITION
# ==========================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="winsat-gui v1.1 - Joshua Dwight" Height="920" Width="1250"
        WindowStartupLocation="CenterScreen" Background="#FAFAFA" FontFamily="Segoe UI"
        MinHeight="750" MinWidth="1000">
    <Window.Resources>
        <!-- Styles -->
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#333333"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="Foreground" Value="#333333"/>
        </Style>
        <Style x:Key="HeaderStyle" TargetType="TextBlock">
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Foreground" Value="#005A9E"/>
            <Setter Property="Margin" Value="0,10,0,10"/>
        </Style>
        <Style x:Key="NavButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="Padding" Value="15,8"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Foreground" Value="#444444"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#E0E0E0"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style x:Key="ActiveNavButtonStyle" TargetType="Button" BasedOn="{StaticResource NavButtonStyle}">
            <Setter Property="Background" Value="#CCE4F7"/>
            <Setter Property="Foreground" Value="#005A9E"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="180"/>
            <RowDefinition Height="30"/>
        </Grid.RowDefinitions>
        
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="220"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="300"/>
        </Grid.ColumnDefinitions>

        <!-- LEFT SIDEBAR -->
        <Border Grid.Row="0" Grid.Column="0" Background="#F3F3F3" BorderBrush="#E0E0E0" BorderThickness="0,0,1,0">
            <StackPanel Margin="10,20,10,10">
                <!-- Branding -->
                <StackPanel Orientation="Horizontal" Margin="5,0,0,20">
                    <Border Background="#4F81BD" Width="32" Height="32" CornerRadius="4">
                        <TextBlock Text="W" FontWeight="Bold" Foreground="White" FontSize="18" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="winsat-gui" FontSize="20" FontWeight="SemiBold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                </StackPanel>
                
                <TextBlock Text="v1.1" FontSize="12" Margin="10,0,0,2" Foreground="#666"/>
                <TextBlock Text="by Joshua Dwight" FontSize="12" Margin="10,0,0,5" Foreground="#666"/>
                <TextBlock Margin="10,0,0,20"><Hyperlink x:Name="lnkGithub"><Run Text="GitHub Repository"/></Hyperlink></TextBlock>

                <TextBlock Text="COMMANDS" FontSize="11" FontWeight="SemiBold" Foreground="#888" Margin="10,10,0,5"/>
                
                <Button x:Name="navAssessments" Content="Assessments" Style="{StaticResource ActiveNavButtonStyle}"/>
                <Button x:Name="navFormal" Content="Formal Scores" Style="{StaticResource NavButtonStyle}"/>
                <Button x:Name="navPrepop" Content="Prepopulation" Style="{StaticResource NavButtonStyle}"/>
                <Button x:Name="navSub" Content="Sub-Assessments" Style="{StaticResource NavButtonStyle}"/>
                <Button x:Name="navUtils" Content="Utilities" Style="{StaticResource NavButtonStyle}"/>

                <TextBlock Text="QUICK LINKS" FontSize="11" FontWeight="SemiBold" Foreground="#888" Margin="10,30,0,5"/>
                <Button x:Name="navAbout" Content="About" Style="{StaticResource NavButtonStyle}"/>
            </StackPanel>
        </Border>

        <!-- MAIN CONTENT AREA -->
        <Border Grid.Row="0" Grid.Column="1" Background="White" Padding="30,20">
            <ScrollViewer VerticalScrollBarVisibility="Auto" BorderThickness="0">
                <StackPanel>
                    <!-- 1. Select Command -->
                    <TextBlock Text="1. Select Command" Style="{StaticResource HeaderStyle}"/>
                    
                    <Grid Margin="0,5,0,15">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="80"/>
                            <ColumnDefinition Width="200"/>
                            <ColumnDefinition Width="30"/>
                            <ColumnDefinition Width="150"/>
                            <ColumnDefinition Width="150"/>
                        </Grid.ColumnDefinitions>
                        
                        <TextBlock Text="Command:" VerticalAlignment="Center" Grid.Column="0"/>
                        <ComboBox x:Name="cmbCommand" Grid.Column="1" Height="26" VerticalContentAlignment="Center"/>
                        <TextBlock Text="(i)" FontWeight="Bold" Grid.Column="2" Foreground="#005A9E" FontSize="16" Margin="5,0,0,0" VerticalAlignment="Center" ToolTip="Select the core WinSAT command to run."/>
                        
                        <CheckBox x:Name="chkVerbose" Content="-v (Verbose)" Grid.Column="3" VerticalAlignment="Center" ToolTip="Enables verbose output."/>
                        <CheckBox x:Name="chkEef" Content="-eef (features only)" Grid.Column="4" VerticalAlignment="Center" ToolTip="Enumerates extended features. Only works with the 'features' command." IsEnabled="False"/>
                    </Grid>

                    <Grid Margin="0,0,0,10">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="80"/>
                            <ColumnDefinition Width="200"/>
                            <ColumnDefinition Width="30"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        
                        <TextBlock Text="Restart:" VerticalAlignment="Center" Grid.Column="0"/>
                        <ComboBox x:Name="cmbRestart" Grid.Column="1" Height="26" VerticalContentAlignment="Center" IsEnabled="False">
                            <ComboBoxItem Content="(default)" IsSelected="True"/>
                            <ComboBoxItem Content="clean"/>
                            <ComboBoxItem Content="never"/>
                        </ComboBox>
                        <TextBlock Text="(i)" FontWeight="Bold" Grid.Column="2" Foreground="#005A9E" FontSize="16" Margin="5,0,0,0" VerticalAlignment="Center" ToolTip="Controls how formal assessments rerun. Clean resets history."/>
                    </Grid>

                    <Grid Margin="0,0,0,20">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="80"/>
                            <ColumnDefinition Width="200"/>
                            <ColumnDefinition Width="30"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        
                        <TextBlock Text="D3D Mode:" VerticalAlignment="Center" Grid.Column="0"/>
                        <ComboBox x:Name="cmbD3d" Grid.Column="1" Height="26" VerticalContentAlignment="Center" IsEnabled="False">
                            <ComboBoxItem Content="(default)" IsSelected="True"/>
                            <ComboBoxItem Content="-dx9"/>
                            <ComboBoxItem Content="-dx10"/>
                        </ComboBox>
                        <TextBlock Text="(i)" FontWeight="Bold" Grid.Column="2" Foreground="#005A9E" FontSize="16" Margin="5,0,0,0" VerticalAlignment="Center" ToolTip="Applies to the d3d command to force DX9 or DX10 execution."/>
                    </Grid>

                    <Separator Margin="0,0,0,10"/>

                    <!-- 2. Output Options -->
                    <TextBlock Text="2. Output Options" Style="{StaticResource HeaderStyle}"/>
                    
                    <Grid Margin="0,5,0,10">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="150"/> <!-- Increased from 100 -->
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="80"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock Text="XML Output:" VerticalAlignment="Center"/>
                        <TextBox x:Name="txtXml" Grid.Column="1" Height="26" Margin="0,0,10,0" VerticalContentAlignment="Center"/>
                        <Button x:Name="btnBrowseXml" Grid.Column="2" Content="Browse..." Height="26"/>
                    </Grid>

                    <Grid Margin="0,0,0,10">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="150"/> <!-- Increased from 100 -->
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="80"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock Text="Log File:" VerticalAlignment="Center"/>
                        <TextBox x:Name="txtLog" Grid.Column="1" Height="26" Margin="0,0,10,0" VerticalContentAlignment="Center"/>
                        <Button x:Name="btnBrowseLog" Grid.Column="2" Content="Browse..." Height="26"/>
                    </Grid>

                    <Grid Margin="0,0,0,20">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="150"/> <!-- Increased from 100 -->
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="80"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock Text="Datastore (prepop only):" VerticalAlignment="Center"/> <!-- Removed TextWrapping -->
                        <TextBox x:Name="txtDatastore" Grid.Column="1" Height="26" Margin="0,0,10,0" VerticalContentAlignment="Center" Text="C:\Windows\Performance\WinSAT\Datastore"/>
                        <Button x:Name="btnBrowseDatastore" Grid.Column="2" Content="Browse..." Height="26"/>
                    </Grid>
                    
                    <Separator Margin="0,0,0,10"/>

                    <!-- 3. Command Preview -->
                    <TextBlock Text="3. Command Preview" Style="{StaticResource HeaderStyle}"/>
                    <Grid Margin="0,5,0,20">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="80"/>
                        </Grid.ColumnDefinitions>
                        <TextBox x:Name="txtPreview" Grid.Column="0" Height="30" Margin="0,0,10,0" IsReadOnly="True" Background="#F9F9F9" Foreground="#333" FontFamily="Consolas" VerticalContentAlignment="Center" Padding="5,0"/>
                        <Button x:Name="btnCopy" Grid.Column="1" Content="Copy" Height="30"/>
                    </Grid>

                    <!-- 4. Execute -->
                    <TextBlock Text="4. Execute" Style="{StaticResource HeaderStyle}"/>
                    <StackPanel Orientation="Horizontal" Margin="0,5,0,0">
                        <Button x:Name="btnRun" Width="120" Height="36" Margin="0,0,10,0" Background="#0078D7" Foreground="White" BorderThickness="0" Cursor="Hand">
                            <TextBlock Text="Run" FontWeight="SemiBold" VerticalAlignment="Center"/>
                        </Button>
                        <Button x:Name="btnStop" Width="120" Height="36" IsEnabled="False" Background="#E0E0E0" Foreground="#666" BorderThickness="0" Cursor="Hand">
                            <TextBlock Text="Stop" FontWeight="SemiBold" VerticalAlignment="Center"/>
                        </Button>
                    </StackPanel>
                </StackPanel>
            </ScrollViewer>
        </Border>

        <!-- RIGHT SIDEBAR (HELP) -->
        <Border Grid.Row="0" Grid.Column="2" Background="#F9F9F9" BorderBrush="#E0E0E0" BorderThickness="1,0,0,0" Padding="15">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
                <StackPanel>
                    <!-- Tabs -->
                    <StackPanel Orientation="Horizontal" Margin="0,0,0,15">
                        <Border BorderBrush="#E0E0E0" BorderThickness="1" Background="White" Padding="15,5">
                            <TextBlock Text="Dynamic Help" FontWeight="SemiBold"/>
                        </Border>
                    </StackPanel>
                    
                    <TextBlock x:Name="txtHelpTitle" Text="Command Help" FontSize="14" FontWeight="SemiBold" Foreground="#005A9E" Margin="0,0,0,10"/>
                    <TextBlock x:Name="txtHelpText" Text="Select a command from the list on the left to see detailed options." TextWrapping="Wrap" Margin="0,0,0,15" LineHeight="20"/>
                </StackPanel>
            </ScrollViewer>
        </Border>

        <!-- OUTPUT CONSOLE -->
        <Border Grid.Row="1" Grid.ColumnSpan="3" Background="#F3F3F3" Padding="10,5">
            <TextBlock Text="Output Console" FontWeight="SemiBold" Foreground="#555"/>
        </Border>
        <TextBox x:Name="txtOutput" Grid.Row="2" Grid.ColumnSpan="3" Background="Black" Foreground="#00FF00" FontFamily="Consolas" FontSize="12" IsReadOnly="True" ScrollViewer.VerticalScrollBarVisibility="Auto" ScrollViewer.HorizontalScrollBarVisibility="Auto" Padding="10" Margin="10,5,10,10" TextWrapping="NoWrap"/>

        <!-- STATUS BAR -->
        <Border Grid.Row="3" Grid.ColumnSpan="3" Background="#EEEEEE" BorderBrush="#D0D0D0" BorderThickness="0,1,0,0">
            <Grid Margin="10,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock x:Name="txtStatusIcon" Text="-" FontWeight="Bold" Foreground="Green" Margin="0,0,5,0"/>
                    <TextBlock x:Name="txtStatus" Text="Ready"/>
                </StackPanel>
                
                <TextBlock x:Name="txtTimer" Grid.Column="1" Text="00:00:00" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#555"/>
                
                <TextBlock x:Name="txtExecutedStatus" Grid.Column="2" Text="No command executed yet." Margin="0,0,20,0" VerticalAlignment="Center" Foreground="#555"/>
                <TextBlock Grid.Column="3" VerticalAlignment="Center"><Hyperlink x:Name="lnkDatastore"><Run Text="Open Datastore Folder"/></Hyperlink></TextBlock>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

# Read XAML
$reader = (New-Object System.Xml.XmlNodeReader ([xml]$xaml))
try {
    $Window = [System.Windows.Markup.XamlReader]::Load($reader)
} catch {
    Write-Warning "Unable to load XAML. Ensure you are running Windows and PowerShell 5.1+."
    Write-Error $_
    exit
}

# ==========================================
# 2. CONTROL BINDINGS
# ==========================================
$cmbCommand = $Window.FindName("cmbCommand")
$chkVerbose = $Window.FindName("chkVerbose")
$chkEef     = $Window.FindName("chkEef")
$cmbRestart = $Window.FindName("cmbRestart")
$cmbD3d     = $Window.FindName("cmbD3d")

$txtXml       = $Window.FindName("txtXml")
$txtLog       = $Window.FindName("txtLog")
$txtDatastore = $Window.FindName("txtDatastore")

$btnBrowseXml       = $Window.FindName("btnBrowseXml")
$btnBrowseLog       = $Window.FindName("btnBrowseLog")
$btnBrowseDatastore = $Window.FindName("btnBrowseDatastore")

$txtPreview = $Window.FindName("txtPreview")
$btnCopy    = $Window.FindName("btnCopy")
$btnRun     = $Window.FindName("btnRun")
$btnStop    = $Window.FindName("btnStop")

$txtOutput  = $Window.FindName("txtOutput")
$txtStatus  = $Window.FindName("txtStatus")
$txtTimer   = $Window.FindName("txtTimer")
$txtStatusIcon = $Window.FindName("txtStatusIcon")
$txtExecutedStatus = $Window.FindName("txtExecutedStatus")
$lnkDatastore = $Window.FindName("lnkDatastore")

# Nav & Help Buttons
$navAssessments = $Window.FindName("navAssessments")
$navFormal      = $Window.FindName("navFormal")
$navPrepop      = $Window.FindName("navPrepop")
$navSub         = $Window.FindName("navSub")
$navUtils       = $Window.FindName("navUtils")
$navAbout       = $Window.FindName("navAbout")
$lnkGithub      = $Window.FindName("lnkGithub")

$txtHelpTitle   = $Window.FindName("txtHelpTitle")
$txtHelpText    = $Window.FindName("txtHelpText")

# ==========================================
# 3. STATE & DATA
# ==========================================
$Script:Categories = [ordered]@{
    "Assessments" = @("formal", "dwm", "cpu", "mem", "d3d", "disk", "media", "mfmedia", "features")
    "Formal Scores" = @("dwmformal", "cpuformal", "memformal", "graphicsformal", "diskformal")
    "Prepopulation" = @("prepop", "prepop -graphics", "prepop -cpu", "prepop -mem", "prepop -disk", "prepop -dwm")
    "Sub-Assessments" = @("graphicsformal3d", "graphicsformalmedia")
    "Utilities" = @("viewlog", "viewevents", "query", "forgethistory")
}

$Script:ActiveProcess = $null
$Script:Stopwatch = New-Object System.Diagnostics.Stopwatch
$Script:Timer = New-Object System.Windows.Threading.DispatcherTimer
$Script:Timer.Interval = [TimeSpan]::FromMilliseconds(500)

# ==========================================
# 4. LOGIC FUNCTIONS
# ==========================================
function Set-NavStyle($activeButton) {
    # Reset all
    $navAssessments.Style = $Window.Resources["NavButtonStyle"]
    $navFormal.Style = $Window.Resources["NavButtonStyle"]
    $navPrepop.Style = $Window.Resources["NavButtonStyle"]
    $navSub.Style = $Window.Resources["NavButtonStyle"]
    $navUtils.Style = $Window.Resources["NavButtonStyle"]
    # Set active
    $activeButton.Style = $Window.Resources["ActiveNavButtonStyle"]
}

function Load-Category($categoryName) {
    $cmbCommand.Items.Clear()
    foreach ($item in $Script:Categories[$categoryName]) {
        [void]$cmbCommand.Items.Add($item)
    }
    $cmbCommand.SelectedIndex = 0
    Update-CommandState
}

function Update-HelpContent {
    $cmd = $cmbCommand.SelectedItem -as [string]
    if (-not $cmd) { return }
    
    $title = "Command: $cmd"
    $desc = ""
    $nl = [Environment]::NewLine
    
    switch -wildcard ($cmd) {
        "formal" { $desc = "Runs the full set of assessments to generate overall system scores.${nl}${nl}Restart Option:${nl}- default: WinSAT determines whether to rerun.${nl}- clean: Reruns all assessments and clears history.${nl}- never: Attempts incremental run if possible." }
        "dwm" { $desc = "Runs the Desktop Windows Manager assessment and restarts the DWM process." }
        "cpu" { $desc = "Runs the CPU assessment." }
        "mem" { $desc = "Runs the system memory assessment." }
        "d3d" { $desc = "Runs the Direct3D assessment.${nl}${nl}D3D Mode:${nl}- -dx9: Run DirectX 9 sub-assessments.${nl}- -dx10: Run DirectX 10 sub-assessments." }
        "disk" { $desc = "Runs the storage assessment." }
        "media" { $desc = "Runs the media assessment." }
        "mfmedia" { $desc = "Runs the Media Foundation based assessment." }
        "features" { $desc = "Enumerates the system's features.${nl}${nl}-eef (Extended Features):${nl}Used with the features command to enumerate extended features like optical disks and memory modules." }
        "prepop*" { $desc = "Generates pre-population WinSAT XML files. You can target specific subsystems (graphics, cpu, mem, disk, dwm).${nl}${nl}Datastore Option:${nl}Specifies the target directory where prepopulation XML files will be stored. Defaults to the standard WinSAT datastore." }
        "*formal*" { $desc = "Runs a specific formal sub-assessment to generate a specific WinSAT score (e.g., Gaming Graphics, CPU, Memory). Results are directly saved to the Windows Datastore." }
        "viewlog" { $desc = "Dumps the results of a previously specified log file to the console." }
        "viewevents" { $desc = "Opens the Windows Event Viewer to display relevant WinSAT events." }
        "query" { $desc = "Queries the current WinSAT datastore for existing system scores." }
        "forgethistory" { $desc = "Clears the existing WinSAT history, effectively rating the machine as if for the first time." }
        default { $desc = "Select a command to view detailed help and usage information." }
    }

    $commonOptions = "${nl}${nl}Common Output Options:${nl}- XML Output: Saves the assessment results to the specified XML file.${nl}- Log File: Generates a log file for troubleshooting and analysis.${nl}- Verbose (-v): Enables detailed diagnostic output during execution."

    $txtHelpTitle.Text = $title
    $txtHelpText.Text = $desc + $commonOptions
}

function Update-CommandState {
    $selected = $cmbCommand.SelectedItem -as [string]
    if (-not $selected) { return }

    # Reset enablers
    $chkEef.IsEnabled = ($selected -eq "features")
    if (-not $chkEef.IsEnabled) { $chkEef.IsChecked = $false }

    $cmbRestart.IsEnabled = ($selected -eq "formal")
    if (-not $cmbRestart.IsEnabled) { $cmbRestart.SelectedIndex = 0 }

    $cmbD3d.IsEnabled = ($selected -eq "d3d")
    if (-not $cmbD3d.IsEnabled) { $cmbD3d.SelectedIndex = 0 }

    $isPrepop = $selected.StartsWith("prepop")
    $txtDatastore.IsEnabled = $isPrepop
    $btnBrowseDatastore.IsEnabled = $isPrepop

    Update-Preview
    Update-HelpContent
}

function Update-Preview {
    $selected = $cmbCommand.SelectedItem -as [string]
    if (-not $selected) { return }

    $cmd = "winsat $selected"

    if ($chkVerbose.IsChecked) { $cmd += " -v" }
    
    if ($chkEef.IsChecked -and $chkEef.IsEnabled) { 
        $cmd += " -eef" 
    }

    if ($cmbRestart.IsEnabled -and $cmbRestart.SelectedIndex -gt 0) {
        $cmd += " -restart $($cmbRestart.Text)"
    }

    if ($cmbD3d.IsEnabled -and $cmbD3d.SelectedIndex -gt 0) {
        $cmd += " $($cmbD3d.Text)"
    }

    if (![string]::IsNullOrWhiteSpace($txtXml.Text)) {
        $cmd += " -xml `"$($txtXml.Text)`""
    }

    if (![string]::IsNullOrWhiteSpace($txtLog.Text)) {
        $cmd += " -log `"$($txtLog.Text)`""
    }

    if ($txtDatastore.IsEnabled -and ![string]::IsNullOrWhiteSpace($txtDatastore.Text)) {
        if ($txtDatastore.Text -ne "C:\Windows\Performance\WinSAT\Datastore") {
            $cmd += " -datastore `"$($txtDatastore.Text)`""
        }
    }

    $txtPreview.Text = $cmd
}

# ==========================================
# 5. EVENT HANDLERS
# ==========================================

# Open External Links
$lnkGithub.Add_RequestNavigate({
    [System.Diagnostics.Process]::Start($_.Uri.AbsoluteUri) | Out-Null
    $_.Handled = $true
})

# Nav Clicks
$navAssessments.Add_Click({ Set-NavStyle $navAssessments; Load-Category "Assessments" })
$navFormal.Add_Click({ Set-NavStyle $navFormal; Load-Category "Formal Scores" })
$navPrepop.Add_Click({ Set-NavStyle $navPrepop; Load-Category "Prepopulation" })
$navSub.Add_Click({ Set-NavStyle $navSub; Load-Category "Sub-Assessments" })
$navUtils.Add_Click({ Set-NavStyle $navUtils; Load-Category "Utilities" })

# About Menu
$navAbout.Add_Click({
    $aboutXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="About winsat-gui" Height="460" Width="480" WindowStartupLocation="CenterScreen" ResizeMode="NoResize" Background="#FAFAFA" FontFamily="Segoe UI">
    <Grid Margin="25">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <TextBlock Grid.Row="0" Text="winsat-gui" FontSize="26" FontWeight="Bold" Foreground="#005A9E"/>
        <TextBlock Grid.Row="1" Text="Version 1.1 | by Joshua Dwight" FontSize="14" Foreground="#555" Margin="0,2,0,15"/>
        
        <StackPanel Grid.Row="2">
            <TextBlock Text="A modern, high-performance WPF graphical interface for the Windows System Assessment Tool (WinSAT). This tool eliminates the need for complex command-line syntax while maintaining full feature parity, making system benchmarking intuitive and accessible." TextWrapping="Wrap" Margin="0,0,0,15" LineHeight="20"/>
            
            <TextBlock Text="Powerful Features:" FontWeight="SemiBold" Margin="0,0,0,8"/>
            <TextBlock Text="- Full GUI mapping of all native WinSAT commands&#x0a;- Asynchronous, non-blocking execution engine&#x0a;- Real-time console output streaming&#x0a;- Dynamic command generation &amp; validation&#x0a;- Context-aware integrated help system" TextWrapping="Wrap" LineHeight="20" Margin="10,0,0,15"/>
            
            <TextBlock><Hyperlink x:Name="lnkAboutGithub" NavigateUri="https://github.com/joshdwight101"><Run Text="https://github.com/joshdwight101"/></Hyperlink></TextBlock>
        </StackPanel>
        
        <Button x:Name="btnAboutClose" Grid.Row="3" Content="OK" Width="80" Height="30" HorizontalAlignment="Right" Background="#0078D7" Foreground="White" BorderThickness="0" Cursor="Hand"/>
    </Grid>
</Window>
"@
    $aboutReader = (New-Object System.Xml.XmlNodeReader ([xml]$aboutXaml))
    $script:aboutWindow = [System.Windows.Markup.XamlReader]::Load($aboutReader)
    
    $btnAboutClose = $script:aboutWindow.FindName("btnAboutClose")
    $btnAboutClose.Add_Click({ $script:aboutWindow.Close() })
    
    $lnkAboutGithub = $script:aboutWindow.FindName("lnkAboutGithub")
    $lnkAboutGithub.Add_RequestNavigate({
        [System.Diagnostics.Process]::Start($_.Uri.AbsoluteUri) | Out-Null
        $_.Handled = $true
    })

    [void]$script:aboutWindow.ShowDialog()
})

# Options Changes
$cmbCommand.Add_SelectionChanged({ Update-CommandState })
$chkVerbose.Add_Click({ Update-Preview })
$chkEef.Add_Click({ Update-Preview })
$cmbRestart.Add_SelectionChanged({ Update-Preview })
$cmbD3d.Add_SelectionChanged({ Update-Preview })
$txtXml.Add_TextChanged({ Update-Preview })
$txtLog.Add_TextChanged({ Update-Preview })
$txtDatastore.Add_TextChanged({ Update-Preview })

# Browse Buttons
$btnBrowseXml.Add_Click({
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = "XML Files (*.xml)|*.xml|All Files (*.*)|*.*"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtXml.Text = $dlg.FileName
    }
})

$btnBrowseLog.Add_Click({
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = "Log Files (*.log)|*.log|All Files (*.*)|*.*"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtLog.Text = $dlg.FileName
    }
})

$btnBrowseDatastore.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Select Datastore Directory"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtDatastore.Text = $dlg.SelectedPath
    }
})

$btnCopy.Add_Click({
    [System.Windows.Clipboard]::SetText($txtPreview.Text)
})

$lnkDatastore.Add_Click({
    $path = "C:\Windows\Performance\WinSAT\Datastore"
    if (Test-Path $path) { Invoke-Item $path }
})

# --- ASYNC EXECUTION ENGINE ---
$Script:Timer.Add_Tick({
    $ts = $Script:Stopwatch.Elapsed
    $txtTimer.Text = [string]::Format("{0:00}:{1:00}:{2:00}", $ts.Hours, $ts.Minutes, $ts.Seconds)
})

$btnRun.Add_Click({
    # Admin Check (WinSAT requires it)
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        [System.Windows.MessageBox]::Show("WinSAT requires Administrator privileges to run hardware assessments. Please run this script as Administrator.", "Admin Required", 0, 48)
        return
    }

    $cmdLine = $txtPreview.Text
    if ([string]::IsNullOrEmpty($cmdLine)) { return }

    # Extract arguments (remove 'winsat ' from start)
    $args = $cmdLine.Substring(7).Trim()

    # Generate separator and newline safely to avoid parser encoding errors
    $separator = New-Object string ('-', 48)
    $nl = [Environment]::NewLine

    $txtOutput.Text = "EXECUTING: $cmdLine${nl}${separator}${nl}"
    $txtStatus.Text = "Running..."
    $txtStatusIcon.Text = "O"
    $txtStatusIcon.Foreground = [System.Windows.Media.Brushes]::Orange
    $txtExecutedStatus.Text = "Last Command: $cmdLine"
    
    $btnRun.IsEnabled = $false
    $btnStop.IsEnabled = $true
    
    $Script:Stopwatch.Restart()
    $Script:Timer.Start()

    $Script:ActiveProcess = New-Object System.Diagnostics.Process
    $Script:ActiveProcess.StartInfo.FileName = "winsat.exe"
    $Script:ActiveProcess.StartInfo.Arguments = $args
    $Script:ActiveProcess.StartInfo.UseShellExecute = $false
    $Script:ActiveProcess.StartInfo.RedirectStandardOutput = $true
    $Script:ActiveProcess.StartInfo.RedirectStandardError = $true
    $Script:ActiveProcess.StartInfo.CreateNoWindow = $true
    $Script:ActiveProcess.EnableRaisingEvents = $true

    # Event handlers for async output
    $outHandler = [System.Diagnostics.DataReceivedEventHandler] {
        param($sender, $e)
        if ($e.Data -ne $null) {
            $Window.Dispatcher.Invoke([Action]{
                $nl = [Environment]::NewLine
                $txtOutput.AppendText($e.Data + $nl)
                $txtOutput.ScrollToEnd()
            })
        }
    }
    
    $exitHandler = [System.EventHandler] {
        param($sender, $e)
        $Window.Dispatcher.Invoke([Action]{
            $Script:Timer.Stop()
            $btnRun.IsEnabled = $true
            $btnStop.IsEnabled = $false
            
            $exitCode = $Script:ActiveProcess.ExitCode
            $separator = New-Object string ('-', 48)
            $nl = [Environment]::NewLine

            if ($exitCode -eq 0) {
                $txtOutput.AppendText("${nl}${separator}${nl}PROCESS COMPLETED SUCCESSFULLY.")
                $txtStatus.Text = "Ready"
                $txtStatusIcon.Text = "V"
                $txtStatusIcon.Foreground = [System.Windows.Media.Brushes]::Green
            } else {
                $txtOutput.AppendText("${nl}${separator}${nl}PROCESS EXITED WITH CODE: $exitCode")
                $txtStatus.Text = "Error"
                $txtStatusIcon.Text = "X"
                $txtStatusIcon.Foreground = [System.Windows.Media.Brushes]::Red
            }
            $txtOutput.ScrollToEnd()
            
            # Clean up
            $Script:ActiveProcess.remove_OutputDataReceived($outHandler)
            $Script:ActiveProcess.remove_ErrorDataReceived($outHandler)
            $Script:ActiveProcess.remove_Exited($exitHandler)
            $Script:ActiveProcess.Dispose()
            $Script:ActiveProcess = $null
        })
    }

    $Script:ActiveProcess.add_OutputDataReceived($outHandler)
    $Script:ActiveProcess.add_ErrorDataReceived($outHandler)
    $Script:ActiveProcess.add_Exited($exitHandler)

    try {
        $Script:ActiveProcess.Start() | Out-Null
        $Script:ActiveProcess.BeginOutputReadLine()
        $Script:ActiveProcess.BeginErrorReadLine()
    } catch {
        $nl = [Environment]::NewLine
        $txtOutput.AppendText("${nl}FAILED TO START: $($_.Exception.Message)")
        $btnRun.IsEnabled = $true
        $btnStop.IsEnabled = $false
        $Script:Timer.Stop()
    }
})

$btnStop.Add_Click({
    if ($Script:ActiveProcess -ne $null -and -not $Script:ActiveProcess.HasExited) {
        $separator = New-Object string ('-', 48)
        $nl = [Environment]::NewLine
        $txtOutput.AppendText("${nl}${separator}${nl}TERMINATING PROCESS...")
        try {
            $Script:ActiveProcess.Kill()
        } catch {
            Write-Warning "Could not kill process."
        }
    }
})

# ==========================================
# 6. INITIALIZATION & LAUNCH
# ==========================================
Load-Category "Assessments"

# Show Window
[void]$Window.ShowDialog()
# SIG # Begin signature block
# MIIFiwYJKoZIhvcNAQcCoIIFfDCCBXgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUpobDInrtp7aM4Uog89vnXgur
# DFegggMcMIIDGDCCAgCgAwIBAgIQdTnGUb3fnrZCF1K2xTtGMjANBgkqhkiG9w0B
# AQsFADAkMSIwIAYDVQQDDBlDSEVTSS1KRENvZGUtU2lnbmluZy0yMDI2MB4XDTI2
# MDMwNjE0NDY0NVoXDTI3MDMwNjE0NDY0NVowJDEiMCAGA1UEAwwZQ0hFU0ktSkRD
# b2RlLVNpZ25pbmctMjAyNjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# AMIvE+cjfWSthiMrydvmvgrd9ucGb77R+W5jS2EfE73xAMxLBjZBbfTdh8Ig1Oj2
# aZuTWPwXoETEdh4ocXbtyYX0WDXqnNwSzDGDLKNiMzQ2bJEgfeegSGazOCUXchya
# x82YR81WyxGd4sIqBBC3JpFxr+O6MZHHtqUHkkHyUY1Q8phH40X6UOH+l7AIB3yC
# zxqyEJ68RNQFh4UhD2dS4DneN0xyPlQ/VhXcMF4dONwQz7lSIIgD+iiJzXo9Ka7F
# ZOGm1jtq7i/p3XwLuq3zMxgeHh3VcVWh2QbO2PODgIxtchRMFBkW5BtiBjV5nSs7
# D879uPSkhTEGk2UAHDDsbKkCAwEAAaNGMEQwDgYDVR0PAQH/BAQDAgeAMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBQGI/EgF0UkEE5pOr6J/upQmqqo2jAN
# BgkqhkiG9w0BAQsFAAOCAQEABPRv9v2ibkmhWvzlXApwWNScLZ2c6r1ErdcIYEDf
# UHMPwiWV8ztOT9cK6NunF9VjPSb/dCxu2OU+F+HGl1utqoTtPMV+95p9ctwu12KR
# 20/JxfmfoGu1dTYQYZZeWapbBNOwwPg3GEti2PNHMCI+QBSN3MbnfABwVFs9T2X+
# 7tQaOdAhY1kqp8siaCoCpwcoGWlhDdO6+hCrI3Qz5oWN/hMCrL6Sm3afgDoh8xzB
# fxnNdcwQq2+etj+JM9Gcz+C8fUnlZmKPn+wEsMS+oZqfEUt5HEzEIe8LVuuub/Ah
# 8eTO2IA6ouL9V9TyN0aWtV2l0qoqyoY+odq6v1QPInnLfDGCAdkwggHVAgEBMDgw
# JDEiMCAGA1UEAwwZQ0hFU0ktSkRDb2RlLVNpZ25pbmctMjAyNgIQdTnGUb3fnrZC
# F1K2xTtGMjAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZ
# BgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYB
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUzkNIIr2hELkT3X/SKLJkcVIJzT8wDQYJ
# KoZIhvcNAQEBBQAEggEAmybg0WAEKU8YC03PjsGK7mWk6I1E9u0u+U68vOP759f3
# sUbP1NkRbQDQZLa93reQjqppxbfe3MLmXshmiIKaXKuDjQAeHE3P3o7ornjkqgva
# ERmjzQqxW9X/Zakhv0rsmXHOaLsuHXgA0K3zhcqBgqI05qnr1xXcfBo18YwWBVo5
# 6q3zVtUNgPEc2g5F9t9M7YGLGPGE10N7pXJz6nxOZXrDROzx95YhMTP4jdeZ78Ep
# uuINqYvZVGlW4/Fm55LY4P9TjPnyIRse9pBzALSTMjmsLWy4GMpDjMZ2Bag5W+FI
# xDEmeFyLdlnVrTT+RYDAW1tuzA2ZPNtAyrlc4I/hng==
# SIG # End signature block
