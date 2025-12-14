$CWD = $PSScriptRoot
Set-Location -Path $CWD

if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function DownloadZipFile {
    param(
        [string]$URL,
        [string]$OutDir = './',
        [bool]$UseFileNameInOutDir = $true 
    )

    $extendedUrl = [uri]$URL

    $fullFileName = $extendedUrl.Segments[ -1 ]
    $fileName     = $fullFileName.split( "." )[ 0 ]

    Invoke-WebRequest -Uri "$URL" -outfile "$OutDir/$fullFileName"

    $extractDir = $OutDir

    if ( $UseFileNameInOutDir )
    {
        $extractDir = "$OutDir/$fileName"
    }

    Expand-Archive -Path "$OutDir/$fullFileName" -DestinationPath "$extractDir" -Force

    return "$OutDir/$fileName"
}
function GetVPKEdit {
    param(
        [string]$OutDir = './'
    )
    return DownloadZipFile -URL "https://github.com/craftablescience/VPKEdit/releases/latest/download/StrataSource-Windows-Binaries-msvc-Release.zip" -OutDir $OutDir
}
function GetHammerPlusPlus{
    param(
        [string]$OutDir = './'
    )
    return DownloadZipFile -URL "https://github.com/ficool2/HammerPlusPlus-Website/releases/download/8864/hammerplusplus_csgo_build8864.zip" -OutDir $OutDir -UseFileNameInOutDir $false
}

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

$hammerBundlePath =  "./hammer"

$defaultHammerBundleGameinfo = @"
"GameInfo"
{
	game 		"INFRA"
	
	GameData	"INFRA.fgd"

	gamelogo 	1

	SupportsDX8     0
	SupportsXbox360 0

	FileSystem
	{
		SteamAppId	251110
		ToolsAppId	211

		SearchPaths
		{
			game     |gameinfo_path|.
			game	 game
			platform platform
		}
	}
}
"@
$defaultHammerParams = @"
[General]
AutosaveDir=$CWD/hammer_autosave
StartupCheckForUpdates=0

[DialogInstanceConvert]
RelativeFolder=$hammerBundlePath/instances/
"@

New-Item -Path "$hammerBundlePath" -ItemType "Directory" -Force
New-Item -Path "$hammerBundlePath/gameinfo.txt" -ItemType "File" -Value "$defaultHammerBundleGameinfo" -Force

$hammerBundleTempPath = "$hammerBundlePath/temp"
New-Item -Path "$hammerBundleTempPath" -ItemType "Directory" -Force

$csgoPath = Read-Host "ENTER CSGO PATH"
Copy-Item -Path "$csgoPath/bin" -Destination "./" -Force -Recurse

$vpkeditPath = GetVPKEdit -OutDir $hammerBundleTempPath
Invoke-Expression -Command "$vpkeditPath/vpkeditcli `"$csgoPath/platform/platform_pak01_dir.vpk`" -o `"$hammerBundleTempPath`" -e"

$csgoResourceFolder = "$hammerBundleTempPath/platform_pak01/resource"
New-Item -Path $csgoResourceFolder -ItemType "Directory" -Force
Copy-Item -Path "$csgoPath/csgo/resource/*.vfont" -Destination $csgoResourceFolder -Force -Recurse

Invoke-Expression -Command "$vpkeditPath/vpkeditcli `"$hammerBundleTempPath/platform_pak01`" -o `"$hammerBundlePath/pak01_dir`""

$hammerplusplusPath = GetHammerPlusPlus -OutDir "$hammerBundleTempPath"
Copy-Item -Path "$hammerplusplusPath/bin" -Destination "./" -Force -Recurse
Remove-Item -Path "$hammerBundleTempPath" -Force -Recurse

$infraPath     = Read-Host "ENTER INFRA PATH"
$infraBinPath  = "$infraPath/bin"
$infraGamePath = "$infraPath/infra"

$defaultCompilersParams = @"
"Command Sequences"
{
    "Default"
    {
        "1"
        {
            "enable"		"1"
            "specialcmd"		"0"
            "run"		"$infraBinPath\vbsp.exe"
            "parms"		"-game $infraGamePath `$path\`$file"
        }
        "2"
        {
            "enable"		"1"
            "specialcmd"		"0"
            "run"		"$infraBinPath\vvis.exe"
            "parms"		"-game $infraGamePath `$path\`$file"
        }
        "3"
        {
            "enable"		"1"
            "specialcmd"		"0"
            "run"		"$infraBinPath\vrad.exe"
            "parms"		"-staticproppolys -staticproplighting -game $infraGamePath `$path\`$file"
        }
        "4"
        {
            "enable"		"1"
            "specialcmd"		"257"
            "parms"		"`$path\`$file.bsp `$bspdir\`$file.bsp"
        }
        "5"
        {
            "enable"		"1"
            "specialcmd"		"0"
            "run"		"$infraPath\infra.exe"
            "parms"		"-dev -console -allowdebug -hijack -insecure -game $infraGamePath +map `$file"
        }
    }
    "Fast"
    {
        "1"
        {
            "enable"		"1"
            "specialcmd"		"0"
            "run"		"$infraBinPath\vbsp.exe"
            "parms"		"`$path\`$file"
        }
        "2"
        {
            "enable"		"1"
            "specialcmd"		"0"
            "run"		"$infraBinPath\vvis.exe"
            "parms"		"-fast `$path\`$file"
        }
        "3"
        {
            "enable"		"1"
            "specialcmd"		"0"
            "run"		"$infraBinPath\vrad.exe"
            "parms"		"-staticproppolys -staticproplighting -staticpropsamplescale 0.25 -bounce 2 -noextra `$path\`$file"
        }
        "4"
        {
            "enable"		"1"
            "specialcmd"		"257"
            "parms"		"`$path\`$file.bsp `$bspdir\`$file.bsp"
        }
        "5"
        {
            "enable"		"1"
            "specialcmd"		"0"
            "run"		"$infraPath\infra.exe"
            "parms"		"-dev -console -allowdebug -hijack -insecure +map `$file"
        }
    }
    "Full Compile"
    {
        "1"
        {
            "enable"		"1"
            "specialcmd"		"0"
            "run"		"$infraBinPath\vbsp.exe"
            "parms"		"`$path\`$file"
        }
        "2"
        {
            "enable"		"1"
            "specialcmd"		"0"
            "run"		"$infraBinPath\vvis.exe"
            "parms"		"`$path\`$file"
        }
        "3"
        {
            "enable"		"1"
            "specialcmd"		"0"
            "run"		"$infraBinPath\vrad.exe"
            "parms"		"-hdr -staticproppolys -staticproplighting `$path\`$file"
        }
        "4"
        {
            "enable"		"1"
            "specialcmd"		"257"
            "parms"		"`$path\`$file.bsp `$bspdir\`$file.bsp"
        }
        "5"
        {
            "enable"		"1"
            "specialcmd"		"0"
            "run"		"$infraPath\infra.exe"
            "parms"		"-dev -console -allowdebug -hijack -insecure +map `$file"
        }
    }
    "Full Compile -final (slow!)"
    {
        "1"
        {
            "enable"		"1"
            "specialcmd"		"0"
            "run"		"$infraBinPath\vbsp.exe"
            "parms"		"-game $infraGamePath `$path\`$file"
        }
        "2"
        {
            "enable"		"1"
            "specialcmd"		"0"
            "run"		"$infraBinPath\vvis.exe"
            "parms"		"-game $infraGamePath `$path\`$file"
        }
        "3"
        {
            "enable"		"1"
            "specialcmd"		"0"
            "run"		"$infraBinPath\vrad.exe"
            "parms"		"-hdr -final -staticproppolys -staticproplighting `$path\`$file"
        }
        "4"
        {
            "enable"		"1"
            "specialcmd"		"257"
            "parms"		"`$path\`$file.bsp `$bspdir\`$file.bsp"
        }
        "5"
        {
            "enable"		"1"
            "specialcmd"		"0"
            "run"		"$infraPath\infra.exe"
            "parms"		"-dev -console -allowdebug -hijack -insecure +map `$file"
        }
    }
    "Only Entities"
    {
        "1"
        {
            "enable"		"1"
            "specialcmd"		"0"
            "run"		"$infraBinPath\vbsp.exe"
            "parms"		"-onlyents `$path\`$file"
        }
        "2"
        {
            "enable"		"1"
            "specialcmd"		"257"
            "parms"		"`$path\`$file.bsp `$bspdir\`$file.bsp"
        }
        "3"
        {
            "enable"		"1"
            "specialcmd"		"0"
            "run"		"$infraPath\infra.exe"
            "parms"		"-dev -console -allowdebug -hijack -insecure +map `$file"
        }
    }
    "Run Map in Engine Fullscreen"
    {
        "1"
        {
            "enable"		"1"
            "run"		"$infraPath\infra.exe"
            "parms"		"-fullscreen -dev -console -allowdebug -hijack -insecure +map `$file"
        }
    }
    "Run Map in Engine Windowed"
    {
        "1"
        {
            "enable"		"1"
            "run"		"$infraPath\infra.exe"
            "parms"		"-sw -dev -console -allowdebug -hijack -insecure +map `$file"
        }
    }
}
"@

$defaultGamesParams = @"
"Configs"
{
	"SDKVersion"		"5"
	"Games"
	{
		"INFRA"
		{
			"GameDir"		"..\hammer"
			"Hammer"
			{
				"GameData0"		"..\root\bin\INFRA.fgd"
				"TextureFormat"		"5"
				"MapFormat"		"4"
				"DefaultTextureScale"		"0.250000"
				"DefaultLightmapScale"		"24"
				"GameExe"		"..\root\infra.exe"
				"DefaultSolidEntity"		"func_detail"
				"DefaultPointEntity"		"info_player_start"
				"BSP"		"..\root\bin\vbsp.exe"
				"Vis"		"..\root\bin\vvis.exe"
				"Light"		"..\root\bin\vrad.exe"
				"GameExeDir"		"..\root"
				"MapDir"		"..\game\maps"
				"BSPDir"		"$infraGamePath\maps"
				"PrefabDir"		"..\game\maps\Prefabs"
				"CordonTexture"		"tools/toolsnodraw"
				"MaterialExcludeCount"		"0"
				"Previous"		"1"
			}
		}
	}
}
"@

New-Item -ItemType "SymbolicLink" -Path "./game"     -Target "$infraPath/infra"    -Force
New-Item -ItemType "SymbolicLink" -Path "./platform" -Target "$infraPath/platform" -Force
New-Item -ItemType "SymbolicLink" -Path "./root"     -Target "$infraPath"          -Force

New-Item -Path "./bin/hammerplusplus/hammerplusplus_sequences.cfg"  -ItemType "File" -Value "$defaultCompilersParams" -Force
New-Item -Path "./bin/hammerplusplus/hammerplusplus_gameconfig.txt" -ItemType "File" -Value "$defaultGamesParams"     -Force
New-Item -Path "./bin/hammerplusplus/hammerplusplus_settings.ini"   -ItemType "File" -Value "$defaultHammerParams"    -Force