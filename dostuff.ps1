function CheckAll {
    $files = Get-ChildItem -Recurse . | Select-Object -Expand Fullname
    foreach ($file in $files) {
        $size = (Get-Item -Path $file).Length / 1MB | ForEach-Object { '{0:0.##}' -f $_ }
        Write-Host "${size}MB: $file"
    }     
}

function Update-Csproj {
    $csproj = Get-ChildItem -Path . -Include *.csproj -Recurse | Select-Object -ExpandProperty Fullname

    @"
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net7.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>


    <PackageId>Contoso.08.28.22.001.Test</PackageId>
    <Version>1.0.0</Version>
    <Authors>your_name</Authors>
    <Company>your_company</Company>
    <GeneratePackageOnBuild>true</GeneratePackageOnBuild>

  </PropertyGroup>

</Project>

"@ | Out-File -Encoding ASCII $csproj

}

function Get-FileIfNotExists {
    Param (
        $Url,
        $Destination
    )

    if (-not (Test-Path $Destination)) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $ProgressPreference = 'SilentlyContinue'

        Write-Verbose "Downloading $Url"
        Invoke-WebRequest -UseBasicParsing -Uri $url -Outfile $Destination
    }
    else {
        Write-Verbose "${Destination} already exists. Skipping."
    }
}

function Check {
    $exts = @(
        "exe"
        "csproj"
        "nuspec"
        "nupkg"
    )

    foreach ($ext in $exts) {
        Write-Host "${ext}:"
        $files = Get-ChildItem -Path . -Include *.$ext -Recurse | Select-Object -ExpandProperty Fullname
        foreach ($file in $files) {
            $size = (Get-Item -Path $file).Length / 1MB | ForEach-Object { '{0:0.##}' -f $_ }
            Write-Host $file
            Write-Host "size:${size}"
        }     
    }
}

function Update-Nuspec {
    $nuspec = Get-ChildItem -Path . -Include *.nuspec -Recurse | Select-Object -ExpandProperty Fullname

    $exe = Get-ChildItem -Path . -Include *.exe -Recurse | Select-Object -ExpandProperty Fullname

    @"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2012/06/nuspec.xsd">
  <metadata>
    <id>Contoso.08.28.22.001.Test</id>
    <version>1.0.0</version>
    <authors>your_name</authors>
    <description>Package Description</description>
    <dependencies>
      <group targetFramework="net7.0" />
    </dependencies>
  </metadata>
  <files>
    <file src="$exe" target="lib\net7.0\reactnut.exe" />
  </files>
</package>

"@ | Out-File -Encoding ASCII $nuspec

    Get-Content $nuspec

}

Function GetExe {

    $url = "https://github.com/taylormonacelli/reactnut/releases/latest/download/reactnut_Windows_x86_64.zip"
    $filename = Split-Path -Leaf -Path $url
    Get-FileIfNotExists $url "c:\Windows\Temp\$filename"

    $global:ProgressPreference = "SilentlyContinue"
    Expand-Archive -Force "c:\Windows\Temp\$filename"
    $exe = Get-ChildItem -Path reactnut_Windows_x86_64 -Include *.exe -Recurse | Select-Object -ExpandProperty Fullname
    $exe
    Get-ChildItem ./reactnut_Windows_x86_64/reactnut.exe

}



function main {
    $ErrorActionPreference = "Stop"
    Set-PSDebug -Trace 0
    $projPath = "C:\Users\Administrator\AppLogger"
    Set-Location "$projPath/.."

    Remove-Item $projPath -Force -Recurse -ErrorAction SilentlyContinue

    New-Item -Type "directory" -Force -Path AppLogger | Out-Null
    Set-Location $projPath

    GetExe

    dotnet new classlib
    Check

    Update-Csproj
    dotnet build

    Update-Nuspec
    dotnet build
    dotnet pack
    Check
    CheckAll
}
