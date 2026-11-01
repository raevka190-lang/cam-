@echo off
setlocal
set "CAM_SETUP_FOLDER=%~dp0"
echo Downloading CAM NESTING protected Windows installer...
powershell.exe -NoLogo -NoProfile -Command "$ErrorActionPreference='Stop'; $work=$null; try { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $base='https://raw.githubusercontent.com/raevka190-lang/cam-/main/updates/protected-client/aff2050f/'; $out=Join-Path $env:CAM_SETUP_FOLDER 'CAM_Nesting_Protected_Setup.exe'; $work=Join-Path ([IO.Path]::GetTempPath()) ('cam-nesting-aff2050f-'+[Guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Path $work | Out-Null; $web=New-Object Net.WebClient; $mf=Join-Path $work 'manifest.json'; $web.DownloadFile($base+'parts-manifest.json',$mf); if ((Get-FileHash -Algorithm SHA256 -LiteralPath $mf).Hash -ne '51ed7907b2cef5436a4026b7ed1584ef3a1c7972535e1b8ca221506369cc823d') { throw 'Manifest checksum mismatch' }; $manifest=Get-Content -LiteralPath $mf -Raw | ConvertFrom-Json; $assembled=Join-Path $work 'setup.exe'; $stream=[IO.File]::OpenWrite($assembled); try { $i=0; foreach ($part in $manifest.parts) { if ($part.name -notmatch '^part-[0-9]{3}\.bin$') { throw 'Invalid part name' }; $i++; Write-Host ('Downloading '+$i+' / '+$manifest.parts.Count); $file=Join-Path $work $part.name; for ($attempt=1; $attempt -le 3; $attempt++) { try { $web.DownloadFile($base+$part.name,$file); break } catch { if ($attempt -eq 3) { throw }; Start-Sleep -Seconds 1 } }; if ((Get-Item -LiteralPath $file).Length -ne $part.bytes -or (Get-FileHash -Algorithm SHA256 -LiteralPath $file).Hash -ne $part.sha256) { throw ('Part checksum mismatch: '+$part.name) }; $bytes=[IO.File]::ReadAllBytes($file); $stream.Write($bytes,0,$bytes.Length); Remove-Item -LiteralPath $file }; } finally { $stream.Dispose() }; if ((Get-Item -LiteralPath $assembled).Length -ne 26833386 -or (Get-FileHash -Algorithm SHA256 -LiteralPath $assembled).Hash -ne 'aff2050fddcc05e6d545716f449850ab524998737c827d62b28634b71f2f3e76') { throw 'Installer checksum mismatch' }; Move-Item -LiteralPath $assembled -Destination $out -Force; Write-Host ('Ready: '+$out); } catch { Write-Host $_.Exception.Message; exit 1 } finally { if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force } }"
if errorlevel 1 goto failed
echo.
echo Ready. Run CAM_Nesting_Protected_Setup.exe in this folder.
pause
exit /b 0
:failed
echo Download failed. Check the internet connection and try again.
pause
exit /b 1
