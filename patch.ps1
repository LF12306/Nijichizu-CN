# 错误处理函数
function Show-Error {
    Write-Host "===========================================" -ForegroundColor Red
    Write-Host "错误：文件复制失败！" -ForegroundColor Red
    Write-Host "可能原因：" -ForegroundColor Yellow
    Write-Host "1. 游戏正在运行 → 请完全退出游戏后重试" -ForegroundColor Yellow
    Write-Host "2. 杀毒软件拦截 → 暂时关闭杀毒软件" -ForegroundColor Yellow
    Write-Host "3. 路径权限不足 → 检查文件夹权限" -ForegroundColor Yellow
    Write-Host "4. 找不到游戏or游戏未安装 → 请把补丁放入游戏根目录后再次尝试" -ForegroundColor Yellow
    Write-Host "===========================================" -ForegroundColor Red
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 5
}

# 主程序
try {
    # 设置参数
    $appId = "3213690"
    $sourceRoot = Join-Path $PSScriptRoot "虹之咲字幕组汉化补丁"
    $global:errorOccurred = $false

    # 检测本地游戏文件
    if (Test-Path (Join-Path $PSScriptRoot "nijichizu.exe")) {
        $gamePath = $PSScriptRoot
        $found = $true
        Write-Host "[INFO] 检测到本地游戏文件，将应用补丁到当前目录：$gamePath" -ForegroundColor Cyan
    }
    else {
        # 未检测到本地文件时搜索Steam路径
        $steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam").SteamPath
        $libraryVdfPath = Join-Path "$steamPath\steamapps" "libraryfolders.vdf"

        $libraryFolders = @("$steamPath\steamapps")

        if (Test-Path $libraryVdfPath) {
            $lines = Get-Content $libraryVdfPath
            foreach ($line in $lines) {
                if ($line -match '"path"\s+"([^"]+)"') {
                    $libPath = $matches[1]
                    $libraryFolders += "$libPath\steamapps"
                }
            }
        }

        $found = $false
        foreach ($folder in $libraryFolders) {
            $manifestPath = Join-Path $folder "appmanifest_$appId.acf"
            if (Test-Path $manifestPath) {
                $content = Get-Content $manifestPath -Raw
                if ($content -match '"installdir"\s+"([^"]+)"') {
                    $installDir = $matches[1]
                    $gamePath = Join-Path $folder "common\$installDir"
                    Write-Output "检测到Steam游戏安装路径：$gamePath"
                    $found = $true
                    break
                }
            }
        }
    }

    # 如果没有找到游戏安装目录，显示错误并退出
    if (-not $found) {
        Write-Host "[ERROR] 未能找到游戏安装目录，请确认游戏已安装" -ForegroundColor Red
        Show-Error
    }
    
    # 文件复制逻辑
    if (-not (Test-Path $sourceRoot)) {
        Write-Host "[ERROR] 找不到汉化补丁文件夹" -ForegroundColor Red
        Write-Host "请把补丁放入游戏根目录后再次尝试" -ForegroundColor Red
        Write-Host "按任意键继续..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }

    Get-ChildItem -Path $sourceRoot -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($sourceRoot.Length + 1)
        $targetPath = Join-Path $gamePath $relativePath
        $targetDir = Split-Path $targetPath -Parent

        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        try {
            Copy-Item -Path $_.FullName -Destination $targetPath -Force
            Write-Output "已更新：$relativePath"
        }
        catch {
            $global:errorOccurred = $true
            Write-Host "[ERROR] 更新失败：$relativePath → $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # 最终错误检查
    if ($global:errorOccurred) { Show-Error }
}
catch {
    Show-Error
}

# 成功提示
Write-Host "`n" -NoNewline
Write-Host "===========================================" -ForegroundColor Green
Write-Host " 虹组汉化补丁安装成功！按 Enter 键退出！" -ForegroundColor Green
Write-Host "           璃奈板「TOKIMEKI！！！」         " -ForegroundColor Magenta
Write-Host "===========================================" -ForegroundColor Green

# 启动游戏
$exePath = Join-Path $gamePath "nijichizu.exe"
if (Test-Path $exePath) {
    Read-Host "按 Enter 键退出补丁并清除缓存"
}
else {
    Write-Host "[WARNING] 未找到游戏主程序" -ForegroundColor Yellow
}

exit 0
