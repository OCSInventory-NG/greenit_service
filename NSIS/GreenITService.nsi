#####################################################################
# Defines, includes and default settings
#####################################################################
!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "WordFunc.nsh"

SetCompressor lzma

!define PRODUCT_NAME "GreenIT Service"
!define PRODUCT_VERSION "1.0"
!define PRODUCT_PUBLISHER "FactorFX"
!define PRODUCT_WEB_SITE "https://factorfx.com"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\GreenIT.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "C:\Users\developpeur\Downloads\GreenITService_Installer.exe"
InstallDir "$PROGRAMFILES\GreenIT Service"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show

; Vairables
Var Dialog
Var COLLECT_INFO_PERIOD_Label
Var COLLECT_INFO_PERIOD
Var UPLOAD_PERIOD_Label
Var UPLOAD_PERIOD
Var SAVE_INFO_PERIOD_Label
Var SAVE_INFO_PERIOD

#####################################################################
# MUI settings
#####################################################################
!define MUI_ABORTWARNING
!define MUI_ICON "greenit.ico"
!define MUI_UNICON "greenit.ico"

; Welcome page
!insertmacro MUI_PAGE_WELCOME
; License page
!insertmacro MUI_PAGE_LICENSE "..\LICENSE.txt"
; Directory page
!insertmacro MUI_PAGE_DIRECTORY
; Config page
Page custom ConfigPage ConfigPageLeave
; Instfiles page
!insertmacro MUI_PAGE_INSTFILES
; Finish page
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\README.md"
!insertmacro MUI_PAGE_FINISH
; Uninstaller pages
!insertmacro MUI_UNPAGE_INSTFILES
; Language files
!insertmacro MUI_LANGUAGE "English"
; Reserve files
ReserveFile /plugin InstallOptions.dll

#####################################################################
# Setup
#####################################################################
Function GetParameters
         Push $R0
         Push $R1
         Push $R2
         Push $R3

         StrCpy $R2 1
         StrLen $R3 $CMDLINE

         ;Check for quote or space
         StrCpy $R0 $CMDLINE $R2
         StrCmp $R0 '"' 0 +3
         StrCpy $R1 '"'
         Goto loop
         StrCpy $R1 " "
         
loop:
         IntOp $R2 $R2 + 1
         StrCpy $R0 $CMDLINE 1 $R2
         StrCmp $R0 $R1 get
         StrCmp $R2 $R3 get
         Goto loop
         
get:
         IntOp $R2 $R2 + 1
         StrCpy $R0 $CMDLINE 1 $R2
         StrCmp $R0 " " get
         StrCpy $R0 $CMDLINE "" $R2

         Pop $R3
         Pop $R2
         Pop $R1
         Exch $R0
FunctionEnd

Function GetOptions
         !define GetOptions `!insertmacro GetOptionsCall`

         !macro GetOptionsCall _PARAMETERS _OPTION _RESULT
                Push `${_PARAMETERS}`
                Push `${_OPTION}`
                Call GetOptions
                Pop ${_RESULT}
         !macroend

         Exch $1
         Exch
         Exch $0
         Exch
         Push $2
         Push $3
         Push $4
         Push $5
         Push $6
         Push $7
         ClearErrors

         StrCpy $2 $1 '' 1
         StrCpy $1 $1 1
         StrLen $3 $2
         StrCpy $7 0

begin:
         StrCpy $4 -1
         StrCpy $6 ''

quote:
         IntOp $4 $4 + 1
         StrCpy $5 $0 1 $4
         StrCmp $5$7 '0' notfound
         StrCmp $5 '' trimright
         StrCmp $5 '"' 0 +7
         StrCmp $6 '' 0 +3
         StrCpy $6 '"'
         goto quote
         StrCmp $6 '"' 0 +3
         StrCpy $6 ''
         goto quote
         StrCmp $5 `'` 0 +7
         StrCmp $6 `` 0 +3
         StrCpy $6 `'`
         goto quote
         StrCmp $6 `'` 0 +3
         StrCpy $6 ``
         goto quote
         StrCmp $5 '`' 0 +7
         StrCmp $6 '' 0 +3
         StrCpy $6 '`'
         goto quote
         StrCmp $6 '`' 0 +3
         StrCpy $6 ''
         goto quote
         StrCmp $6 '"' quote
         StrCmp $6 `'` quote
         StrCmp $6 '`' quote
         StrCmp $5 $1 0 quote
         StrCmp $7 0 trimleft trimright

trimleft:
         IntOp $4 $4 + 1
         StrCpy $5 $0 $3 $4
         StrCmp $5 '' notfound
         StrCmp $5 $2 0 quote
         IntOp $4 $4 + $3
         StrCpy $0 $0 '' $4
         StrCpy $4 $0 1
         StrCmp $4 ' ' 0 +3
         StrCpy $0 $0 '' 1
         goto -3
         StrCpy $7 1
         goto begin

trimright:
         StrCpy $0 $0 $4
         StrCpy $4 $0 1 -1
         StrCmp $4 ' ' 0 +3
         StrCpy $0 $0 -1
         goto -3
         StrCpy $3 $0 1
         StrCpy $4 $0 1 -1
         StrCmp $3 $4 0 end
         StrCmp $3 '"' +3
         StrCmp $3 `'` +2
         StrCmp $3 '`' 0 end
         StrCpy $0 $0 -1 1
         goto end

notfound:
         SetErrors
         StrCpy $0 ''

end:
         Pop $7
         Pop $6
         Pop $5
         Pop $4
         Pop $3
         Pop $2
         Pop $1
         Exch $0
FunctionEnd

Function InstallService
         Call GetParameters
         Exch $R0
         ${GetOptions} $R0 "/collectPeriod" $R1
         IfErrors 0 +3
         MessageBox MB_OK "Missing collectPeriod setting!"
         Abort
         ${GetOptions} $R0 "/uploadPeriod" $R1
         IfErrors 0 +3
         MessageBox MB_OK "Missing uploadPeriod setting!"
         Abort
         ${GetOptions} $R0 "/savesPeriod" $R1
         IfErrors 0 +3
         MessageBox MB_OK "Missing savestPeriod setting!"
         Abort
         ExecWait '"$INSTDIR\GreenIT.exe" install'
FunctionEnd

Function StartService
         ExecWait '"$INSTDIR\GreenIT.exe" start'
FunctionEnd

Function .onInit
         Call GetParameters
         Exch $R0
         ${GetOptions} $R0 "/silent" $R1
         IfErrors +2 0
         SetSilent silent
FunctionEnd

Section "Main" SEC01
         SetOutPath "$INSTDIR"
         SetOverwrite try
         File "..\Project\GreenIT\bin\Release\net6.0\System.Diagnostics.EventLog.dll"
         File "..\Project\GreenIT\bin\Release\net6.0\GreenIT.exe"
         File "..\Project\GreenIT\bin\Release\net6.0\config.json"
         Call UploadConfig
         AccessControl::GrantOnFile "$INSTDIR\config.ini" "(BU)" "GenericExecute + GenericRead + GenericWrite"
         CreateDirectory "$SMPROGRAMS\GreenIT Service"
         CreateShortCut "$SMPROGRAMS\GreenIT Service\GreenIT Service.lnk" "$INSTDIR\GreenIT.exe"
         File "..\Project\GreenIT\bin\Release\net6.0\System.IO.Ports.dll"
         File "..\Project\GreenIT\bin\Release\net6.0\Microsoft.Win32.SystemEvents.dll"
         File "..\Project\GreenIT\bin\Release\net6.0\System.Management.dll"
         SetOutPath "$INSTDIR\runtimes\win\lib\netstandard2.0"
         File "..\Project\GreenIT\bin\Release\net6.0\runtimes\win\lib\netstandard2.0\System.IO.Ports.dll"
         File "..\Project\GreenIT\bin\Release\net6.0\runtimes\win\lib\netstandard2.0\System.ServiceProcess.ServiceController.dll"
         SetOutPath "$INSTDIR\runtimes\win\lib\netcoreapp2.0"
         File "..\Project\GreenIT\bin\Release\net6.0\runtimes\win\lib\netcoreapp2.0\System.Diagnostics.EventLog.dll"
         File "..\Project\GreenIT\bin\Release\net6.0\runtimes\win\lib\netcoreapp2.0\System.Management.dll"
         SetOutPath "$INSTDIR\runtimes\win\lib\netcoreapp3.0"
         File "..\Project\GreenIT\bin\Release\net6.0\runtimes\win\lib\netcoreapp3.0\Microsoft.Win32.SystemEvents.dll"
         SetOutPath "$INSTDIR"
         File "..\Project\GreenIT\bin\Release\net6.0\System.ServiceProcess.ServiceController.dll"
         File "..\Project\GreenIT\bin\Release\net6.0\GreenIT.deps.json"
         File "..\Project\GreenIT\bin\Release\net6.0\HidLibrary.dll"
         File "..\Project\GreenIT\bin\Release\net6.0\TopShelf.ServiceInstaller.dll"
         File "..\Project\GreenIT\bin\Release\net6.0\System.CodeDom.dll"
         File "..\Project\GreenIT\bin\Release\net6.0\GreenIT.runtimeconfig.json"
         File "..\Project\GreenIT\bin\Release\net6.0\OpenHardwareMonitorLib.dll"
         File "..\Project\GreenIT\bin\Release\net6.0\GreenIT.pdb"
         File "..\Project\GreenIT\bin\Release\net6.0\GreenIT.dll"
         File "..\Project\GreenIT\bin\Release\net6.0\Topshelf.dll"
         SetOverwrite ifnewer
         File "..\README.md"
         File "..\LICENSE.txt"
         Call InstallService
         Call StartService
SectionEnd

#####################################################################
# Config page
#####################################################################
Function ConfigPage
         !insertmacro MUI_HEADER_TEXT "Configuration of service settings" "Configure your own service settings."
         nsDialogs::Create 1018
         Pop $Dialog

         ${If} $Dialog == error
                Abort
         ${EndIf}

         ${NSD_CreateGroupBox} 0 0 100% 100% "Service configuration"

         ${NSD_CreateLabel} 5% 25% 55% 10u "Period between collecting information (in seconds) :"
         Pop $COLLECT_INFO_PERIOD_Label

         ${NSD_CreateNumber} 65% 25% 20% 12u "1"
         Pop $COLLECT_INFO_PERIOD
         ${NSD_Edit_SetTextLimit} $COLLECT_INFO_PERIOD 4

         ${NSD_CreateLabel} 5% 50% 45% 10u "Period between uploads (in minutes) :"
         Pop $UPLOAD_PERIOD_Label

         ${NSD_CreateNumber} 65% 50% 20% 12u "0"
         Pop $UPLOAD_PERIOD
         ${NSD_Edit_SetTextLimit} $UPLOAD_PERIOD 4

         ${NSD_CreateLabel} 5% 75% 40% 10u "Period between saves (in hours) :"
         Pop $SAVE_INFO_PERIOD_Label

         ${NSD_CreateNumber} 65% 75% 20% 12u "1"
         Pop $SAVE_INFO_PERIOD
         ${NSD_Edit_SetTextLimit} $SAVE_INFO_PERIOD 4

         nsDialogs::Show
FunctionEnd

Function ConfigPageLeave
         ${NSD_GetText} $COLLECT_INFO_PERIOD $0
         ${NSD_GetText} $UPLOAD_PERIOD $1
         ${NSD_GetText} $SAVE_INFO_PERIOD $2
FunctionEnd

Function UploadConfig
         IfSilent 0 +9
         Call GetParameters
         Exch $R0
         ${GetOptions} $R0 "/collectPeriod=" $R1
         StrCpy $0 $R1
         MessageBox MB_OK $R1
         ${GetOptions} $R0 "/collectPeriod=" $R1
         StrCpy $1 $R1
         ${GetOptions} $R0 "/collectPeriod=" $R1
         StrCpy $2 $R1
         nsJSON::Set /file `$INSTDIR\config.json`
         nsJSON::Set `COLLECT_INFO_PERIOD` /value `"$0"`
         nsJSON::Set `UPLOAD_PERIOD` /value `"$1"`
         nsJSON::Set `SAVE_INFO_PERIOD` /value `"$2"`
         nsJSON::Serialize /file `$INSTDIR\config.json`
FunctionEnd

#####################################################################
# Addons
#####################################################################
Section -AdditionalIcons
         WriteIniStr "$INSTDIR\${PRODUCT_NAME}.url" "InternetShortcut" "URL" "${PRODUCT_WEB_SITE}"
         CreateShortCut "$SMPROGRAMS\GreenIT Service\Website.lnk" "$INSTDIR\${PRODUCT_NAME}.url"
         CreateShortCut "$SMPROGRAMS\GreenIT Service\Uninstall.lnk" "$INSTDIR\uninstall.exe"
SectionEnd

Section -Post
         WriteUninstaller "$INSTDIR\uninstall.exe"
         WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\GreenIT.exe"
         WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
         WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
         WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\GreenIT.exe"
         WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
         WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
         WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
SectionEnd

#####################################################################
# Uninstaller
#####################################################################
Function un.GetParameters
         Push $R0
         Push $R1
         Push $R2
         Push $R3

         StrCpy $R2 1
         StrLen $R3 $CMDLINE

         ;Check for quote or space
         StrCpy $R0 $CMDLINE $R2
         StrCmp $R0 '"' 0 +3
         StrCpy $R1 '"'
         Goto loop
         StrCpy $R1 " "
         
loop:
         IntOp $R2 $R2 + 1
         StrCpy $R0 $CMDLINE 1 $R2
         StrCmp $R0 $R1 get
         StrCmp $R2 $R3 get
         Goto loop
         
get:
         IntOp $R2 $R2 + 1
         StrCpy $R0 $CMDLINE 1 $R2
         StrCmp $R0 " " get
         StrCpy $R0 $CMDLINE "" $R2

         Pop $R3
         Pop $R2
         Pop $R1
         Exch $R0
FunctionEnd

Function un.GetOptions
         !define un.GetOptions `!insertmacro un.GetOptionsCall`

         !macro un.GetOptionsCall _PARAMETERS _OPTION _RESULT
                Push `${_PARAMETERS}`
                Push `${_OPTION}`
                Call un.GetOptions
                Pop ${_RESULT}
         !macroend

         Exch $1
         Exch
         Exch $0
         Exch
         Push $2
         Push $3
         Push $4
         Push $5
         Push $6
         Push $7
         ClearErrors

         StrCpy $2 $1 '' 1
         StrCpy $1 $1 1
         StrLen $3 $2
         StrCpy $7 0

begin:
         StrCpy $4 -1
         StrCpy $6 ''

quote:
         IntOp $4 $4 + 1
         StrCpy $5 $0 1 $4
         StrCmp $5$7 '0' notfound
         StrCmp $5 '' trimright
         StrCmp $5 '"' 0 +7
         StrCmp $6 '' 0 +3
         StrCpy $6 '"'
         goto quote
         StrCmp $6 '"' 0 +3
         StrCpy $6 ''
         goto quote
         StrCmp $5 `'` 0 +7
         StrCmp $6 `` 0 +3
         StrCpy $6 `'`
         goto quote
         StrCmp $6 `'` 0 +3
         StrCpy $6 ``
         goto quote
         StrCmp $5 '`' 0 +7
         StrCmp $6 '' 0 +3
         StrCpy $6 '`'
         goto quote
         StrCmp $6 '`' 0 +3
         StrCpy $6 ''
         goto quote
         StrCmp $6 '"' quote
         StrCmp $6 `'` quote
         StrCmp $6 '`' quote
         StrCmp $5 $1 0 quote
         StrCmp $7 0 trimleft trimright

trimleft:
         IntOp $4 $4 + 1
         StrCpy $5 $0 $3 $4
         StrCmp $5 '' notfound
         StrCmp $5 $2 0 quote
         IntOp $4 $4 + $3
         StrCpy $0 $0 '' $4
         StrCpy $4 $0 1
         StrCmp $4 ' ' 0 +3
         StrCpy $0 $0 '' 1
         goto -3
         StrCpy $7 1
         goto begin

trimright:
         StrCpy $0 $0 $4
         StrCpy $4 $0 1 -1
         StrCmp $4 ' ' 0 +3
         StrCpy $0 $0 -1
         goto -3
         StrCpy $3 $0 1
         StrCpy $4 $0 1 -1
         StrCmp $3 $4 0 end
         StrCmp $3 '"' +3
         StrCmp $3 `'` +2
         StrCmp $3 '`' 0 end
         StrCpy $0 $0 -1 1
         goto end

notfound:
         SetErrors
         StrCpy $0 ''

end:
         Pop $7
         Pop $6
         Pop $5
         Pop $4
         Pop $3
         Pop $2
         Pop $1
         Exch $0
FunctionEnd

Function un.onInit
         Call un.GetParameters
         Exch $R0
         ${un.GetOptions} $R0 "/silent" $R1
         IfErrors +2 0
         SetSilent silent
         IfErrors 0 +3
         MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Are you sure you want to uninstall $(^Name) ?" IDYES +2
         Abort
FunctionEnd

Function un.StopService
         ExecWait '"$INSTDIR\GreenIT.exe" uninstall'
FunctionEnd

Section Uninstall
         Call un.StopService
         Delete "$INSTDIR\${PRODUCT_NAME}.url"
         Delete "$INSTDIR\uninstall.exe"
         Delete "$INSTDIR\LICENSE.txt"
         Delete "$INSTDIR\README.md"
         Delete "$INSTDIR\Topshelf.dll"
         Delete "$INSTDIR\GreenIT.dll"
         Delete "$INSTDIR\GreenIT.pdb"
         Delete "$INSTDIR\OpenHardwareMonitorLib.dll"
         Delete "$INSTDIR\GreenIT.runtimeconfig.json"
         Delete "$INSTDIR\System.CodeDom.dll"
         Delete "$INSTDIR\TopShelf.ServiceInstaller.dll"
         Delete "$INSTDIR\HidLibrary.dll"
         Delete "$INSTDIR\GreenIT.deps.json"
         Delete "$INSTDIR\System.ServiceProcess.ServiceController.dll"
         Delete "$INSTDIR\runtimes\win\lib\netcoreapp3.0\Microsoft.Win32.SystemEvents.dll"
         Delete "$INSTDIR\runtimes\win\lib\netcoreapp2.0\System.Management.dll"
         Delete "$INSTDIR\runtimes\win\lib\netcoreapp2.0\System.Diagnostics.EventLog.dll"
         Delete "$INSTDIR\runtimes\win\lib\netstandard2.0\System.ServiceProcess.ServiceController.dll"
         Delete "$INSTDIR\runtimes\win\lib\netstandard2.0\System.IO.Ports.dll"
         Delete "$INSTDIR\System.Management.dll"
         Delete "$INSTDIR\Microsoft.Win32.SystemEvents.dll"
         Delete "$INSTDIR\System.IO.Ports.dll"
         Delete "$INSTDIR\GreenIT.exe"
         Delete "$INSTDIR\config.json"
         Delete "$INSTDIR\System.Diagnostics.EventLog.dll"

         Delete "$SMPROGRAMS\GreenIT Service\Uninstall.lnk"
         Delete "$SMPROGRAMS\GreenIT Service\Website.lnk"
         Delete "$DESKTOP\GreenIT Service.lnk"
         Delete "$SMPROGRAMS\GreenIT Service\GreenIT Service.lnk"

         RMDir "$SMPROGRAMS\GreenIT Service"
         RMDir "$INSTDIR\runtimes\win\lib\netstandard2.0"
         RMDir "$INSTDIR\runtimes\win\lib\netcoreapp3.0"
         RMDir "$INSTDIR\runtimes\win\lib\netcoreapp2.0"
         RMDir "$INSTDIR\runtimes\win\lib"
         RMDir "$INSTDIR\runtimes\win"
         RMDir "$INSTDIR\runtimes"
         RMDir "$INSTDIR"

         DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
         DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
         SetAutoClose true
SectionEnd

Function un.onUninstSuccess
         HideWindow
         Call un.GetParameters
         Exch $R0
         ${un.GetOptions} $R0 "/silent" $R1
         IfErrors +2 0
         SetSilent silent
         IfErrors 0 +2
         MessageBox MB_ICONINFORMATION|MB_OK "$(^Name) was successfully uninstalled."
FunctionEnd