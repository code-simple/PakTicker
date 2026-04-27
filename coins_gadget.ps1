# Top-right desktop ticker for crypto prices and Binance P2P USDT/PKR.
# Double-click coins_gadget.vbs to launch. Right-click to close.

Add-Type -AssemblyName PresentationFramework
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class WinAPI {
    [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
    [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);
    public const int GWL_EXSTYLE      = -20;
    public const int WS_EX_TOOLWINDOW = 0x00000080;
    public const int WS_EX_APPWINDOW  = 0x00040000;
}
'@

# ── Config ────────────────────────────────────────────────────────────────────
$configPath     = Join-Path $PSScriptRoot 'coins_config.json'
$defaultSymbols = @('BTCUSDT', 'CFXUSDT', 'PAXGUSDT')

function Load-Config {
    if (Test-Path $configPath) {
        try { return @(Get-Content $configPath -Raw | ConvertFrom-Json) } catch {}
    }
    return $defaultSymbols
}
function Save-Config {
    $script:coinSymbols | ConvertTo-Json | Set-Content $configPath
}
function Get-CoinLabel([string]$sym) {
    if ($sym -eq 'PAXGUSDT') { return 'GOLD' }
    foreach ($q in @('USDT','BUSD','USDC','BTC','ETH','BNB')) {
        if ($sym.ToUpper().EndsWith($q)) { return $sym.Substring(0, $sym.Length - $q.Length).ToUpper() }
    }
    return $sym.Substring(0, [Math]::Min(6, $sym.Length)).ToUpper()
}
function Update-PriceUrl {
    $syms = ($script:coinSymbols | ForEach-Object { '"' + $_ + '"' }) -join ','
    $script:url = 'https://api.binance.com/api/v3/ticker/24hr?symbols=[' + $syms + ']'
}

$script:coinSymbols = Load-Config
$script:labels      = @{}
$pollSeconds        = 5
Update-PriceUrl

# ── PKR rows XAML ─────────────────────────────────────────────────────────────
$pkrRows = @(
    @{ Name='BHi'; Color='#B0FFB0'; Prefix='B-Hi'; TopMargin=2; BotMargin=0 },
    @{ Name='BLo'; Color='#B0FFB0'; Prefix='B-Lo'; TopMargin=0; BotMargin=0 },
    @{ Name='SHi'; Color='#FFB0B0'; Prefix='S-Hi'; TopMargin=0; BotMargin=0 },
    @{ Name='SLo'; Color='#FFB0B0'; Prefix='S-Lo'; TopMargin=0; BotMargin=2 }
)
$pkrRowXaml = ($pkrRows | ForEach-Object {
    $n = $_.Name; $col = $_.Color; $pre = $_.Prefix; $tm = $_.TopMargin; $bm = $_.BotMargin
@"
    <Grid Margin="0,$tm,0,$bm">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="80"/>
        <ColumnDefinition Width="95"/>
        <ColumnDefinition Width="100"/>
      </Grid.ColumnDefinitions>
      <TextBlock x:Name="PKR_${n}Name" Foreground="#99AABB" FontFamily="Consolas" FontSize="10" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
      <TextBlock x:Name="PKR_$n"       Grid.Column="1" Foreground="$col" TextAlignment="Right" FontFamily="Consolas" FontSize="12" FontWeight="Bold" Text="$pre ..." VerticalAlignment="Center"/>
      <TextBlock x:Name="PKR_${n}Lim"  Grid.Column="2" Foreground="#888888" TextAlignment="Right" FontFamily="Consolas" FontSize="10" Text="" VerticalAlignment="Center" Margin="6,0,0,0"/>
    </Grid>
"@
}) -join "`n"

# ── XAML ──────────────────────────────────────────────────────────────────────
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStyle="None" AllowsTransparency="True" Background="#80111418"
        Topmost="False" ShowInTaskbar="False" SizeToContent="WidthAndHeight"
        ResizeMode="NoResize">
  <Grid>
    <Border BorderBrush="#33FFFFFF" BorderThickness="1" CornerRadius="6" Padding="10,8,10,8">
      <StackPanel>
        <StackPanel x:Name="CoinsPanel"/>
        <Button x:Name="BtnAddCoin" Content="+ add coin"
                Background="Transparent" Foreground="#445566"
                FontFamily="Consolas" FontSize="10" BorderThickness="0"
                Padding="0,3" HorizontalAlignment="Left" Cursor="Hand" Margin="0,2,0,4"/>
        <TextBlock Text="P2P Binance" HorizontalAlignment="Center" Foreground="#99AABB"
                   FontFamily="Consolas" FontSize="11" FontWeight="Bold" Margin="0,2,0,2"/>
$pkrRowXaml
      </StackPanel>
    </Border>

    <Border x:Name="Overlay" CornerRadius="6" Background="#DD0A0C10" Visibility="Collapsed">
      <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" Margin="24,16">
        <TextBlock Text="Close gadget?" HorizontalAlignment="Center" Foreground="#CCCCCC"
                   FontFamily="Consolas" FontSize="12" Margin="0,0,0,14"/>
        <Button x:Name="BtnClose" Content="Close" Width="110"
                Background="#99441111" Foreground="#FF8888"
                FontFamily="Consolas" FontSize="12" FontWeight="Bold"
                BorderBrush="#66FF4444" BorderThickness="1"
                Padding="0,7" Margin="0,0,0,8" Cursor="Hand"/>
        <Button x:Name="BtnCancel" Content="Cancel" Width="110"
                Background="#44333333" Foreground="#888888"
                FontFamily="Consolas" FontSize="12"
                BorderBrush="#33FFFFFF" BorderThickness="1"
                Padding="0,7" Cursor="Hand"/>
      </StackPanel>
    </Border>

    <Border x:Name="OverlayAdd" CornerRadius="6" Background="#DD0A0C10" Visibility="Collapsed">
      <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" Margin="24,16">
        <TextBlock Text="Add Coin" HorizontalAlignment="Center" Foreground="#CCCCCC"
                   FontFamily="Consolas" FontSize="12" FontWeight="Bold" Margin="0,0,0,4"/>
        <TextBlock Text="e.g. ETHUSDT, SOLUSDT" HorizontalAlignment="Center" Foreground="#445566"
                   FontFamily="Consolas" FontSize="10" Margin="0,0,0,10"/>
        <Grid Margin="0,0,0,6">
          <TextBox x:Name="TxtSymbol" Width="150"
                   Background="#1A2030" Foreground="White" CaretBrush="White"
                   FontFamily="Consolas" FontSize="13"
                   BorderBrush="#44FFFFFF" BorderThickness="1"
                   Padding="6,5" HorizontalContentAlignment="Center"/>
          <TextBlock x:Name="TxtPlaceholder" Text="SOLUSDT  /  BNBUSDT"
                     IsHitTestVisible="False" Foreground="#445566"
                     FontFamily="Consolas" FontSize="11"
                     HorizontalAlignment="Center" VerticalAlignment="Center"/>
        </Grid>
        <TextBlock x:Name="TxtAddError" HorizontalAlignment="Center" Foreground="#FF7070"
                   FontFamily="Consolas" FontSize="10" Margin="0,0,0,8" Text=""/>
        <Button x:Name="BtnAddConfirm" Content="Add" Width="150"
                Background="#1A3322" Foreground="#88FF88"
                FontFamily="Consolas" FontSize="12" FontWeight="Bold"
                BorderBrush="#4466FF66" BorderThickness="1"
                Padding="0,7" Margin="0,0,0,8" Cursor="Hand"/>
        <Button x:Name="BtnAddCancel" Content="Cancel" Width="150"
                Background="#44333333" Foreground="#888888"
                FontFamily="Consolas" FontSize="12"
                BorderBrush="#33FFFFFF" BorderThickness="1"
                Padding="0,7" Cursor="Hand"/>
      </StackPanel>
    </Border>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# ── Brushes ───────────────────────────────────────────────────────────────────
$green = [Windows.Media.Brushes]::LimeGreen
$red   = [Windows.Media.Brushes]::Tomato
$white = [Windows.Media.Brushes]::White
$grey  = [Windows.Media.Brushes]::Gray

$coinsPanel = $window.FindName('CoinsPanel')

# ── Dynamic coin rows ─────────────────────────────────────────────────────────
function Add-CoinRow([string]$sym) {
    $label     = Get-CoinLabel $sym
    $removable = ($sym -ne 'PAXGUSDT')
    $mkBrush   = { param($hex) New-Object Windows.Media.SolidColorBrush ([Windows.Media.ColorConverter]::ConvertFromString($hex)) }

    $grid = New-Object Windows.Controls.Grid
    $grid.Margin = [Windows.Thickness]::new(0, 2, 0, 2)
    foreach ($w in @(55, 115, 80, 18)) {
        $cd = New-Object Windows.Controls.ColumnDefinition
        $cd.Width = [Windows.GridLength]::new($w)
        $grid.ColumnDefinitions.Add($cd)
    }

    $lblTb = New-Object Windows.Controls.TextBlock
    $lblTb.Text              = $label
    $lblTb.Foreground        = (& $mkBrush '#99AABB')
    $lblTb.FontFamily        = [Windows.Media.FontFamily]::new('Consolas')
    $lblTb.FontSize          = 12
    $lblTb.FontWeight        = [Windows.FontWeights]::Bold
    $lblTb.VerticalAlignment = 'Center'

    $priceTb = New-Object Windows.Controls.TextBlock
    $priceTb.Text              = '...'
    $priceTb.Foreground        = $white
    $priceTb.TextAlignment     = 'Right'
    $priceTb.FontFamily        = [Windows.Media.FontFamily]::new('Consolas')
    $priceTb.FontSize          = 14
    $priceTb.FontWeight        = [Windows.FontWeights]::Bold
    $priceTb.VerticalAlignment = 'Center'
    [Windows.Controls.Grid]::SetColumn($priceTb, 1)

    $chgTb = New-Object Windows.Controls.TextBlock
    $chgTb.TextAlignment     = 'Right'
    $chgTb.FontFamily        = [Windows.Media.FontFamily]::new('Consolas')
    $chgTb.FontSize          = 10
    $chgTb.VerticalAlignment = 'Center'
    $chgTb.Margin            = [Windows.Thickness]::new(6, 0, 0, 0)
    [Windows.Controls.Grid]::SetColumn($chgTb, 2)

    $grid.Children.Add($lblTb)   | Out-Null
    $grid.Children.Add($priceTb) | Out-Null
    $grid.Children.Add($chgTb)   | Out-Null

    if ($removable) {
        $removeBtn = New-Object Windows.Controls.Button
        $removeBtn.Content         = [char]0x00D7
        $removeBtn.Foreground      = (& $mkBrush '#445566')
        $removeBtn.Background      = [Windows.Media.Brushes]::Transparent
        $removeBtn.BorderThickness = [Windows.Thickness]::new(0)
        $removeBtn.FontFamily      = [Windows.Media.FontFamily]::new('Consolas')
        $removeBtn.FontSize        = 12
        $removeBtn.VerticalAlignment   = 'Center'
        $removeBtn.HorizontalAlignment = 'Center'
        $removeBtn.Cursor  = [Windows.Input.Cursors]::Hand
        $removeBtn.Padding = [Windows.Thickness]::new(0)
        [Windows.Controls.Grid]::SetColumn($removeBtn, 3)

        $capturedSym  = $sym
        $capturedGrid = $grid
        $removeBtn.Add_Click({
            $coinsPanel.Children.Remove($capturedGrid)
            $script:coinSymbols = @($script:coinSymbols | Where-Object { $_ -ne $capturedSym })
            $script:labels.Remove($capturedSym)
            Update-PriceUrl
            Save-Config
        }.GetNewClosure())

        $grid.Children.Add($removeBtn) | Out-Null
    }

    $coinsPanel.Children.Add($grid) | Out-Null
    $script:labels[$sym] = @{ Price = $priceTb; Chg = $chgTb }
}

foreach ($sym in $script:coinSymbols) { Add-CoinRow $sym }

# ── PKR cells ─────────────────────────────────────────────────────────────────
$pkrCells = @{}
foreach ($r in $pkrRows) {
    $pkrCells[$r.Name] = @{
        Name   = $window.FindName("PKR_$($r.Name)Name")
        Price  = $window.FindName("PKR_$($r.Name)")
        Lim    = $window.FindName("PKR_$($r.Name)Lim")
        Prefix = $r.Prefix
        Color  = (New-Object Windows.Media.SolidColorBrush ([Windows.Media.ColorConverter]::ConvertFromString($r.Color)))
    }
}

# ── UI element refs ───────────────────────────────────────────────────────────
$txtPlaceholder = $window.FindName('TxtPlaceholder')
$overlay        = $window.FindName('Overlay')
$btnClose      = $window.FindName('BtnClose')
$btnCancel     = $window.FindName('BtnCancel')
$overlayAdd    = $window.FindName('OverlayAdd')
$txtSymbol     = $window.FindName('TxtSymbol')
$txtAddError   = $window.FindName('TxtAddError')
$btnAddConfirm = $window.FindName('BtnAddConfirm')
$btnAddCancel  = $window.FindName('BtnAddCancel')
$btnAddCoin    = $window.FindName('BtnAddCoin')

# ── Event handlers ────────────────────────────────────────────────────────────
$window.Add_MouseRightButtonDown({ $overlay.Visibility = 'Visible' })
$btnClose.Add_Click({ $window.Close() })
$btnCancel.Add_Click({ $overlay.Visibility = 'Collapsed' })

$txtSymbol.Add_TextChanged({
    $txtPlaceholder.Visibility = if ($txtSymbol.Text.Length -gt 0) { 'Collapsed' } else { 'Visible' }
})

$btnAddCoin.Add_Click({
    $txtSymbol.Text        = ''
    $txtAddError.Text      = ''
    $txtPlaceholder.Visibility = 'Visible'
    $overlayAdd.Visibility = 'Visible'
    $txtSymbol.Focus() | Out-Null
})
$btnAddCancel.Add_Click({ $overlayAdd.Visibility = 'Collapsed' })

$btnAddConfirm.Add_Click({
    $sym = $txtSymbol.Text.Trim().ToUpper()
    if ($sym -eq '') { $txtAddError.Text = 'Enter a symbol'; return }
    if ($script:coinSymbols -contains $sym) { $txtAddError.Text = 'Already added'; return }
    $txtAddError.Text = 'Checking...'
    try {
        $test = Invoke-RestMethod -Uri "https://api.binance.com/api/v3/ticker/price?symbol=$sym" -TimeoutSec 5 -Headers @{ 'User-Agent' = 'Mozilla/5.0' }
        if (-not $test.symbol) { throw }
    } catch {
        $txtAddError.Text = 'Symbol not found on Binance'
        return
    }
    $script:coinSymbols += $sym
    Update-PriceUrl
    Save-Config
    Add-CoinRow $sym
    $overlayAdd.Visibility = 'Collapsed'
    Update-Prices
})

$window.Add_KeyDown({
    if ($_.Key -eq 'Return' -and $overlayAdd.Visibility -eq 'Visible') {
        $btnAddConfirm.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
        return
    }
    if ($_.Key -eq 'Escape') {
        if    ($overlayAdd.Visibility -eq 'Visible') { $overlayAdd.Visibility = 'Collapsed' }
        elseif ($overlay.Visibility   -eq 'Visible') { $overlay.Visibility   = 'Collapsed' }
        else  { $window.Close() }
    }
})

# ── Window positioning ────────────────────────────────────────────────────────
$margin = 10
$anchorTopRight = {
    $work = [System.Windows.SystemParameters]::WorkArea
    $targetLeft = $work.Right - $window.ActualWidth - $margin
    $targetTop  = $work.Top + $margin
    if ($window.Left -ne $targetLeft) { $window.Left = $targetLeft }
    if ($window.Top  -ne $targetTop)  { $window.Top  = $targetTop  }
}
$window.Add_SourceInitialized({
    $hwnd  = (New-Object System.Windows.Interop.WindowInteropHelper($window)).Handle
    $style = [WinAPI]::GetWindowLong($hwnd, [WinAPI]::GWL_EXSTYLE)
    $style = ($style -bor [WinAPI]::WS_EX_TOOLWINDOW) -band (-bnot [WinAPI]::WS_EX_APPWINDOW)
    [WinAPI]::SetWindowLong($hwnd, [WinAPI]::GWL_EXSTYLE, $style)
    & $anchorTopRight
})
$window.Add_ContentRendered($anchorTopRight)
$window.Add_SizeChanged($anchorTopRight)
$window.Add_LocationChanged($anchorTopRight)

# ── P2P functions ─────────────────────────────────────────────────────────────
$p2pUrl = 'https://p2p.binance.com/bapi/c2c/v2/friendly/c2c/adv/search'

function Get-P2PAds([string]$tradeType, [int]$transAmount) {
    $params = @{
        asset         = 'USDT'
        fiat          = 'PKR'
        tradeType     = $tradeType
        transAmount   = $transAmount
        page          = 1
        rows          = 20
        payTypes      = @()
        publisherType = 'merchant'
    }
    $resp = Invoke-RestMethod -Uri $p2pUrl -Method Post -Body ($params | ConvertTo-Json) -ContentType 'application/json' -Headers @{ 'User-Agent' = 'Mozilla/5.0' } -TimeoutSec 8
    return @($resp.data | Where-Object { [double]$_.adv.surplusAmount -ge ([double]$_.adv.minSingleTransAmount / [double]$_.adv.price) })
}

function Format-PKRAmt([double]$v) {
    if ($v -ge 1000000) { return ('{0:N1}M' -f ($v / 1000000)) }
    if ($v -ge 1000)    { return ('{0:N0}k' -f ($v / 1000)) }
    return ('{0:N0}' -f $v)
}

function Set-PKRCell($cell, $ad) {
    if ($null -eq $ad) {
        $cell.Name.Text = ''; $cell.Price.Text = "$($cell.Prefix) -"; $cell.Price.Foreground = $red; $cell.Lim.Text = ''
        $cell.Price.ToolTip = $null; $cell.Lim.ToolTip = $null
        return
    }
    $cell.Price.Text       = ('{0} {1:N2}' -f $cell.Prefix, [double]$ad.adv.price)
    $cell.Price.Foreground = $cell.Color
    $cell.Lim.Text         = ('{0}-{1}' -f (Format-PKRAmt ([double]$ad.adv.minSingleTransAmount)), (Format-PKRAmt ([double]$ad.adv.maxSingleTransAmount)))
    $cell.Name.Text        = $ad.advertiser.nickName
    $orders  = $ad.advertiser.monthOrderCount
    $rateRaw = [double]$ad.advertiser.monthFinishRate
    $rate    = if ($rateRaw -le 1) { [math]::Round($rateRaw * 100, 0) } else { [math]::Round($rateRaw, 0) }
    $methods = ($ad.adv.tradeMethods | ForEach-Object { $_.tradeMethodName }) -join ', '
    if ([string]::IsNullOrWhiteSpace($methods)) { $methods = '(no methods listed)' }
    $surplus = [math]::Round([double]$ad.adv.surplusAmount, 0)
    $tip = "$($ad.advertiser.nickName)`n$orders orders | ${rate}% completion | $surplus USDT avail`n$methods"
    $cell.Price.ToolTip = $tip; $cell.Lim.ToolTip = $tip
}

function Update-PKR {
    try {
        $bHi = Get-P2PAds 'BUY'  100000 | Select-Object -First 1
        $bLo = Get-P2PAds 'BUY'  1000   | Select-Object -First 1
        $sHi = Get-P2PAds 'SELL' 100000 | Select-Object -First 1
        $sLo = Get-P2PAds 'SELL' 1000   | Select-Object -First 1
        Set-PKRCell $pkrCells['BHi'] $bHi
        Set-PKRCell $pkrCells['BLo'] $bLo
        Set-PKRCell $pkrCells['SHi'] $sHi
        Set-PKRCell $pkrCells['SLo'] $sLo
    } catch {
        foreach ($k in $pkrCells.Keys) {
            $c = $pkrCells[$k]
            $c.Price.Text = "$($c.Prefix) err"; $c.Price.Foreground = $red; $c.Lim.Text = ''
        }
    }
}

function Update-Prices {
    try {
        $data = Invoke-RestMethod -Uri $script:url -TimeoutSec 4 -Headers @{ 'User-Agent' = 'Mozilla/5.0' }
        foreach ($row in $data) {
            $l = $script:labels[$row.symbol]
            if (-not $l) { continue }
            $price = [double]$row.lastPrice
            $chg   = [double]$row.priceChangePercent
            $l.Price.Text       = ('{0:N2}' -f $price)
            $l.Price.Foreground = $white
            $sign = if ($chg -ge 0) { '+' } else { '' }
            $l.Chg.Text       = ('{0}{1:N2}%' -f $sign, $chg)
            $l.Chg.Foreground = if ($chg -ge 0) { $green } else { $red }
        }
    } catch {
        foreach ($l in $script:labels.Values) {
            $l.Price.Text = 'err'; $l.Price.Foreground = $red; $l.Chg.Text = ''
        }
    }
}

# ── Timers ────────────────────────────────────────────────────────────────────
$priceTimer = New-Object System.Windows.Threading.DispatcherTimer
$priceTimer.Interval = [TimeSpan]::FromSeconds($pollSeconds)
$priceTimer.Add_Tick({ Update-Prices })
$priceTimer.Start()

$p2pTimer = New-Object System.Windows.Threading.DispatcherTimer
$p2pTimer.Interval = [TimeSpan]::FromSeconds(10)
$p2pTimer.Add_Tick({ Update-PKR })
$p2pTimer.Start()

Update-Prices
Update-PKR
$window.ShowDialog() | Out-Null
