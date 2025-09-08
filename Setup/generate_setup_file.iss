#define AppName "GreenIT Service"
#define AppVersion "2.0"
#define AppPublisher "FactorFX"
#define AppURL "https://factorfx.com/"
#define AppExeName "Service.exe"
#define AppPath "\path\to\generated\service\binary"
; from source directory: **\Service\bin\Release\net8.0\ 

[Setup]
AppId={{81BEA8FD-0E67-4831-B6D7-198603933A19}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
DefaultDirName={autopf}\{#AppName}
UninstallDisplayIcon={app}\{#AppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
LicenseFile=..\LICENSE.txt
OutputBaseFilename=GreenIT-Service-setup-{#AppVersion}
SetupIconFile=greenit.ico
SetupLogging=yes
SolidCompression=yes
UninstallLogging=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Files]
Source: "JSONConfig.dll"; Flags: dontcopy
Source: "{#AppPath}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#AppPath}\config.json"; DestDir: "{commonappdata}\GreenIT\"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"

[Code]
var
  InputPage: TInputQueryWizardPage;
  RunNowPage: TWizardPage;
  RunNowCheckBox: TNewCheckBox;
  ConfigPath: String;
  CollectPeriod, WritingPeriod, BackupPeriod: Int64;
  ResultCode: Integer;

procedure InitializeWizard;
begin
  Log(ExpandConstant('{cm:StartingGreenITSetup}'));
  ConfigPath := ExpandConstant('{commonappdata}\GreenIT\config.json');
  if WizardSilent then
  begin
    Log(ExpandConstant('{cm:RunningInSilentMode}'));
  end
  else
  begin
    Log(ExpandConstant('{cm:RunningInInteractiveMode}'));
    InputPage := CreateInputQueryPage(wpSelectDir, ExpandConstant('{cm:ServiceConfigurationPageTitle}'), ExpandConstant('{cm:ServiceConfigurationPageDescription}'), '');
    
    InputPage.Add(ExpandConstant('{cm:CollectPeriodDescription}'), False);
    InputPage.Add(ExpandConstant('{cm:WritingPeriodDescription}'), False);
    InputPage.Add(ExpandConstant('{cm:BackupPeriodDescription}'), False);
    
    InputPage.Values[0] := '1';
    InputPage.Values[1] := '0';
    InputPage.Values[2] := '1';
    
    RunNowPage := CreateCustomPage(InputPage.ID, ExpandConstant('{cm:ServiceConfigurationPageTitle}'), ExpandConstant('{cm:ServiceConfigurationPageDescription}'));
    
    RunNowCheckBox := TNewCheckBox.Create(RunNowPage);
    RunNowCheckBox.Parent := RunNowPage.Surface;
    RunNowCheckBox.Top := 0;
    RunNowCheckBox.Left := 0;
    RunNowCheckBox.Width := RunNowPage.SurfaceWidth;
    RunNowCheckBox.Caption := ExpandConstant('{cm:StartingServiceDescription}');
    RunNowCheckBox.Checked := True;

    Log(ExpandConstant('{cm:WaitingUserToEnterInputs}'));
  end;
end;

function JSONWriteInteger(FileName, Section, Key: String; Value: Int64): Boolean;
external 'JSONWriteInteger@files:jsonconfig.dll stdcall';

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;

  if WizardSilent then
  begin
    Exit;
  end
  else
  begin
    if CurPageID = InputPage.ID then
    begin    
      if InputPage.Values[0] = '' then
      begin
        MsgBox('Error: No value on collect period input', mbError, MB_OK);
        Result := False;
      end
      else if InputPage.Values[1] = '' then
      begin
        MsgBox('Error: No value on writing period input', mbError, MB_OK);
        Result := False;
      end
      else if InputPage.Values[2] = '' then
      begin
        MsgBox('Error: No value on backup period input', mbError, MB_OK);
        Result := False;
      end
      else
      begin
        Log(Format(ExpandConstant('{cm:InputValidated}'), [InputPage.Values[0], InputPage.Values[1], InputPage.Values[1]]));
      end;
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if WizardSilent then
    begin
      CollectPeriod := StrToInt64Def(ExpandConstant('{param:COLLECT_PERIOD}'), 1);
      WritingPeriod := StrToInt64Def(ExpandConstant('{param:WRITING_PERIOD}'), 0);
      BackupPeriod := StrToInt64Def(ExpandConstant('{param:BACKUP_PERIOD}'), 1);
    end
    else
    begin
      CollectPeriod := StrToInt64Def(InputPage.Values[0], 1);
      WritingPeriod := StrToInt64Def(InputPage.Values[1], 0);
      BackupPeriod := StrToInt64Def(InputPage.Values[2], 1);
    end;

    JSONWriteInteger(ConfigPath, 'collect', 'period', CollectPeriod);
    JSONWriteInteger(ConfigPath, 'writing', 'period', WritingPeriod);
    JSONWriteInteger(ConfigPath, 'backup', 'period', BackupPeriod);

    Log(ExpandConstant('{cm:JONConfigurationWritten}'));

    Log(ExpandConstant('{cm:InstallingService}'));

    Exec('sc.exe', 'create "GreenIT Service" binpath= "C:\Program Files\GreenIT Service\Service.exe" start= "auto"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Exec('sc.exe', 'description "GreenIT Service" "Collect consumption information for OCSInventory GreenIT plugin."', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Log(ExpandConstant('{cm:ServiceInstalled}'));
    if WizardSilent then
    begin
      Log(ExpandConstant('{cm:StartingService}'));
      Exec('sc.exe', 'start "GreenIT Service"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    end
    else
    begin
      if RunNowCheckBox.Checked then
      begin
        Log(ExpandConstant('{cm:StartingService}'));
        Exec('sc.exe', 'start "GreenIT Service"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
      end;
    end;
    Log(ExpandConstant('{cm:ServiceStarted}'));
    Log(ExpandConstant('{cm:SetupCompleted}'));
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
  begin
    if Exec('sc.exe', 'stop "GreenIT Service"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    begin
      if Exec('sc.exe', 'delete "GreenIT Service"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
      begin
        Log(ExpandConstant('{cm:ServiceDeletedSuccessfully}'));
      end
      else
      begin
        MsgBox(ExpandConstant('{cm:ServiceDeleteFailed}'), mbError, MB_OK);
      end;
    end
    else
    begin
      MsgBox(ExpandConstant('{cm:ServiceDeleteFailed}'), mbError, MB_OK);
    end;
  end;
end;


[CustomMessages]
StartingGreenITSetup=Starting GreenIT Service setup...
RunningInSilentMode=Running in silent mode...
RunningInInteractiveMode=Running in interactive mode...
ServiceConfigurationPageTitle=Service Configuration
ServiceConfigurationPageDescription=Please enter the configuration parameters for the service.
CollectPeriodDescription=Period between collecting information (in seconds):
WritingPeriodDescription=Period between data is written in data file (in minutes):
BackupPeriodDescription=Period between data is written in bakcup file (in hours):
StartingServiceDescription=Start the service now
WaitingUserToEnterInputs=Waiting for user to enter inputs...
InputValidated=Input validated: collect period=%s seconds, writing period=%s minutes, backup period=%s hours.
JONConfigurationWritten=JSON configuration file written successfully.
InstallingService=Installing the Windows service...
ServiceInstalled=Windows service installed successfully.
StartingService=Starting the Windows service...
ServiceStarted=Windows service started successfully.
SetupCompleted=Setup completed successfully.
ServiceDeletedSuccessfully=Windows service deleted successfully.
ServiceDeleteFailed=Failed to delete the Windows service. Please stop it manually and try again.

french.StartingGreenITSetup=Démarrage de l'installation du service GreenIT...
french.RunningInSilentMode=Exécution en mode silencieux...
french.RunningInInteractiveMode=Exécution en mode interactif...
french.ServiceConfigurationPageTitle=Configuration du service
french.ServiceConfigurationPageDescription=Veuillez entrer les paramètres de configuration pour le service.
french.CollectPeriodDescription=Période entre chaque collecte d'informations (en secondes) :
french.WritingPeriodDescription=Période entre chaque écriture des données dans le fichier (en minutes) :
french.BackupPeriodDescription=Période entre chaque écriture des données dans le fichier de sauvegarde (en heures) :
french.StartingServiceDescription=Démarrer le service maintenant
french.WaitingUserToEnterInputs=En attente que l'utilisateur saisisse les entrées...
french.InputValidated=Entrée validée : période de collecte=%s secondes, période d'écriture=%s minutes, période de sauvegarde=%s heures.
french.JONConfigurationWritten=Fichier de configuration JSON écrit avec succès.
french.InstallingService=Installation du service Windows...
french.ServiceInstalled=Service Windows installé avec succès.
french.StartingService=Démarrage du service Windows...
french.ServiceStarted=Service Windows démarré avec succès.
french.SetupCompleted=Installation terminée avec succès.
french.ServiceDeletedSuccessfully=Service Windows supprimé avec succès.
french.ServiceDeleteFailed=Échec de la suppression du service Windows. Veuillez l'arrêter manuellement et réessayer.