; Defines
!define PRODUCT_NAME "GreenIT Service"
!define PRODUCT_VERSION "1.0"
!define PRODUCT_PUBLISHER "FactorFX"
!define PRODUCT_WEB_SITE "https://factorfx.com"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\GreenIT.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

SetCompressor lzma

; Includes
!include "MUI.nsh"
!include "nsDialogs.nsh"

; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

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
!define MUI_FINISHPAGE_RUN "$INSTDIR\GreenIT.exe"
!define MUI_FINISHPAGE_RUN_PARAMETERS "install start"
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\README.md"
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_INSTFILES

; Language files
!insertmacro MUI_LANGUAGE "English"

; Reserve files
!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS

; MUI end ------

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
SectionEnd

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
        nsJSON::Set /file `$INSTDIR\config.json`
        nsJSON::Set `COLLECT_INFO_PERIOD` /value `"$0"`
        nsJSON::Set `UPLOAD_PERIOD` /value `"$1"`
        nsJSON::Set `SAVE_INFO_PERIOD` /value `"$2"`
        nsJSON::Serialize /file `$INSTDIR\config.json`
FunctionEnd

Function un.onUninstSuccess
        HideWindow
        MessageBox MB_ICONINFORMATION|MB_OK "$(^Name) a été désinstallé avec succès de votre ordinateur."
FunctionEnd

Function un.onInit
        MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Êtes-vous certains de vouloir désinstaller totalement $(^Name) et tous ses composants ?" IDYES +2
        Abort
FunctionEnd

Section Uninstall
        ExecWait '"$INSTDIR\GreenIT.exe" uninstall'
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