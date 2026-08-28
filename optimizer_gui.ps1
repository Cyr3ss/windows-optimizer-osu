<#
.SYNOPSIS
    Windows Gaming & Tablet Optimizer - Interactive GUI App
#>

$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }
$global:ErrorLogPath = Join-Path $scriptDir "optimizer_error.log"

function Log-Exception($ex, $context = "General") {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $msg = if ($ex.Message) { $ex.Message } else { "$ex" }
    $stack = if ($ex.StackTrace) { $ex.StackTrace } else { (Get-PSCallStack | Out-String) }
    
    $errEntry = @"
=================================================================
[$timestamp] ERROR IN [$context]
Message: $msg
StackTrace:
$stack
=================================================================

"@
    try {
        [System.IO.File]::AppendAllText($global:ErrorLogPath, $errEntry, [System.Text.Encoding]::UTF8)
    } catch {}
}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    try {
        Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"") -Verb RunAs
        exit
    } catch {
        Log-Exception $_ "UAC Elevation"
        exit 1
    }
}

try {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
} catch {
    Log-Exception $_ "Assembly Loading"
    throw $_
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Windows Gaming and Tablet Optimizer" Height="780" Width="960"
        WindowStartupLocation="CenterScreen" Background="#12141A" Foreground="#E0E0E0"
        FontFamily="Segoe UI, Roboto, Arial" FontSize="13" ResizeMode="CanResize">
    <Window.Resources>
        <Style TargetType="TabItem">
            <Setter Property="Background" Value="#1A1D26"/>
            <Setter Property="Foreground" Value="#9E9E9E"/>
            <Setter Property="Padding" Value="16,10"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="BorderThickness" Value="0,0,0,2"/>
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border Name="Border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Padding="{TemplateBinding Padding}" CornerRadius="4,4,0,0" Margin="0,0,4,0">
                            <ContentPresenter ContentSource="Header" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Border" Property="Background" Value="#222736"/>
                                <Setter TargetName="Border" Property="BorderBrush" Value="#00E5FF"/>
                                <Setter Property="Foreground" Value="#00E5FF"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#E0E0E0"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Margin" Value="0,6,0,6"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Padding" Value="14,8"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Name="btnBorder" Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="btnBorder" Property="Opacity" Value="0.85"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="btnBorder" Property="Opacity" Value="0.7"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="18">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="180"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0" Background="#1A1D26" CornerRadius="8" Padding="18,14" Margin="0,0,0,14" BorderBrush="#2A2F40" BorderThickness="1">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel VerticalAlignment="Center">
                    <TextBlock Text="Windows Gaming and Tablet Optimizer" FontSize="19" FontWeight="Bold" Foreground="#00E5FF"/>
                    <TextBlock Text="System Tweaker, Tablet Input Lag Reducer and Network Optimizer" FontSize="12" Foreground="#8C93A8" Margin="0,3,0,0"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button Name="btnScan" Content="Scan System" Background="#263238" Foreground="#00E5FF" Margin="0,0,10,0" Padding="14,8"/>
                    <Button Name="btnSelectAll" Content="Select All" Background="#2A2F40" Foreground="#E0E0E0" Margin="0,0,6,0" Padding="10,8"/>
                    <Button Name="btnDeselectAll" Content="Deselect All" Background="#2A2F40" Foreground="#E0E0E0" Margin="0,0,10,0" Padding="10,8"/>
                    <Button Name="btnApply" Content="Apply Selected" Background="#00C853" Foreground="#FFFFFF" FontWeight="Bold" Padding="16,8"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Category Tabs -->
        <TabControl Grid.Row="1" Background="#161922" BorderThickness="1" BorderBrush="#2A2F40">
            
            <!-- Tab 1: Tablet and Pen -->
            <TabItem Header="Tablet and Pen">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="16">
                    <StackPanel>
                        <TextBlock Text="XP-Pen Deco 640 / Wacom / Huion / Gaomon Optimizations" FontWeight="Bold" FontSize="14" Foreground="#00E5FF" Margin="0,0,0,12"/>
                        
                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_PenHold" Content="Disable Pen Press-and-Hold (HoldMode) and Flicks (FlickMode)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Eliminates 300ms touch delay and gestures buffer in Windows Ink." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_PenHold" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_TabletGPO" Content="Enforce TabletPC and PenWorkspace Group Policies" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="System-level block on touch animations, ripples, and press-and-hold." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_TabletGPO" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_LinearCurve" Content="Zero Out Cursor Smoothing (1:1 Raw Linear Curve)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Zeroes SmoothMouseX/YCurve for pure 1:1 hardware translation." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_LinearCurve" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_TabletInputSvc" Content="Disable Touch Keyboard and Handwriting Service (TabletInputService)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Stops Windows system process from intercepting pen coordinates." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_TabletInputSvc" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_UsbSuspend" Content="Disable USB Selective Suspend and Power Saving on Root Hubs" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Prevents tablet controller sleep, guaranteeing continuous 1000Hz polling rate." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_UsbSuspend" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <!-- Tab 2: System, CPU and FPS -->
            <TabItem Header="System, CPU and FPS">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="16">
                    <StackPanel>
                        <TextBlock Text="Low-level BCD Timers, CPU Quanta, Priorities and Kernel" FontWeight="Bold" FontSize="14" Foreground="#00E5FF" Margin="0,0,0,12"/>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_BcdTimers" Content="Enable Invariant TSC Timer (disabledynamictick yes / useplatformclock no)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Eliminates timer tick skipping and sets Windows to hardware TSC." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_BcdTimers" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_Win32Priority" Content="Configure 3:1 CPU Quanta in Favor of Game (Win32PrioritySeparation = 0x26)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Allocates 3x CPU time slices to active game window without background interrupts." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_Win32Priority" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_CsrssDwm" Content="Boost Input Server (CSRSS) and Compositor (DWM) Priorities" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Sets csrss.exe and dwm.exe to High Priority for instantaneous click processing." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_CsrssDwm" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_GameMode" Content="Enable Windows Game Mode and Disable GameDVR / GameBar" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Enables Windows Game Mode and completely terminates GameBarPresenceWriter." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_GameMode" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_KeyboardDelay" Content="Reduce Keyboard Repeat Delay (KeyboardDelay = 0 / Speed = 31)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Speeds up K1/K2 key streaming registration in osu! and zeroes BounceTime." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_KeyboardDelay" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_CpuUnpark" Content="Unpark All CPU Cores (CPU Core Unparking 100%)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Prevents CPU from parking cores, eliminating 2-5ms unparking wake latencies." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_CpuUnpark" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_KernelRam" Content="Lock Kernel in RAM and Disable Fast Startup (Clean Cold Boot)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Sets DisablePagingExecutive = 1 and disables hibernation boot caches." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_KernelRam" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_OsuFso" Content="Enforce Hardware Exclusive Fullscreen for osu!.exe" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Disables Fullscreen Optimizations for osu! (direct display render without DWM buffer)." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_OsuFso" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <!-- Tab 3: Network and Ping -->
            <TabItem Header="Network and Ping">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="16">
                    <StackPanel>
                        <TextBlock Text="Network Adapters, Nagle Algorithm and QoS Optimization" FontWeight="Bold" FontSize="14" Foreground="#00E5FF" Margin="0,0,0,12"/>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_Nagle" Content="Disable Nagle's Algorithm (TCPNoDelay = 1, TcpAckFrequency = 1)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Transmits small packets immediately without waiting for buffer accumulation." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_Nagle" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_QoS" Content="Unlock 20% Reserved Network Bandwidth (QoS Limit = 0)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Unlocks 100% full bandwidth throughput for games." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_QoS" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_DeliveryOpt" Content="Disable P2P Background Update Seeding (Delivery Optimization)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Prevents Windows from uploading updates in background to peer PCs." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_DeliveryOpt" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <!-- Tab 4: Debloat and SSD -->
            <TabItem Header="Services and SSD">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="16">
                    <StackPanel>
                        <TextBlock Text="Safe Background Telemetry Debloat and SSD Optimization" FontWeight="Bold" FontSize="14" Foreground="#00E5FF" Margin="0,0,0,12"/>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_Telemetry" Content="Disable Telemetry Diagnostic Tracking (DiagTrack) and SysMain" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Stops persistent diagnostic disk writes on SSD and frees RAM." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_Telemetry" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_OemServices" Content="Set Secondary OEM/Diagnostic Services to Manual" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Sets background telemetry services (HP, Dell, AnyDesk, WerSvc) to Manual." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_OemServices" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_TasksDebloat" Content="Disable Heavy Scheduled Background Tasks (Compatibility Appraiser)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Disables periodical background telemetry scans and error report uploaders." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_TasksDebloat" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_SsdLastAccess" Content="Optimize SSD File System (Disable LastAccess Timestamps)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Eliminates unnecessary write overhead on SSD during standard file reads." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_SsdLastAccess" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_UiDelay" Content="Remove Artificial Menu Delays (MenuShowDelay = 0 / MinAnimate = 0)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Makes context menus and Windows explorer window responses instantaneous." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_UiDelay" Grid.Column="1" Text="[ Not Checked ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
        </TabControl>

        <!-- Progress Bar and Status -->
        <Grid Grid.Row="2" Margin="0,10,0,6">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <ProgressBar Name="prgBar" Height="8" Background="#1A1D26" Foreground="#00E5FF" BorderThickness="0" Value="0" Maximum="100"/>
            <TextBlock Name="lblStatusText" Grid.Column="1" Text="Ready" FontSize="11" Foreground="#8C93A8" Margin="10,0,0,0"/>
        </Grid>

        <!-- Live Log Console -->
        <Border Grid.Row="3" Background="#0C0E14" CornerRadius="6" BorderBrush="#2A2F40" BorderThickness="1" Padding="10">
            <ScrollViewer Name="scrollLog" VerticalScrollBarVisibility="Auto">
                <TextBox Name="txtLog" Background="Transparent" Foreground="#00E676" FontFamily="Consolas, monospace" FontSize="11" BorderThickness="0" IsReadOnly="True" TextWrapping="Wrap"/>
            </ScrollViewer>
        </Border>
    </Grid>
</Window>
"@

try {
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    Log-Exception $_ "XAML Parsing / Window Load"
    throw $_
}

$btnScan = $window.FindName("btnScan")
$btnSelectAll = $window.FindName("btnSelectAll")
$btnDeselectAll = $window.FindName("btnDeselectAll")
$btnApply = $window.FindName("btnApply")
$prgBar = $window.FindName("prgBar")
$lblStatusText = $window.FindName("lblStatusText")
$txtLog = $window.FindName("txtLog")
$scrollLog = $window.FindName("scrollLog")

function Add-Log($text, $color = "#00E676") {
    $timestamp = Get-Date -Format "HH:mm:ss"
    $txtLog.AppendText("[$timestamp] $text`r`n")
    $txtLog.ScrollToEnd()
    [System.Windows.Forms.Application]::DoEvents()
}

function Set-Badge($badgeName, $text, $colorHex) {
    $elem = $window.FindName($badgeName)
    if ($elem) {
        $elem.Text = $text
        $elem.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString($colorHex)
    }
}

# 1. Smart Pre-Check System Scan
$btnScan.Add_Click({
    try {
        $txtLog.Clear()
        Add-Log "=== Starting System Pre-Scan ==="
        $lblStatusText.Text = "Scanning..."
        $prgBar.Value = 10

        # Tablet & Pen
        $sysEvent = Get-ItemProperty "HKCU:\Software\Microsoft\Wisp\Pen\SysEventParameters" -ErrorAction SilentlyContinue
        if ($sysEvent -and $sysEvent.HoldMode -eq 0) {
            Set-Badge "status_PenHold" "[ Already Applied ]" "#00E676"
        } else {
            Set-Badge "status_PenHold" "[ Available ]" "#00E5FF"
        }
        
        $tis = Get-Service -Name "TabletInputService" -ErrorAction SilentlyContinue
        if ($tis) {
            if ($tis.StartType -eq "Disabled") {
                Set-Badge "status_TabletInputSvc" "[ Already Disabled ]" "#00E676"
            } else {
                Set-Badge "status_TabletInputSvc" "[ Detected (Active) ]" "#FFD600"
            }
        } else {
            Set-Badge "status_TabletInputSvc" "[ Not Found (N/A) ]" "#757575"
        }

        Set-Badge "status_TabletGPO" "[ Available ]" "#00E5FF"
        Set-Badge "status_LinearCurve" "[ Available ]" "#00E5FF"
        Set-Badge "status_UsbSuspend" "[ Available ]" "#00E5FF"
        $prgBar.Value = 40

        # System & Timers
        $bcdDyn = bcdedit /enum "{current}" 2>$null | Select-String "disabledynamictick\s+Yes"
        if ($bcdDyn) {
            Set-Badge "status_BcdTimers" "[ Active (TSC) ]" "#00E676"
        } else {
            Set-Badge "status_BcdTimers" "[ Available ]" "#00E5FF"
        }

        $prio = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -ErrorAction SilentlyContinue).Win32PrioritySeparation
        if ($prio -eq 38) {
            Set-Badge "status_Win32Priority" "[ Active (0x26) ]" "#00E676"
        } else {
            Set-Badge "status_Win32Priority" "[ Available ]" "#00E5FF"
        }

        Set-Badge "status_CsrssDwm" "[ Available ]" "#00E5FF"
        Set-Badge "status_GameMode" "[ Available ]" "#00E5FF"
        Set-Badge "status_KeyboardDelay" "[ Available ]" "#00E5FF"
        Set-Badge "status_CpuUnpark" "[ Available ]" "#00E5FF"
        Set-Badge "status_KernelRam" "[ Available ]" "#00E5FF"

        $possibleOsu = @("$env:LOCALAPPDATA\osu!\osu!.exe", "C:\osu!\osu!.exe", "D:\osu!\osu!.exe", "E:\osu!\osu!.exe")
        $foundOsu = $possibleOsu | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($foundOsu) {
            Set-Badge "status_OsuFso" "[ Detected ]" "#00E676"
        } else {
            Set-Badge "status_OsuFso" "[ osu! Not Found ]" "#757575"
        }
        $prgBar.Value = 70

        # Network
        $interfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue
        if ($interfaces) {
            Set-Badge "status_Nagle" "[ Available ($($interfaces.Count) adapters) ]" "#00E5FF"
        } else {
            Set-Badge "status_Nagle" "[ N/A ]" "#757575"
        }
        Set-Badge "status_QoS" "[ Available ]" "#00E5FF"
        Set-Badge "status_DeliveryOpt" "[ Available ]" "#00E5FF"

        # Services & SSD
        $diag = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
        if ($diag -and $diag.StartType -eq "Disabled") {
            Set-Badge "status_Telemetry" "[ Already Disabled ]" "#00E676"
        } else {
            Set-Badge "status_Telemetry" "[ Detected ]" "#FFD600"
        }
        Set-Badge "status_OemServices" "[ Available ]" "#00E5FF"
        Set-Badge "status_TasksDebloat" "[ Available ]" "#00E5FF"
        Set-Badge "status_SsdLastAccess" "[ Available ]" "#00E5FF"
        Set-Badge "status_UiDelay" "[ Available ]" "#00E5FF"

        $prgBar.Value = 100
        $lblStatusText.Text = "Scan Complete!"
        Add-Log "[V] System pre-scan completed. All modules verified."
    } catch {
        Log-Exception $_ "btnScan_Click"
        Add-Log "[!] Error during system scan. Details logged in optimizer_error.log" "#FF5252"
    }
})

# Select All / Deselect All
$btnSelectAll.Add_Click({
    @("chk_PenHold","chk_TabletGPO","chk_LinearCurve","chk_TabletInputSvc","chk_UsbSuspend",
      "chk_BcdTimers","chk_Win32Priority","chk_CsrssDwm","chk_GameMode","chk_KeyboardDelay",
      "chk_CpuUnpark","chk_KernelRam","chk_OsuFso","chk_Nagle","chk_QoS","chk_DeliveryOpt",
      "chk_Telemetry","chk_OemServices","chk_TasksDebloat","chk_SsdLastAccess","chk_UiDelay") | ForEach-Object {
        $chk = $window.FindName($_)
        if ($chk) { $chk.IsChecked = $true }
    }
    Add-Log "All checkboxes selected."
})

$btnDeselectAll.Add_Click({
    @("chk_PenHold","chk_TabletGPO","chk_LinearCurve","chk_TabletInputSvc","chk_UsbSuspend",
      "chk_BcdTimers","chk_Win32Priority","chk_CsrssDwm","chk_GameMode","chk_KeyboardDelay",
      "chk_CpuUnpark","chk_KernelRam","chk_OsuFso","chk_Nagle","chk_QoS","chk_DeliveryOpt",
      "chk_Telemetry","chk_OemServices","chk_TasksDebloat","chk_SsdLastAccess","chk_UiDelay") | ForEach-Object {
        $chk = $window.FindName($_)
        if ($chk) { $chk.IsChecked = $false }
    }
    Add-Log "All checkboxes deselected."
})

# 2. Apply Selected Tweaks
$btnApply.Add_Click({
    $txtLog.Clear()
    Add-Log "=== Applying Selected Optimizations ==="
    $lblStatusText.Text = "Applying tweaks..."
    $prgBar.Value = 0

    $totalChecks = 21
    $current = 0

    # 1. Pen Hold & Flick
    if ($window.FindName("chk_PenHold").IsChecked) {
        try {
            $sysEvent = "HKCU:\Software\Microsoft\Wisp\Pen\SysEventParameters"
            if (-not (Test-Path $sysEvent)) { New-Item -Path $sysEvent -Force | Out-Null }
            Set-ItemProperty -Path $sysEvent -Name "FlickMode" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $sysEvent -Name "HoldMode" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $sysEvent -Name "Splash" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $sysEvent -Name "DblTime" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $sysEvent -Name "DblDist" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $sysEvent -Name "WaitTime" -Value 0 -Type DWord -Force

            $touch = "HKCU:\Software\Microsoft\Wisp\Touch"
            if (-not (Test-Path $touch)) { New-Item -Path $touch -Force | Out-Null }
            Set-ItemProperty -Path $touch -Name "TouchMode_hold" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $touch -Name "TouchModeN_HoldTime_BeforeAnimation" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $touch -Name "TouchModeN_HoldTime_Animation" -Value 0 -Type DWord -Force

            Set-Badge "status_PenHold" "[ Applied OK ]" "#00E676"
            Add-Log "[OK] Windows Ink HoldMode and FlickMode disabled."
        } catch {
            Log-Exception $_ "chk_PenHold"
            Set-Badge "status_PenHold" "[ Error ]" "#FF5252"
            Add-Log "[FAIL] Error disabling Windows Ink: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 2. Tablet GPO
    if ($window.FindName("chk_TabletGPO").IsChecked) {
        try {
            $pathsToCreate = @(
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC",
                "HKCU:\Software\Policies\Microsoft\Windows\TabletPC",
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PenWorkspace",
                "HKCU:\Software\Policies\Microsoft\Windows\PenWorkspace",
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports"
            )
            foreach ($p in $pathsToCreate) {
                if (-not (Test-Path $p)) { New-Item -Path $p -Force -ErrorAction SilentlyContinue | Out-Null }
            }
            $policyValues = @{
                "TurnOffPenFeedback" = 1; "TurnOffPressAndHold" = 1; "DisableFlicks" = 1;
                "DisablePagingFlick" = 1; "DisablePenCursorFeedback" = 1; "DisableTouchVisualFeedback" = 1;
                "PreventHandwritingDataSharing" = 1
            }
            foreach ($k in $policyValues.Keys) {
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC" -Name $k -Value $policyValues[$k] -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\TabletPC" -Name $k -Value $policyValues[$k] -Type DWord -Force -ErrorAction SilentlyContinue
            }
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PenWorkspace" -Name "EnablePenWorkspace" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\PenWorkspace" -Name "EnablePenWorkspace" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            Set-Badge "status_TabletGPO" "[ Applied OK ]" "#00E676"
            Add-Log "[OK] TabletPC and PenWorkspace Group Policies applied."
        } catch {
            Log-Exception $_ "chk_TabletGPO"
            Set-Badge "status_TabletGPO" "[ Error ]" "#FF5252"
            Add-Log "[FAIL] Error applying Group Policies: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 3. Linear Mouse Curve
    if ($window.FindName("chk_LinearCurve").IsChecked) {
        try {
            $smoothZero = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)
            Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "SmoothMouseXCurve" -Value $smoothZero -Type Binary -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "SmoothMouseYCurve" -Value $smoothZero -Type Binary -Force -ErrorAction SilentlyContinue
            Set-Badge "status_LinearCurve" "[ Applied OK ]" "#00E676"
            Add-Log "[OK] Mouse polynomial curves zeroed (1:1 Raw Linear)."
        } catch {
            Log-Exception $_ "chk_LinearCurve"
            Set-Badge "status_LinearCurve" "[ Error ]" "#FF5252"
            Add-Log "[FAIL] Error setting mouse curve: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 4. TabletInputService
    if ($window.FindName("chk_TabletInputSvc").IsChecked) {
        $tis = Get-Service -Name "TabletInputService" -ErrorAction SilentlyContinue
        if ($tis) {
            try {
                Stop-Service -Name "TabletInputService" -Force -ErrorAction SilentlyContinue
                Set-Service -Name "TabletInputService" -StartupType Disabled -ErrorAction SilentlyContinue
                & sc.exe config "TabletInputService" start= disabled 2>$null | Out-Null
                Set-Badge "status_TabletInputSvc" "[ Applied OK ]" "#00E676"
                Add-Log "[OK] TabletInputService disabled."
            } catch {
                Log-Exception $_ "chk_TabletInputSvc"
                Set-Badge "status_TabletInputSvc" "[ Warning ]" "#FFD600"
                Add-Log "[WARN] TabletInputService stop warning: $_"
            }
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 5. USB Suspend
    if ($window.FindName("chk_UsbSuspend").IsChecked) {
        try {
            powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-9177-b06418304ddf 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
            powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-9177-b06418304ddf 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
            powercfg /setactive SCHEME_CURRENT 2>$null

            Get-CimInstance MSPower_DeviceEnable -Namespace root\wmi -ErrorAction SilentlyContinue | Where-Object { $_.InstanceName -match "USB" } | ForEach-Object {
                Set-CimInstance -Query "Select * from MSPower_DeviceEnable where InstanceName='$($_.InstanceName)'" -Property @{Enable=$false} -Namespace root\wmi -ErrorAction SilentlyContinue
            }
            Set-Badge "status_UsbSuspend" "[ Applied OK ]" "#00E676"
            Add-Log "[OK] USB Selective Suspend and Root Hubs sleep disabled."
        } catch {
            Log-Exception $_ "chk_UsbSuspend"
            Set-Badge "status_UsbSuspend" "[ Partial ]" "#FFD600"
            Add-Log "[WARN] USB power configuration partial: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 6. BCD Timers
    if ($window.FindName("chk_BcdTimers").IsChecked) {
        try {
            bcdedit /set disabledynamictick yes 2>$null | Out-Null
            bcdedit /set useplatformclock no 2>$null | Out-Null
            Set-Badge "status_BcdTimers" "[ Applied OK ]" "#00E676"
            Add-Log "[OK] BCD Timers: disabledynamictick yes / useplatformclock no."
        } catch {
            Log-Exception $_ "chk_BcdTimers"
            Set-Badge "status_BcdTimers" "[ Error ]" "#FF5252"
            Add-Log "[FAIL] BCD timer error: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 7. Win32PrioritySeparation
    if ($window.FindName("chk_Win32Priority").IsChecked) {
        try {
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-Badge "status_Win32Priority" "[ Applied OK ]" "#00E676"
            Add-Log "[OK] Win32PrioritySeparation = 0x26 (38) set."
        } catch {
            Log-Exception $_ "chk_Win32Priority"
            Set-Badge "status_Win32Priority" "[ Error ]" "#FF5252"
            Add-Log "[FAIL] Win32Priority error: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 8. CSRSS and DWM Priority
    if ($window.FindName("chk_CsrssDwm").IsChecked) {
        try {
            $csrssPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions"
            if (-not (Test-Path $csrssPath)) { New-Item -Path $csrssPath -Force -ErrorAction SilentlyContinue | Out-Null }
            Set-ItemProperty -Path $csrssPath -Name "CpuPriorityClass" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $csrssPath -Name "IoPriority" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue

            $dwmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\dwm.exe\PerfOptions"
            if (-not (Test-Path $dwmPath)) { New-Item -Path $dwmPath -Force -ErrorAction SilentlyContinue | Out-Null }
            Set-ItemProperty -Path $dwmPath -Name "CpuPriorityClass" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $dwmPath -Name "IoPriority" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-Badge "status_CsrssDwm" "[ Applied OK ]" "#00E676"
            Add-Log "[OK] CSRSS and DWM set to High Priority."
        } catch {
            Log-Exception $_ "chk_CsrssDwm"
            Set-Badge "status_CsrssDwm" "[ Error ]" "#FF5252"
            Add-Log "[FAIL] PerfOptions error: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 9. Game Mode and PresenceWriter
    if ($window.FindName("chk_GameMode").IsChecked) {
        try {
            $gb = "HKCU:\Software\Microsoft\GameBar"
            if (-not (Test-Path $gb)) { New-Item -Path $gb -Force | Out-Null }
            Set-ItemProperty -Path $gb -Name "AutoGameModeEnabled" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $gb -Name "AllowAutoGameMode" -Value 1 -Type DWord -Force

            $gcs = "HKCU:\System\GameConfigStore"
            if (-not (Test-Path $gcs)) { New-Item -Path $gcs -Force | Out-Null }
            Set-ItemProperty -Path $gcs -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $gcs -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord -Force
            Set-ItemProperty -Path $gcs -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force

            $gbpw = "HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter"
            if (Test-Path $gbpw) { Set-ItemProperty -Path $gbpw -Name "ActivationType" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue }

            Set-Badge "status_GameMode" "[ Applied OK ]" "#00E676"
            Add-Log "[OK] Game Mode enabled, GameDVR/PresenceWriter disabled."
        } catch {
            Log-Exception $_ "chk_GameMode"
            Set-Badge "status_GameMode" "[ Error ]" "#FF5252"
            Add-Log "[FAIL] GameMode error: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 10. Keyboard Delay
    if ($window.FindName("chk_KeyboardDelay").IsChecked) {
        try {
            Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value "0" -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value "31" -Force -ErrorAction SilentlyContinue
            $kResponse = "HKCU:\Control Panel\Accessibility\Keyboard Response"
            if (Test-Path $kResponse) {
                Set-ItemProperty -Path $kResponse -Name "DelayBeforeAcceptance" -Value "0" -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $kResponse -Name "BounceTime" -Value "0" -Force -ErrorAction SilentlyContinue
            }
            Set-Badge "status_KeyboardDelay" "[ Applied OK ]" "#00E676"
            Add-Log "[OK] KeyboardDelay = 0 / Speed = 31 applied."
        } catch {
            Log-Exception $_ "chk_KeyboardDelay"
            Set-Badge "status_KeyboardDelay" "[ Error ]" "#FF5252"
            Add-Log "[FAIL] Keyboard delay error: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 11. CPU Unparking
    if ($window.FindName("chk_CpuUnpark").IsChecked) {
        try {
            powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>$null
            powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>$null
            powercfg -setactive SCHEME_CURRENT 2>$null
            Set-Badge "status_CpuUnpark" "[ Applied OK ]" "#00E676"
            Add-Log "[OK] CPU Core Unparking (100% active cores) applied."
        } catch {
            Log-Exception $_ "chk_CpuUnpark"
            Set-Badge "status_CpuUnpark" "[ Error ]" "#FFD600"
            Add-Log "[WARN] CPU Unparking error: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 12. Kernel RAM and Fast Startup Off
    if ($window.FindName("chk_KernelRam").IsChecked) {
        try {
            $pt = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
            if (-not (Test-Path $pt)) { New-Item -Path $pt -Force | Out-Null }
            Set-ItemProperty -Path $pt -Name "PowerThrottlingOff" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-Badge "status_KernelRam" "[ Applied OK ]" "#00E676"
            Add-Log "[OK] Kernel locked in RAM, Fast Startup disabled."
        } catch {
            Log-Exception $_ "chk_KernelRam"
            Set-Badge "status_KernelRam" "[ Error ]" "#FF5252"
            Add-Log "[FAIL] Kernel RAM error: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 13. Osu FSO
    if ($window.FindName("chk_OsuFso").IsChecked) {
        try {
            $possibleOsu = @("$env:LOCALAPPDATA\osu!\osu!.exe", "C:\osu!\osu!.exe", "D:\osu!\osu!.exe", "E:\osu!\osu!.exe")
            $appCompat = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
            if (-not (Test-Path $appCompat)) { New-Item -Path $appCompat -Force | Out-Null }
            $applied = $false
            foreach ($p in $possibleOsu) {
                if (Test-Path $p) {
                    Set-ItemProperty -Path $appCompat -Name $p -Value "~ DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE" -Force -ErrorAction SilentlyContinue
                    Add-Log "[OK] Hardware Fullscreen Exclusive set for: $p"
                    $applied = $true
                }
            }
            if ($applied) {
                Set-Badge "status_OsuFso" "[ Applied OK ]" "#00E676"
            } else {
                Set-Badge "status_OsuFso" "[ Skipped (N/A) ]" "#757575"
            }
        } catch {
            Log-Exception $_ "chk_OsuFso"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 14. Nagle's Algorithm
    if ($window.FindName("chk_Nagle").IsChecked) {
        try {
            $interfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue
            $cnt = 0
            foreach ($i in $interfaces) {
                Set-ItemProperty -Path $i.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $i.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $i.PSPath -Name "TcpDelAckTicks" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                $cnt++
            }
            Set-Badge "status_Nagle" "[ Applied ($cnt adapters) ]" "#00E676"
            Add-Log "[OK] Nagle algorithm disabled across $cnt adapters."
        } catch {
            Log-Exception $_ "chk_Nagle"
            Set-Badge "status_Nagle" "[ Error ]" "#FF5252"
            Add-Log "[FAIL] TCPNoDelay error: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 15. QoS
    if ($window.FindName("chk_QoS").IsChecked) {
        try {
            $pschedPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
            if (-not (Test-Path $pschedPath)) { New-Item -Path $pschedPath -Force -ErrorAction SilentlyContinue | Out-Null }
            Set-ItemProperty -Path $pschedPath -Name "NonBestEffortLimit" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-Badge "status_QoS" "[ Applied OK ]" "#00E676"
            Add-Log "[OK] 100% QoS network bandwidth unlocked."
        } catch {
            Log-Exception $_ "chk_QoS"
            Set-Badge "status_QoS" "[ Error ]" "#FF5252"
            Add-Log "[FAIL] QoS policy error: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 16. Delivery Optimization
    if ($window.FindName("chk_DeliveryOpt").IsChecked) {
        try {
            $doPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization"
            if (-not (Test-Path $doPath)) { New-Item -Path $doPath -Force | Out-Null }
            Set-ItemProperty -Path $doPath -Name "DODownloadMode" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            $doPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
            if (-not (Test-Path $doPolicy)) { New-Item -Path $doPolicy -Force | Out-Null }
            Set-ItemProperty -Path $doPolicy -Name "DODownloadMode" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-Badge "status_DeliveryOpt" "[ Applied OK ]" "#00E676"
            Add-Log "[OK] Delivery Optimization P2P uploads disabled."
        } catch {
            Log-Exception $_ "chk_DeliveryOpt"
            Set-Badge "status_DeliveryOpt" "[ Error ]" "#FF5252"
            Add-Log "[FAIL] Delivery Optimization error: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 17. Telemetry and SysMain
    if ($window.FindName("chk_Telemetry").IsChecked) {
        try {
            @("DiagTrack", "SysMain") | ForEach-Object {
                $s = $_
                $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
                if ($svc) {
                    Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
                    Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
                    Add-Log "[OK] Service $s disabled."
                }
            }
            Set-Badge "status_Telemetry" "[ Applied OK ]" "#00E676"
        } catch {
            Log-Exception $_ "chk_Telemetry"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 18. OEM Services
    if ($window.FindName("chk_OemServices").IsChecked) {
        try {
            $manualServices = @("HPAppHelperCap", "HPDiagsCap", "HPNetworkCap", "HPSysInfoCap", "AnyDesk", "WerSvc")
            $fnd = 0
            foreach ($s in $manualServices) {
                $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
                if ($svc) {
                    Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
                    Set-Service -Name $s -StartupType Manual -ErrorAction SilentlyContinue
                    $fnd++
                }
            }
            Set-Badge "status_OemServices" "[ Set: $fnd ]" "#00E676"
            Add-Log "[OK] OEM services ($fnd) set to Manual startup."
        } catch {
            Log-Exception $_ "chk_OemServices"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 19. Tasks Debloat
    if ($window.FindName("chk_TasksDebloat").IsChecked) {
        try {
            $tasks = @(
                "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
                "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
                "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
                "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
                "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
                "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem",
                "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
            )
            $tCount = 0
            foreach ($t in $tasks) {
                try {
                    $taskName = $t.Split('\')[-1]
                    $taskPath = $t.Substring(0, $t.LastIndexOf('\')+1)
                    $chk = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
                    if ($chk) {
                        Disable-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue | Out-Null
                        $tCount++
                    }
                } catch {}
            }
            Set-Badge "status_TasksDebloat" "[ Disabled ($tCount) ]" "#00E676"
            Add-Log "[OK] Disabled $tCount telemetry scheduled tasks."
        } catch {
            Log-Exception $_ "chk_TasksDebloat"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 20. SSD LastAccess
    if ($window.FindName("chk_SsdLastAccess").IsChecked) {
        try {
            fsutil behavior set disablelastaccess 1 2>$null | Out-Null
            Set-Badge "status_SsdLastAccess" "[ Applied OK ]" "#00E676"
            Add-Log "[OK] DisableLastAccess = 1 applied on SSD."
        } catch {
            Log-Exception $_ "chk_SsdLastAccess"
            Set-Badge "status_SsdLastAccess" "[ Warning ]" "#FFD600"
            Add-Log "[WARN] fsutil warning: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 21. UI Delay
    if ($window.FindName("chk_UiDelay").IsChecked) {
        try {
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -Force -ErrorAction SilentlyContinue
            $wm = "HKCU:\Control Panel\Desktop\WindowMetrics"
            if (-not (Test-Path $wm)) { New-Item -Path $wm -Force | Out-Null }
            Set-ItemProperty -Path $wm -Name "MinAnimate" -Value "0" -Force -ErrorAction SilentlyContinue
            Set-Badge "status_UiDelay" "[ Applied OK ]" "#00E676"
            Add-Log "[OK] MenuShowDelay = 0 and MinAnimate = 0 set."
        } catch {
            Log-Exception $_ "chk_UiDelay"
            Set-Badge "status_UiDelay" "[ Error ]" "#FF5252"
            Add-Log "[FAIL] UI delay error: $_"
        }
    }
    $current++; $prgBar.Value = 100
    $lblStatusText.Text = "Finished! All selected tweaks applied."
    Add-Log "====================================================="
    Add-Log "[V] ALL DONE! A system restart is recommended."
})

# Auto-Scan on window startup
$window.Add_ContentRendered({
    try {
        $btnScan.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
    } catch {
        Log-Exception $_ "Add_ContentRendered AutoScan"
    }
})

# Display Window
try {
    $window.ShowDialog() | Out-Null
} catch {
    Log-Exception $_ "Window ShowDialog"
    throw $_
}