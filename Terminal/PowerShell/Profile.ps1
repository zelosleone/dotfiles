# Import modules
Import-Module PSReadLine
Import-Module Terminal-Icons
if (Get-Module -ListAvailable -Name PSFzf) { Import-Module PSFzf }

# PSReadLine configuration
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Custom prompt with git
function prompt {
    $location = $ExecutionContext.SessionState.Path.CurrentLocation
    $gitBranch = git branch --show-current 2>$null
    $promptChar = if ($?) { "❯" } else { "×" }
    
    $gitInfo = if ($gitBranch) { " [$gitBranch]" } else { "" }
    "$([char]0x1b)[36m$location$([char]0x1b)[33m$gitInfo$([char]0x1b)[0m`n$promptChar "
}

# Development environment aliases and functions
${function:dev} = { Set-Location "~/Documents/GitHub" }

# Docker shortcuts
${function:dps} = { docker ps }
${function:dex} = { docker exec -it $args[0] bash }
${function:dc} = { docker-compose $args }

# Git shortcuts
${function:gs} = { git status }
${function:gp} = { git pull }
${function:gpush} = { git push }
${function:gc} = { git commit -m $args[0] }
${function:gch} = { git checkout $args[0] }

# Kubernetes shortcuts
${function:k} = { kubectl $args }
${function:kns} = { kubectl config set-context --current --namespace=$args[0] }
${function:kctx} = { kubectl config use-context $args[0] }

function Start-JupyterLab {
    jupyter lab
}

function Start-JupyterNotebook {
    param(
        [string]$Port = "8888",
        [switch]$NoToken
    )
    if ($NoToken) {
        jupyter notebook --port=$Port --no-browser --ServerApp.token='' --NotebookApp.auth_token=''
    } else {
        jupyter notebook --port=$Port --no-browser
    }
}

function Start-TensorBoard {
    param(
        [string]$LogDir = "logs",
        [string]$Port = "6006"
    )
    tensorboard --logdir=$LogDir --port=$Port
}

Set-Alias -Name jlab -Value Start-JupyterLab
Set-Alias -Name nb -Value Start-JupyterNotebook
Set-Alias -Name tb -Value Start-TensorBoard

# Data paths
$env:DATA_PATH = Join-Path $HOME "Documents/Data"
$env:MODELS_PATH = Join-Path $HOME "Documents/Models"

function Install-DataSciencePackages {
    conda install -y numpy pandas matplotlib seaborn scikit-learn jupyter jupyterlab tensorflow pytorch
}

function Show-Plot {
    param($Data, $Kind = "line")
    $fixedPath = $Data.Replace('\', '/')
    python -c @"
import pandas as pd
import matplotlib.pyplot as plt

# Read the data
df = pd.read_csv(r'$fixedPath' if '.csv' in r'$fixedPath' else r'$fixedPath.csv')

# Create the plot
plt.figure(figsize=(12, 6))

# Plot all numeric columns
numeric_cols = df.select_dtypes(include=['float64', 'int64']).columns
for col in numeric_cols:
    plt.plot(df.index, df[col], label=col)

plt.grid(True, alpha=0.3)
plt.legend()
plt.title('Data Visualization')
plt.tight_layout()
plt.show()
"@
}

# Trading/Financial helper
function Show-StockChart {
    param(
        [string]$Symbol,
        [string]$Period = "1mo",
        [string]$Interval = "1d"
    )
    
    $tempFile = [System.IO.Path]::GetTempFileName() + ".py"
    
    @"
import yfinance as yf
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

def calculate_rsi(data, periods=14):
    delta = data.diff()
    gain = (delta.where(delta > 0, 0)).rolling(window=periods).mean()
    loss = (-delta.where(delta < 0, 0)).rolling(window=periods).mean()
    rs = gain / loss
    return 100 - (100 / (1 + rs))

symbol = '$Symbol'
ticker = yf.Ticker(symbol)
hist = ticker.history(period='$Period', interval='$Interval')

# Calculate RSI
hist['RSI'] = calculate_rsi(hist['Close'])

# Create figure with subplots
plt.style.use('dark_background')
fig = plt.figure(figsize=(12, 8))
gs = fig.add_gridspec(2, 1, height_ratios=[2, 1], hspace=0.15)

# Price plot
ax1 = fig.add_subplot(gs[0])
ax1.plot(hist.index, hist['Close'], color='cyan', linewidth=1)
ax1.fill_between(hist.index, hist['Close'], alpha=0.2, color='cyan')
ax1.set_title(f'{symbol} Stock Price', color='white', size=14, pad=10)
ax1.grid(True, alpha=0.2)
ax1.set_ylabel('Price (USD)', color='white')
ax1.tick_params(axis='x', labelbottom=False)

# RSI plot
ax2 = fig.add_subplot(gs[1])
ax2.plot(hist.index, hist['RSI'], color='magenta', linewidth=1)
ax2.axhline(y=70, color='red', linestyle='--', alpha=0.5)
ax2.axhline(y=30, color='green', linestyle='--', alpha=0.5)
ax2.fill_between(hist.index, hist['RSI'], 70, where=(hist['RSI'] >= 70), color='red', alpha=0.3)
ax2.fill_between(hist.index, hist['RSI'], 30, where=(hist['RSI'] <= 30), color='green', alpha=0.3)
ax2.set_ylabel('RSI', color='white')
ax2.set_ylim(0, 100)
ax2.grid(True, alpha=0.2)

# Last RSI value
last_rsi = hist['RSI'].iloc[-1]
rsi_color = 'red' if last_rsi > 70 else 'green' if last_rsi < 30 else 'white'
ax2.text(0.02, 0.95, f'RSI: {last_rsi:.2f}', transform=ax2.transAxes, color=rsi_color)

# Adjust layout and display
plt.subplots_adjust(left=0.1, right=0.9, top=0.9, bottom=0.1)
plt.show()
"@ | Set-Content $tempFile -Encoding UTF8

    try {
        python $tempFile
    }
    finally {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
}

function stonks {
    param(
        [Parameter(Mandatory=$true)][string]$Symbol,
        [switch]$Chart,
        [string]$Period = "1mo",
        [string]$Interval = "1d"
    )
    
    $querySymbol = if ($Symbol -match "USDT$") {
        ($Symbol -replace "USDT$") + "-USD"
    } else {
        $Symbol
    }

        try {
            $response = Invoke-RestMethod "https://query1.finance.yahoo.com/v8/finance/chart/$querySymbol"
            
            if ($response.chart.result) {
                $data = $response.chart.result[0]
                $meta = $data.meta
                
                $currentPrice = [math]::Round($meta.regularMarketPrice, 2)
                $previousClose = [math]::Round($meta.previousClose, 2)
                $change = [math]::Round($currentPrice - $previousClose, 2)
                $changePercent = [math]::Round(($change / $previousClose) * 100, 2)
                
                $changeColor = if ($change -ge 0) { "[92m" } else { "[91m" }
                
                Write-Host "`nSymbol: $($meta.symbol)" -ForegroundColor Cyan
                Write-Host ("Price: `${0:N2}" -f $currentPrice)
                Write-Host ("Change: $([char]0x1b)$changeColor`${0:N2} ({1:N2}%)$([char]0x1b)[0m" -f $change, $changePercent)
                Write-Host ("Previous Close: `${0:N2}`n" -f $previousClose)
                
                if ($Chart) {
                    Show-StockChart -Symbol $querySymbol -Period $Period -Interval $Interval
                }
            }
        }
        catch {
            Write-Error "Failed to fetch data for symbol: $Symbol"
        }
}

function which {
    param($Command)
    Get-Command $Command | Select-Object -ExpandProperty Source
}

# Environment setup
$env:PYTHONIOENCODING = "utf-8"
$env:VIRTUAL_ENV_DISABLE_PROMPT = 1

# Set default editors
$env:EDITOR = "code"
$env:VISUAL = "code"

# Enable kubectl autocompletion
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    kubectl completion powershell | Out-String | Invoke-Expression
}

# Aliases
Set-Alias -Name touch -Value New-Item
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name g -Value git
Set-Alias -Name py -Value python