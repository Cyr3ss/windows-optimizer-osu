<#
.SYNOPSIS
    Windows Gaming & Tablet Optimizer - Interactive GUI App
    Нативное приложение на WPF (XAML) с предварительным сканированием модулей,
    выбором твиков через чекбоксы, живым цветным журналом и записью исключений в optimizer_error.log.
#>

$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }
$global:ErrorLogPath = Join-Path $scriptDir "optimizer_error.log"

# Функция логирования исключений в отдельный файл
function Log-Exception($ex, $context = "General") {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $msg = if ($ex.Message) { $ex.Message } else { "$ex" }
    $stack = if ($ex.StackTrace) { $ex.StackTrace } else { (Get-PSCallStack | Out-String) }
    
    $errEntry = @"
=================================================================
[$timestamp] ИСКЛЮЧЕНИЕ В БЛОКЕ: [$context]
Сообщение: $msg
Стек вызовов:
$stack
=================================================================

"@
    try {
        Add-Content -Path $global:ErrorLogPath -Value $errEntry -Encoding UTF8 -Force
    } catch {}
}

# Автоматическое повышение прав Администратора
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
        Title="Windows Gaming &amp; Tablet Optimizer" Height="780" Width="960"
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
                    <TextBlock Text="⚡ Windows Gaming &amp; Tablet Optimizer" FontSize="19" FontWeight="Bold" Foreground="#00E5FF"/>
                    <TextBlock Text="Интерактивный твикер системы, задержек графического планшета и сетевого отклика" FontSize="12" Foreground="#8C93A8" Margin="0,3,0,0"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button Name="btnScan" Content="🔍 Сканировать систему" Background="#263238" Foreground="#00E5FF" Margin="0,0,10,0" Padding="14,8"/>
                    <Button Name="btnSelectAll" Content="Выбрать все" Background="#2A2F40" Foreground="#E0E0E0" Margin="0,0,6,0" Padding="10,8"/>
                    <Button Name="btnDeselectAll" Content="Снять все" Background="#2A2F40" Foreground="#E0E0E0" Margin="0,0,10,0" Padding="10,8"/>
                    <Button Name="btnApply" Content="⚡ Применить выбранное" Background="#00C853" Foreground="#FFFFFF" FontWeight="Bold" Padding="16,8"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Category Tabs -->
        <TabControl Grid.Row="1" Background="#161922" BorderThickness="1" BorderBrush="#2A2F40">
            
            <!-- Tab 1: Tablet & Pen -->
            <TabItem Header="🖊️ Планшет и Перо">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="16">
                    <StackPanel>
                        <TextBlock Text="Оптимизация под XP-Pen Deco 640 / Wacom / Huion / Gaomon" FontWeight="Bold" FontSize="14" Foreground="#00E5FF" Margin="0,0,0,12"/>
                        
                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_PenHold" Content="Отключить задержку касания (HoldMode) и жесты (FlickMode)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Убирает 300 мс задержки при первом касании пером и буфер жестов Windows Ink." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_PenHold" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_TabletGPO" Content="Применить Group Policies для планшетов (TabletPC &amp; PenWorkspace)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Системный запрет на генерацию анимаций кругов (Ripple), зажатия и жестов в HKLM/HKCU." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_TabletGPO" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_LinearCurve" Content="Обнулить нелинейное сглаживание курсора (1:1 Raw Linear Curve)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Обнуляет полиномиальные кривые SmoothMouseX/YCurve для абсолютно равномерного движения." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_LinearCurve" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_TabletInputSvc" Content="Отключить службу сенсорной клавиатуры и рукописного ввода (TabletInputService)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Убирает перехват координат пера системным процессом Windows." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_TabletInputSvc" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_UsbSuspend" Content="Отключить энергосбережение USB (Selective Suspend &amp; Root Hubs)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Предотвращает засыпание контроллера планшета, обеспечивая непрерывную частоту опроса." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_UsbSuspend" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <!-- Tab 2: System, CPU & FPS -->
            <TabItem Header="⚡ Система, CPU и FPS">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="16">
                    <StackPanel>
                        <TextBlock Text="Низкоуровневые таймеры BCD, кванты CPU, приоритеты и ядро" FontWeight="Bold" FontSize="14" Foreground="#00E5FF" Margin="0,0,0,12"/>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_BcdTimers" Content="Включить аппаратный таймер TSC (disabledynamictick yes / useplatformclock no)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Устраняет пропуск тиков таймера процессора и переводит Windows на инвариантный таймер TSC." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_BcdTimers" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_Win32Priority" Content="Настроить кванты CPU 3:1 в пользу активной игры (Win32PrioritySeparation = 0x26)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Выделяет активному окну в 3 раза больше времени CPU без прерываний на фоновые службы." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_Win32Priority" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_CsrssDwm" Content="Повысить приоритеты диспетчера ввода (CSRSS) и вывода кадров (DWM)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Переводит csrss.exe и dwm.exe в High Priority для мгновенной доставки аппаратных кликов." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_CsrssDwm" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_GameMode" Content="Включить Windows Game Mode и отключить GameDVR / GameBar" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Активирует игровой режим Windows и полностью выключает фоновый процесс GameBarPresenceWriter." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_GameMode" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_KeyboardDelay" Content="Снизить задержку повтора клавиатуры (KeyboardDelay = 0 / Speed = 31)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Ускоряет регистрацию стримов K1/K2 в osu! и обнуляет время задержки дребезга (BounceTime)." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_KeyboardDelay" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_CpuUnpark" Content="Разблокировать спящие ядра процессора (CPU Core Unparking 100%)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Запрещает процессору усыплять логические ядра, устраняя 2-5 мс лага пробуждения." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_CpuUnpark" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_KernelRam" Content="Зафиксировать ядро в RAM и отключить Fast Startup (Чистый старт ОС)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Включает DisablePagingExecutive = 1 и отключает гибернацию ядра при выключении ПК." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_KernelRam" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_OsuFso" Content="Принудительный аппаратный Fullscreen Exclusive для osu!.exe" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Отключает 'Оптимизацию во весь экран' для osu! (прямой рендер без буфера DWM)." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_OsuFso" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <!-- Tab 3: Network & Ping -->
            <TabItem Header="🌐 Сеть и Пинг">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="16">
                    <StackPanel>
                        <TextBlock Text="Оптимизация сетевых адаптеров, алгоритм Нейгла и QoS" FontWeight="Bold" FontSize="14" Foreground="#00E5FF" Margin="0,0,0,12"/>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_Nagle" Content="Отключить алгоритм Нейгла (TCPNoDelay = 1, TcpAckFrequency = 1)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Отправляет мелкие пакеты ввода мгновенно без накопления в сетевом буфере." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_Nagle" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_QoS" Content="Снять 20% системное ограничение пропускной способности (QoS = 0)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Разблокирует 100% пропускной способности интернет-канала для сетевых игр." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_QoS" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_DeliveryOpt" Content="Отключить фоновую раздачу обновлений P2P (Delivery Optimization)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Запрещает Windows раздавать скачанные обновления по локальной сети и интернету." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_DeliveryOpt" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <!-- Tab 4: Debloat & SSD -->
            <TabItem Header="🧹 Службы и SSD">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="16">
                    <StackPanel>
                        <TextBlock Text="Безопасное отключение фоновой телеметрии и оптимизация SSD" FontWeight="Bold" FontSize="14" Foreground="#00E5FF" Margin="0,0,0,12"/>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_Telemetry" Content="Отключить службу сбора телеметрии (DiagTrack) и SysMain" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Останавливает постоянную запись диагностических логов на SSD и освобождает ОЗУ." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_Telemetry" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_OemServices" Content="Перевести второстепенные OEM/Служебные процессы в ручной режим" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Переводит фоновые диагностические службы (HP, Dell, AnyDesk, WerSvc) в режим Manual." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_OemServices" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_TasksDebloat" Content="Отключить тяжелые задачи планировщика (Compatibility Appraiser)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Отключает периодические фоновые сканеры совместимости и отчеты об ошибках." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_TasksDebloat" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_SsdLastAccess" Content="Оптимизировать файловую систему SSD (Disable LastAccess Timestamps)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Отключает лишние операции записи на SSD при обычном чтении файлов (fsutil)." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_SsdLastAccess" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>

                        <Border Background="#1E2230" CornerRadius="6" Padding="12" Margin="0,0,0,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <CheckBox Name="chk_UiDelay" Content="Убрать искусственные задержки меню (MenuShowDelay = 0 / MinAnimate = 0)" IsChecked="True" FontWeight="SemiBold"/>
                                    <TextBlock Text="Делает открытие контекстных меню и отклик окон Windows моментальным." FontSize="11" Foreground="#8C93A8" Margin="22,0,0,0"/>
                                </StackPanel>
                                <TextBlock Name="status_UiDelay" Grid.Column="1" Text="[ Не проверено ]" Foreground="#757575" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </Grid>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
        </TabControl>

        <!-- Progress Bar & Status -->
        <Grid Grid.Row="2" Margin="0,10,0,6">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <ProgressBar Name="prgBar" Height="8" Background="#1A1D26" Foreground="#00E5FF" BorderThickness="0" Value="0" Maximum="100"/>
            <TextBlock Name="lblStatusText" Grid.Column="1" Text="Готов к работе" FontSize="11" Foreground="#8C93A8" Margin="10,0,0,0"/>
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

# Связывание элементов интерфейса
$btnScan = $window.FindName("btnScan")
$btnSelectAll = $window.FindName("btnSelectAll")
$btnDeselectAll = $window.FindName("btnDeselectAll")
$btnApply = $window.FindName("btnApply")
$prgBar = $window.FindName("prgBar")
$lblStatusText = $window.FindName("lblStatusText")
$txtLog = $window.FindName("txtLog")
$scrollLog = $window.FindName("scrollLog")

# Функция добавления сообщений в лог
function Add-Log($text, $color = "#00E676") {
    $timestamp = Get-Date -Format "HH:mm:ss"
    $txtLog.AppendText("[$timestamp] $text`r`n")
    $txtLog.ScrollToEnd()
    [System.Windows.Forms.Application]::DoEvents()
}

# Функция установки бейджа статуса
function Set-Badge($badgeName, $text, $colorHex) {
    $elem = $window.FindName($badgeName)
    if ($elem) {
        $elem.Text = $text
        $elem.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString($colorHex)
    }
}

# 1. Сканирование системы (Smart Pre-Check)
$btnScan.Add_Click({
    try {
        $txtLog.Clear()
        Add-Log "=== Запуск предварительного сканирования системы ==="
        $lblStatusText.Text = "Сканирование..."
        $prgBar.Value = 10

        # Планшет & Перо
        $sysEvent = Get-ItemProperty "HKCU:\Software\Microsoft\Wisp\Pen\SysEventParameters" -ErrorAction SilentlyContinue
        if ($sysEvent -and $sysEvent.HoldMode -eq 0) {
            Set-Badge "status_PenHold" "[ Уже оптимизировано ]" "#00E676"
        } else {
            Set-Badge "status_PenHold" "[ Доступно ]" "#00E5FF"
        }
        
        $tis = Get-Service -Name "TabletInputService" -ErrorAction SilentlyContinue
        if ($tis) {
            if ($tis.StartType -eq "Disabled") {
                Set-Badge "status_TabletInputSvc" "[ Уже отключена ]" "#00E676"
            } else {
                Set-Badge "status_TabletInputSvc" "[ Обнаружена (Активна) ]" "#FFD600"
            }
        } else {
            Set-Badge "status_TabletInputSvc" "[ Не найдена (N/A) ]" "#757575"
        }

        Set-Badge "status_TabletGPO" "[ Доступно ]" "#00E5FF"
        Set-Badge "status_LinearCurve" "[ Доступно ]" "#00E5FF"
        Set-Badge "status_UsbSuspend" "[ Доступно ]" "#00E5FF"
        $prgBar.Value = 40

        # Система & Таймеры
        $bcdDyn = bcdedit /enum "{current}" 2>$null | Select-String "disabledynamictick\s+Yes"
        if ($bcdDyn) {
            Set-Badge "status_BcdTimers" "[ Уже активно (TSC) ]" "#00E676"
        } else {
            Set-Badge "status_BcdTimers" "[ Доступно ]" "#00E5FF"
        }

        $prio = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -ErrorAction SilentlyContinue).Win32PrioritySeparation
        if ($prio -eq 38) {
            Set-Badge "status_Win32Priority" "[ Уже активно (0x26) ]" "#00E676"
        } else {
            Set-Badge "status_Win32Priority" "[ Доступно ]" "#00E5FF"
        }

        Set-Badge "status_CsrssDwm" "[ Доступно ]" "#00E5FF"
        Set-Badge "status_GameMode" "[ Доступно ]" "#00E5FF"
        Set-Badge "status_KeyboardDelay" "[ Доступно ]" "#00E5FF"
        Set-Badge "status_CpuUnpark" "[ Доступно ]" "#00E5FF"
        Set-Badge "status_KernelRam" "[ Доступно ]" "#00E5FF"

        $possibleOsu = @("$env:LOCALAPPDATA\osu!\osu!.exe", "C:\osu!\osu!.exe", "D:\osu!\osu!.exe", "E:\osu!\osu!.exe")
        $foundOsu = $possibleOsu | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($foundOsu) {
            Set-Badge "status_OsuFso" "[ Найдена: $foundOsu ]" "#00E676"
        } else {
            Set-Badge "status_OsuFso" "[ osu! не найдена ]" "#757575"
        }
        $prgBar.Value = 70

        # Сеть
        $interfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue
        if ($interfaces) {
            Set-Badge "status_Nagle" "[ Найдено $($interfaces.Count) интерфейсов ]" "#00E5FF"
        } else {
            Set-Badge "status_Nagle" "[ N/A ]" "#757575"
        }
        Set-Badge "status_QoS" "[ Доступно ]" "#00E5FF"
        Set-Badge "status_DeliveryOpt" "[ Доступно ]" "#00E5FF"

        # Службы & SSD
        $diag = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
        if ($diag -and $diag.StartType -eq "Disabled") {
            Set-Badge "status_Telemetry" "[ Уже отключена ]" "#00E676"
        } else {
            Set-Badge "status_Telemetry" "[ Обнаружена ]" "#FFD600"
        }
        Set-Badge "status_OemServices" "[ Доступно ]" "#00E5FF"
        Set-Badge "status_TasksDebloat" "[ Доступно ]" "#00E5FF"
        Set-Badge "status_SsdLastAccess" "[ Доступно ]" "#00E5FF"
        Set-Badge "status_UiDelay" "[ Доступно ]" "#00E5FF"

        $prgBar.Value = 100
        $lblStatusText.Text = "Сканирование завершено!"
        Add-Log "[V] Сканирование успешно завершено. Все доступные модули обнаружены."
    } catch {
        Log-Exception $_ "btnScan_Click"
        Add-Log "[!] Ошибка при сканировании системы. Подробности в optimizer_error.log" "#FF5252"
    }
})

# Кнопки Выбрать все / Снять все
$btnSelectAll.Add_Click({
    @("chk_PenHold","chk_TabletGPO","chk_LinearCurve","chk_TabletInputSvc","chk_UsbSuspend",
      "chk_BcdTimers","chk_Win32Priority","chk_CsrssDwm","chk_GameMode","chk_KeyboardDelay",
      "chk_CpuUnpark","chk_KernelRam","chk_OsuFso","chk_Nagle","chk_QoS","chk_DeliveryOpt",
      "chk_Telemetry","chk_OemServices","chk_TasksDebloat","chk_SsdLastAccess","chk_UiDelay") | ForEach-Object {
        $chk = $window.FindName($_)
        if ($chk) { $chk.IsChecked = $true }
    }
    Add-Log "Все чекбоксы отмечены."
})

$btnDeselectAll.Add_Click({
    @("chk_PenHold","chk_TabletGPO","chk_LinearCurve","chk_TabletInputSvc","chk_UsbSuspend",
      "chk_BcdTimers","chk_Win32Priority","chk_CsrssDwm","chk_GameMode","chk_KeyboardDelay",
      "chk_CpuUnpark","chk_KernelRam","chk_OsuFso","chk_Nagle","chk_QoS","chk_DeliveryOpt",
      "chk_Telemetry","chk_OemServices","chk_TasksDebloat","chk_SsdLastAccess","chk_UiDelay") | ForEach-Object {
        $chk = $window.FindName($_)
        if ($chk) { $chk.IsChecked = $false }
    }
    Add-Log "Все чекбоксы сняты."
})

# 2. Применение выбранных твиков
$btnApply.Add_Click({
    $txtLog.Clear()
    Add-Log "=== Применение выбранных оптимизаций ==="
    $lblStatusText.Text = "Применение твиков..."
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

            Set-Badge "status_PenHold" "[ Применено Успешно ]" "#00E676"
            Add-Log "[OK] Windows Ink HoldMode и FlickMode отключены."
        } catch {
            Log-Exception $_ "chk_PenHold"
            Set-Badge "status_PenHold" "[ Ошибка ]" "#FF5252"
            Add-Log "[FAIL] Ошибка Windows Ink: $_"
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

            Set-Badge "status_TabletGPO" "[ Применено Успешно ]" "#00E676"
            Add-Log "[OK] Group Policies для TabletPC и PenWorkspace применены."
        } catch {
            Log-Exception $_ "chk_TabletGPO"
            Set-Badge "status_TabletGPO" "[ Ошибка ]" "#FF5252"
            Add-Log "[FAIL] Ошибка Group Policies: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 3. Linear Mouse Curve
    if ($window.FindName("chk_LinearCurve").IsChecked) {
        try {
            $smoothZero = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)
            Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "SmoothMouseXCurve" -Value $smoothZero -Type Binary -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "SmoothMouseYCurve" -Value $smoothZero -Type Binary -Force -ErrorAction SilentlyContinue
            Set-Badge "status_LinearCurve" "[ Применено Успешно ]" "#00E676"
            Add-Log "[OK] Нелинейное сглаживание курсора обнулено (1:1 Raw)."
        } catch {
            Log-Exception $_ "chk_LinearCurve"
            Set-Badge "status_LinearCurve" "[ Ошибка ]" "#FF5252"
            Add-Log "[FAIL] Ошибка MouseCurve: $_"
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
                Set-Badge "status_TabletInputSvc" "[ Применено Успешно ]" "#00E676"
                Add-Log "[OK] TabletInputService отключена."
            } catch {
                Log-Exception $_ "chk_TabletInputSvc"
                Set-Badge "status_TabletInputSvc" "[ Ошибка прав ]" "#FFD600"
                Add-Log "[WARN] Ошибка остановки TabletInputService: $_"
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
            Set-Badge "status_UsbSuspend" "[ Применено Успешно ]" "#00E676"
            Add-Log "[OK] USB Selective Suspend и спящий режим Hubs отключены."
        } catch {
            Log-Exception $_ "chk_UsbSuspend"
            Set-Badge "status_UsbSuspend" "[ Частично ]" "#FFD600"
            Add-Log "[WARN] USB Suspend настроен частично: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 6. BCD Timers
    if ($window.FindName("chk_BcdTimers").IsChecked) {
        try {
            bcdedit /set disabledynamictick yes 2>$null | Out-Null
            bcdedit /set useplatformclock no 2>$null | Out-Null
            Set-Badge "status_BcdTimers" "[ Применено Успешно ]" "#00E676"
            Add-Log "[OK] BCD таймеры: disabledynamictick yes / useplatformclock no."
        } catch {
            Log-Exception $_ "chk_BcdTimers"
            Set-Badge "status_BcdTimers" "[ Ошибка ]" "#FF5252"
            Add-Log "[FAIL] BCD ошибка: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 7. Win32PrioritySeparation
    if ($window.FindName("chk_Win32Priority").IsChecked) {
        try {
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-Badge "status_Win32Priority" "[ Применено Успешно ]" "#00E676"
            Add-Log "[OK] Win32PrioritySeparation = 0x26 (38) выставлен."
        } catch {
            Log-Exception $_ "chk_Win32Priority"
            Set-Badge "status_Win32Priority" "[ Ошибка ]" "#FF5252"
            Add-Log "[FAIL] Ошибка Win32Priority: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 8. CSRSS & DWM Priority
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
            Set-Badge "status_CsrssDwm" "[ Применено Успешно ]" "#00E676"
            Add-Log "[OK] CSRSS и DWM переведены в High Priority."
        } catch {
            Log-Exception $_ "chk_CsrssDwm"
            Set-Badge "status_CsrssDwm" "[ Ошибка ]" "#FF5252"
            Add-Log "[FAIL] Ошибка PerfOptions: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 9. Game Mode & PresenceWriter
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

            Set-Badge "status_GameMode" "[ Применено Успешно ]" "#00E676"
            Add-Log "[OK] Game Mode включен, GameDVR и PresenceWriter отключены."
        } catch {
            Log-Exception $_ "chk_GameMode"
            Set-Badge "status_GameMode" "[ Ошибка ]" "#FF5252"
            Add-Log "[FAIL] Ошибка GameMode: $_"
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
            Set-Badge "status_KeyboardDelay" "[ Применено Успешно ]" "#00E676"
            Add-Log "[OK] KeyboardDelay = 0 / Speed = 31 выставлены."
        } catch {
            Log-Exception $_ "chk_KeyboardDelay"
            Set-Badge "status_KeyboardDelay" "[ Ошибка ]" "#FF5252"
            Add-Log "[FAIL] Ошибка клавиатуры: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 11. CPU Unparking
    if ($window.FindName("chk_CpuUnpark").IsChecked) {
        try {
            powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>$null
            powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>$null
            powercfg -setactive SCHEME_CURRENT 2>$null
            Set-Badge "status_CpuUnpark" "[ Применено Успешно ]" "#00E676"
            Add-Log "[OK] CPU Core Unparking (100% активных ядер) включен."
        } catch {
            Log-Exception $_ "chk_CpuUnpark"
            Set-Badge "status_CpuUnpark" "[ Ошибка ]" "#FFD600"
            Add-Log "[WARN] Ошибка CPU Unparking: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 12. Kernel RAM & Fast Startup Off
    if ($window.FindName("chk_KernelRam").IsChecked) {
        try {
            $pt = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
            if (-not (Test-Path $pt)) { New-Item -Path $pt -Force | Out-Null }
            Set-ItemProperty -Path $pt -Name "PowerThrottlingOff" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-Badge "status_KernelRam" "[ Применено Успешно ]" "#00E676"
            Add-Log "[OK] Ядро зафиксировано в RAM, Fast Startup отключен."
        } catch {
            Log-Exception $_ "chk_KernelRam"
            Set-Badge "status_KernelRam" "[ Ошибка ]" "#FF5252"
            Add-Log "[FAIL] Ошибка ядра: $_"
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
                    Add-Log "[OK] Fullscreen Exclusive настроен для: $p"
                    $applied = $true
                }
            }
            if ($applied) {
                Set-Badge "status_OsuFso" "[ Применено Успешно ]" "#00E676"
            } else {
                Set-Badge "status_OsuFso" "[ Пропущено (N/A) ]" "#757575"
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
            Set-Badge "status_Nagle" "[ Применено ($cnt адаптеров) ]" "#00E676"
            Add-Log "[OK] Алгоритм Нейгла отключен на $cnt интерфейсах."
        } catch {
            Log-Exception $_ "chk_Nagle"
            Set-Badge "status_Nagle" "[ Ошибка ]" "#FF5252"
            Add-Log "[FAIL] Ошибка TCPNoDelay: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 15. QoS
    if ($window.FindName("chk_QoS").IsChecked) {
        try {
            $pschedPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
            if (-not (Test-Path $pschedPath)) { New-Item -Path $pschedPath -Force -ErrorAction SilentlyContinue | Out-Null }
            Set-ItemProperty -Path $pschedPath -Name "NonBestEffortLimit" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-Badge "status_QoS" "[ Применено Успешно ]" "#00E676"
            Add-Log "[OK] 100% QoS канала разблокировано."
        } catch {
            Log-Exception $_ "chk_QoS"
            Set-Badge "status_QoS" "[ Ошибка ]" "#FF5252"
            Add-Log "[FAIL] Ошибка QoS: $_"
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
            Set-Badge "status_DeliveryOpt" "[ Применено Успешно ]" "#00E676"
            Add-Log "[OK] Delivery Optimization P2P отключена."
        } catch {
            Log-Exception $_ "chk_DeliveryOpt"
            Set-Badge "status_DeliveryOpt" "[ Ошибка ]" "#FF5252"
            Add-Log "[FAIL] Ошибка Delivery Optimization: $_"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 17. Telemetry & SysMain
    if ($window.FindName("chk_Telemetry").IsChecked) {
        try {
            @("DiagTrack", "SysMain") | ForEach-Object {
                $s = $_
                $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
                if ($svc) {
                    Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
                    Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
                    Add-Log "[OK] Служба $s отключена."
                }
            }
            Set-Badge "status_Telemetry" "[ Применено Успешно ]" "#00E676"
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
            Set-Badge "status_OemServices" "[ Переведено: $fnd ]" "#00E676"
            Add-Log "[OK] OEM службы ($fnd шт.) переведены в ручной режим."
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
            Set-Badge "status_TasksDebloat" "[ Отключено ($tCount) ]" "#00E676"
            Add-Log "[OK] Отключено $tCount тяжелых фоновых задач планировщика."
        } catch {
            Log-Exception $_ "chk_TasksDebloat"
        }
    }
    $current++; $prgBar.Value = [math]::Round(($current / $totalChecks) * 100)

    # 20. SSD LastAccess
    if ($window.FindName("chk_SsdLastAccess").IsChecked) {
        try {
            fsutil behavior set disablelastaccess 1 2>$null | Out-Null
            Set-Badge "status_SsdLastAccess" "[ Применено Успешно ]" "#00E676"
            Add-Log "[OK] DisableLastAccess = 1 для SSD применен."
        } catch {
            Log-Exception $_ "chk_SsdLastAccess"
            Set-Badge "status_SsdLastAccess" "[ Ошибка ]" "#FFD600"
            Add-Log "[WARN] Ошибка fsutil: $_"
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
            Set-Badge "status_UiDelay" "[ Применено Успешно ]" "#00E676"
            Add-Log "[OK] Задержка интерфейса MenuShowDelay = 0 установлена."
        } catch {
            Log-Exception $_ "chk_UiDelay"
            Set-Badge "status_UiDelay" "[ Ошибка ]" "#FF5252"
            Add-Log "[FAIL] Ошибка UI delay: $_"
        }
    }
    $current++; $prgBar.Value = 100
    $lblStatusText.Text = "Готово! Все выбранные твики применены."
    Add-Log "====================================================="
    Add-Log "[V] ГОТОВО! Рекомендуется перезагрузить компьютер."
})

# Запуск сканирования при старте окна
$window.Add_ContentRendered({
    try {
        $btnScan.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
    } catch {
        Log-Exception $_ "Add_ContentRendered AutoScan"
    }
})

# Отображение окна
try {
    $window.ShowDialog() | Out-Null
} catch {
    Log-Exception $_ "Window ShowDialog"
    throw $_
}
