@echo off
setlocal
cd /d "%~dp0"
if not defined FASTBOOT set "FASTBOOT=fastboot"

for %%I in (boot init_boot vendor_boot dtbo pvmfw recovery vbmeta_system vbmeta_vendor vbmeta) do (
    if not exist "%%I.img" (
        echo Missing %%I.img
        exit /b 1
    )
)

echo Nothing Phone ^(3^) / metroid Lineage Recovery bootstrap
echo This flashes the matched release boot and AVB chain to both slots.
echo It does not disable AVB and does not touch super or userdata.
echo.
"%FASTBOOT%" devices || goto :fail
"%FASTBOOT%" getvar product 2>&1
set /p "CONFIRM=Type metroid to continue: "
if /i not "%CONFIRM%"=="metroid" (
    echo Cancelled.
    exit /b 1
)

"%FASTBOOT%" set_active a || goto :fail
"%FASTBOOT%" erase misc || goto :fail

for %%S in (a b) do (
    "%FASTBOOT%" flash boot_%%S boot.img || goto :fail
    "%FASTBOOT%" flash init_boot_%%S init_boot.img || goto :fail
    "%FASTBOOT%" flash vendor_boot_%%S vendor_boot.img || goto :fail
    "%FASTBOOT%" flash dtbo_%%S dtbo.img || goto :fail
    "%FASTBOOT%" flash pvmfw_%%S pvmfw.img || goto :fail
    "%FASTBOOT%" flash recovery_%%S recovery.img || goto :fail
    "%FASTBOOT%" flash vbmeta_system_%%S vbmeta_system.img || goto :fail
    "%FASTBOOT%" flash vbmeta_vendor_%%S vbmeta_vendor.img || goto :fail
    "%FASTBOOT%" flash vbmeta_%%S vbmeta.img || goto :fail
)

"%FASTBOOT%" set_active a || goto :fail
"%FASTBOOT%" erase misc || goto :fail
echo Rebooting to Lineage Recovery. Do not reboot Android before sideloading the ROM.
"%FASTBOOT%" reboot recovery || goto :fail
exit /b 0

:fail
echo Fastboot failed. Stop here and use your stock restore procedure.
exit /b 1
