@echo off
set psfile="%cd%\download_community.ps1"
echo $computer="cname" > %psfile%
for /f "delims=:" %%i in ('findstr /n "^:JoinDomain$" "%~f0"') do (
	more +%%i "%~f0" >> %psfile%
)
powershell -executionpolicy remotesigned -file %psfile%

del %psfile%
exit

:JoinDomain
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
$source = "https://apigw-devops-serverless.idreamsky.com/app/download/ae6501f4-c5a5-5a00-84a2-6eb42229d869?fileName=window_resource.zip"
$dest = "./android/unity_resource_android_windows.zip"
$unityExport = "./android/unityExport/src/main"
$unityExportManifest = "./$UnityExport/AndroidManifest.xml"
$unityExportManifestBackup = "./$UnityExport/../AndroidManifest.xml"

$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $source -OutFile $dest

if (Test-Path -LiteralPath $unityExportManifestBackup) {
    Remove-Item -Path $unityExportManifestBackup
}
mv -path $unityExportManifest -destination $unityExportManifestBackup
Remove-Item -Path $unityExport -Recurse
Expand-Archive -Path $dest -DestinationPath $unityExport
Remove-Item -Path $unityExportManifest
mv -path $unityExportManifestBackup -destination $unityExportManifest
Remove-Item -Path $dest