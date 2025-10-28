@echo off && goto PreCheck
<# �R�}���h�v�����v�g----------------------------------
  :PreCheck
     setlocal
       for /f "tokens=3 delims=\ " %%A in ('whoami /groups^|find "Mandatory Label"') do set LEVEL=%%A
       if not "%LEVEL%"=="High"  goto GETadmin
     goto Excute
  :GETadmin
     endlocal
     echo "%~nx0": elevating self
     echo    Are you OK ?
     del "%temp%\getadmin.vbs"                                    2>NUL
       set vbs=%temp%\getadmin.vbs
       echo Set UAC = CreateObject^("Shell.Application"^)          >> "%vbs%"
       echo Dim stCmd                                              >> "%vbs%"
       echo stCmd = "/c """"%~s0"" " ^& "%~dp0" ^& Chr(34)         >> "%vbs%"
       echo UAC.ShellExecute "cmd.exe", stCmd, "", "runas", 1      >> "%vbs%"
       pause
       "%temp%\getadmin.vbs"
     del "%temp%\getadmin.vbs"
     goto :eof
  :Excute
     endlocal
     set "Dir=%~1"
     powershell -NoProfile -ExecutionPolicy Unrestricted "$s=[scriptblock]::create((gc \""%~f0"\"|?{$_.readcount -gt 1})-join\"`n\");&$s" "'%Dir%'" &exit /b
-------------------------------------------------------#>
  Param([string] $SptDirPATH)
  write-host "Script Start......`($SptDirPATH`)"
####################################
###   Powershell Script HERE!!   ###
####################################
<# �o�b�t�@�[�T�C�Y�̒��� #>
# WindowSize �̊���l��ϐ��Ɋi�[
$defaultWS = $host.UI.RawUI.WindowSize

# BufferSize �� 140 �ɕύX
(Get-Host).UI.RawUI.BufferSize `
   = New-Object "System.Management.Automation.Host.Size" (140,$host.UI.RawUI.BufferSize.Height)

# WindowSize �͊���l�ɐݒ�
$host.UI.RawUI.WindowSize = $defaultWS


<# 0 #>
# ���łɐݒ肳��Ă���A�_�v�^�[�̊m�F
$0VMName = (Read-Host �A�_�v�^�[��ǉ�����VM������͂��Ă�������)

# �Z�b�g����VM�����݂��邩�m�F
$VMall = Get-VM
$VMalls = $VMall.Name | Out-String -Stream
# ��������
if ($VMalls.Contains("$0VMName"))
  {Write-Host �v���Z�X��i�߂܂�}
Else
  {# ���͂��ꂽ�l�� �s�K��
   Write-Output (@"
VM��: "$0VMName" ��������܂���ł����B
�����L�[����͂��A�^�X�N���I�����܂�...
"@)
   $host.UI.RawUI.ReadKey() | Out-Null
   exit
   } 

# ���łɐݒ肳��Ă���A�_�v�^�[�̍폜
$ErrorActionPreference = 'Stop'
try {
    Remove-VMGpuPartitionAdapter -VMName "$0VMName"
    ""
    Write-Host "����VM�ɐݒ肳��Ă���GPU-Partition���폜����܂���"
} catch {
    ""
    Write-Host "����VM��GPU-Partition�͐ݒ肳��Ă��܂���"
}
$ErrorActionPreference = "Continue"


<# 1 #>
# ���[�U�[������͂��󂯕t���ē��͓��e�� $percent �Ɋi�[
""
Write-Host "�������l����͂��Ă�������"
[int]$1percentMIN =(Read-Host "MIN�F��������ŏ��̗ʂ���͂��Ă��������i%:  0�`100�j")
[int]$1percentMAX =(Read-Host "MAX�F��������ő�̗ʂ���͂��Ă��������i%:MIN�`100�j")
[int]$1percentOPT =(Read-Host "OPT�F��������œK�̗ʂ���͂��Ă��������i%:MIN�`MAX�j")

# ��������
if (($1percentMIN -ge 0) -and
    ($1percentMIN -le 100) -and

    ($1percentMAX -ge 1) -and
    ($1percentMAX -ge ($1percentMIN)) -and
    ($1percentMAX -le 100) -and

    ($1percentOPT -ge 1) -and
    ($1percentOPT -ge $1percentMIN) -and
    ($1percentOPT -le ($1percentMAX))){
	# �����iif,else���ꂼ�ꉽ������K�v�j
    Write-Host �v���Z�X��i�߂܂�
}Else{
    # ���͂��ꂽ������ �s�K��
    Write-Host ���͂��ꂽ�������s�K�؂ł��B�����𒆒f���܂��B
    Write-Host "���s����ɂ͉����L�[�������Ă�������..."
    $host.UI.RawUI.ReadKey() | Out-Null
    exit
}


<# 2 #>
# �C���X�^���X�p�X�AGPU���A�ϐ������擾����

[int]$Count = (Get-VMHostPartitionableGpu).Count

# �ڑ�����Ă��� GPU �̐��ŕ���
If($Count -ge 2) {
   (Get-VMHostPartitionableGpu).Name `
      | ForEach-Object `
           -Begin { 
              # �ϐ���������
              Remove-Variable Add, Sub, End 2>${NULL}
              # �ϐ���錾�A�����A�ݒ�
              $Space = ($Host.UI.RawUI.WindowSize.Width - 11)
              [Array]$Sub = [System.Management.Automation.Host.ChoiceDescription]::new("(&���������)", "����")
              $Name_HashTable = [Ordered]@{}
              [int]$Num = 1
             } `
           -Process { 
             # PnP Util �Ŏg����悤�ɒ���
              $InsID = ($_ -split '\\?\',0,'Simplematch' -split '#{')[1].Replace('#','\')
              Set-Variable "2InsID$Num" "$InsID"
             # PnP Util ���� GPU�� ���擾
              $GPUName = (Get-PnpDevice -InstanceId $InsID).FriendlyName
              Set-Variable "Name$Num" "$GPUName"
             # PromptForChoice �̑I����������
              $One = "$GPUName(&$Num)"
              $CRLF = $One.PadRight($Space)+"`b"
              [Array]$Add = [System.Management.Automation.Host.ChoiceDescription]::new("$CRLF", "$_")
             # ���[�v�̍Ō�Ƃ���ȊO�ŕ���
              If($Num -ne $Count)
                {$Sub = @($Sub;$Add)}
              Else 
                {$CRLF = $One.PadRight($Space*2)+"`b"
                 $Sub = @($Sub;[System.Management.Automation.Host.ChoiceDescription]::new("$CRLF", "$_`r`n`b"))}
             # GPU-P �p�̃C���X�^���X�p�X���i�[
              $Name_HashTable.Add("$Num","$_")
              $Num += 1
             } `
           -End { 
             # ���܂����̑I�����̒ǉ�
              [Array]$End = [System.Management.Automation.Host.ChoiceDescription]::new("�w�肵�Ȃ�(&$Num)`r`n`b", "�V�X�e���ɔC���܂��B`r`n`r`n`b")
              $Sub = @($Sub;$End)
             }

  # PromptForChoice �Ŏ��s������̂�ݒ�
   1..($Num-1) | ForEach-Object `
                    -Begin { $Options = @('{') } `
                    -Process { 
                       $Arg1 = (Get-Variable "Name$_").Value
                       $Arg2 = $Name_HashTable["$_"]
                       $Options += "$_ `{Write-Host `"$Arg1 ���I������܂���`" ;`$AGPUName = `"$Arg1`" ;`$2gpuNAME = `"$Arg2`" ;break `};" 
                      } `
                    -End { $Options += @('}') }
  # �I��������ʕ\��
   $Result = $Host.UI.PromptForChoice("�y�m�F�z","--�ԍ���I�сA���͂��Ă�������--`r`n�@",$Sub,$Num)
  # �I���ɉ������R�}���h�����s
   If($Result -ne $Num)
     {. ([Scriptblock]::Create("switch ($Result) $Options"))}
}

# GPU ��1�� ���� ���܂��� �ɂ����ꍇ�Ɏ��s����
If(!($Count -ge 2) -OR ($Result -eq $Num)) {
   Write-Host "GPU�������ɃZ�b�g���܂�"
   $2gpuNAME `
      = ( Get-VMHostPartitionableGpu `
             | Select-Object Name `
             | Get-Member -Membertype NoteProperty `
             | Select-Object Definition `
             | Format-Table -AutoSize -Wrap `
             | Out-String -Stream `
             | Select-String string `
         )  -replace "string Name="

   # GPU�����擾
   $2InsID = ($2gpuNAME -split '\\?\',0,'Simplematch' -split '#{')[1].Replace('#','\')
   $AGPUName = (Get-PnpDevice -InstanceId $2InsID).FriendlyName
}

# �擾�������e��\��
""
Write-Host (@"
$0VMName ��
GPU : $2gpuNAME
�i��$AGPUName�j
�� GPU-Partition �Ƃ��ēK�p���܂�
"@)
""


<# 3 #>
# Get-VMHostPartitionableGpu���犄�蓖�Ă���GPU�̑��ʂ��擾
$3gpuAvailableVRAM = Get-VMHostPartitionableGpu | Out-String -Stream | Select-String AvailableVRAM
$3gpuAvailableEncode = Get-VMHostPartitionableGpu | Out-String -Stream | Select-String AvailableEncode
$3gpuAvailableDecode = Get-VMHostPartitionableGpu | Out-String -Stream | Select-String AvailableDecode
$3gpuAvailableCompute = Get-VMHostPartitionableGpu | Out-String -Stream | Select-String AvailableCompute


# GPU�̊e���ʂ����ꂼ�ꕶ����Ƃ��Ċi�[
$3gpuAvailableVRAMStr = [String]$3gpuAvailableVRAM -replace "^[a-zA-Z]+ +: ([0-9]+).+$", "`$1"
$3gpuAvailableEncodeStr = [String]$3gpuAvailableEncode -replace "^[a-zA-Z]+ +: ([0-9]+).+$", "`$1"
$3gpuAvailableDecodeStr = [String]$3gpuAvailableDecode -replace "^[a-zA-Z]+ +: ([0-9]+).+$", "`$1"
$3gpuAvailableComputeStr = [String]$3gpuAvailableCompute -replace "^[a-zA-Z]+ +: ([0-9]+).+$", "`$1"


# GPU�̊e���ʂ����ꂼ�ꐔ�l�Ƃ��Ċi�[
$3gpuAvailableVRAMA = [System.Int32]::Parse($3gpuAvailableVRAMStr)
$3gpuAvailableEncodeA = [System.Decimal]::Parse($3gpuAvailableEncodeStr)
$3gpuAvailableDecodeA = [System.Int32]::Parse($3gpuAvailableDecodeStr)
$3gpuAvailableComputeA = [System.Int32]::Parse($3gpuAvailableComputeStr)


<# 4 #>
# LOG �̕ۑ���f�B���N�g�����쐬
$DIRpath=$SptDirPATH.TrimEnd('\') + "\LOG"
if ( -not ( Test-Path -Path "$DIRpath" )){ New-Item "$DIRpath" -ItemType Directory > $null }
Get-Date | Out-String -Stream | ?{$_ -ne ""} | Out-File "$DIRpath\GPU-P_log.txt" -Append -Force


<# 5 #>
# �p�[�e�B�V���������l�����߂�
$VRAMdivideMIN = [Math]::Round($($3gpuAvailableVRAMA * ($1percentMIN / 100)),0)
$VRAMdivideMAX = [Math]::Round($($3gpuAvailableVRAMA * ($1percentMAX / 100)),0)
$VRAMdivideOPT = [Math]::Round($($3gpuAvailableVRAMA * ($1percentOPT / 100)),0)

$ENCODEdivideMIN = [Math]::Round($($3gpuAvailableEncodeA * ($1percentMIN / 100)),0)
$ENCODEdivideMAX = [Math]::Round($($3gpuAvailableEncodeA * ($1percentMAX / 100)),0)
$ENCODEdivideOPT = [Math]::Round($($3gpuAvailableEncodeA * ($1percentOPT / 100)),0)

$DECODEdivideMIN = [Math]::Round($($3gpuAvailableDecodeA * ($1percentMIN / 100)),0)
$DECODEdivideMAX = [Math]::Round($($3gpuAvailableDecodeA * ($1percentMAX / 100)),0)
$DECODEdivideOPT = [Math]::Round($($3gpuAvailableDecodeA * ($1percentOPT / 100)),0)

$COMPUTEdivideMIN = [Math]::Round($($3gpuAvailableComputeA * ($1percentMIN / 100)),0)
$COMPUTEdivideMAX = [Math]::Round($($3gpuAvailableComputeA * ($1percentMAX / 100)),0)
$COMPUTEdivideOPT = [Math]::Round($($3gpuAvailableComputeA * ($1percentOPT / 100)),0)


# �v�Z���ʂ�\������
$5VRAMdisplay = [pscustomobject]([ordered]@{"------VRAM------" = ""; MIN = " $VRAMdivideMIN"; OPT = " $VRAMdivideOPT"; MAX = " $VRAMdivideMAX"; Available = " $3gpuAvailableVRAMA";})
$5ENCODEdisplay = [pscustomobject]([ordered]@{"-----Encode-----" = ""; MIN = " $ENCODEdivideMIN"; OPT = " $ENCODEdivideOPT"; MAX = " $ENCODEdivideMAX"; Available = " $3gpuAvailableEncodeA";})
$5DECODEdisplay = [pscustomobject]([ordered]@{"-----Decode-----" = ""; MIN = " $DECODEdivideMIN"; OPT = " $DECODEdivideOPT"; MAX = " $DECODEdivideMAX"; Available = " $3gpuAvailableDecodeA";})
$5COMPUTEdisplay = [pscustomobject]([ordered]@{"-----Compute----" = ""; MIN = " $COMPUTEdivideMIN"; OPT = " $COMPUTEdivideOPT"; MAX = " $COMPUTEdivideMAX"; Available = " $3gpuAvailableComputeA";})

""
Write-Host "# confimation"

Write-Output "VM  : $0VMName" | Out-File "$DIRpath\GPU-P_log.txt" -Append
Write-Output "GPU : $GPUName" | Out-File "$DIRpath\GPU-P_log.txt" -Append
Write-Output "Instance ID A : $2InsID" | Out-File "$DIRpath\GPU-P_log.txt" -Append
Write-Output "Instance ID B : $2gpuNAME" | Out-File "$DIRpath\GPU-P_log.txt" -Append

$5VRAMdisplay | Out-String -Stream | ?{$_ -ne ""} | Tee-Object -FilePath "$DIRpath\GPU-P_log.txt" -Append
$5ENCODEdisplay | Out-String -Stream | ?{$_ -ne ""} | Tee-Object -FilePath "$DIRpath\GPU-P_log.txt" -Append
$5DECODEdisplay | Out-String -Stream | ?{$_ -ne ""} | Tee-Object -FilePath "$DIRpath\GPU-P_log.txt" -Append
$5COMPUTEdisplay | Out-String -Stream | ?{$_ -ne ""} | Tee-Object -FilePath "$DIRpath\GPU-P_log.txt" -Append

""
Write-Host "�����O�̏o�͐�� `"$DIRpath\GPU-P_log.txt`""

Write-Output "" | Out-File "$DIRpath\GPU-P_log.txt" -Append -Force
Write-Output "" | Out-File "$DIRpath\GPU-P_log.txt" -Append -Force


<# 6 #>
# ���s���邩�m�F
$title = "�y�m�F�z"
$message = @"
��L�̒ʂ��GPUPartition���Z�b�g���܂��B
���̑�������s���܂���?
"@

$tChoiceDescription = "System.Management.Automation.Host.ChoiceDescription"
$tOptions = @(
    New-Object $tChoiceDescription ("�͂�(&Yes)",     "���̑�������s���A���̃X�e�b�v�֐i�݂܂��B")
    New-Object $tChoiceDescription ("������(&No)",    "���̑�����L�����Z�����A���f���܂��B")
)

$tResult = $host.ui.PromptForChoice($title, $message, $tOptions, 0)
switch ($tResult)
  {
    0 {"�u�͂��v���I�΂�܂����B"; break}
    1 {"�u���f�v���I�΂�܂����B"; break}
  }

if ($tResult -ne 0) { exit }


<# 7 #>
# GPU-P.Adapter��ǉ�����
If(!($Count -ge 2) -OR ($Result -eq $Num)) {
   # �V�X�e�����w��
   Add-VMGpuPartitionAdapter -VMName "$0VMName"
}Else{
   # GPU���w�肷��ꍇ
   Add-VMGpuPartitionAdapter -VMName "$0VMName" -InstancePath "$2gpuNAME"
}

# �ǉ������A�_�v�^�[��ݒ肷��
#VRAM
Set-VMGpuPartitionAdapter -VMName "$0VMName" -MinPartitionVRAM $VRAMdivideMIN
Set-VMGpuPartitionAdapter -VMName "$0VMName" -MaxPartitionVRAM $VRAMdivideMAX
Set-VMGpuPartitionAdapter -VMName "$0VMName" -OptimalPartitionVRAM $VRAMdivideOPT

#Encode
Set-VMGpuPartitionAdapter -VMName "$0VMName" -MinPartitionEncode $ENCODEdivideMIN
Set-VMGpuPartitionAdapter -VMName "$0VMName" -MaxPartitionEncode $ENCODEdivideMAX
Set-VMGpuPartitionAdapter -VMName "$0VMName" -OptimalPartitionEncode $ENCODEdivideOPT

#Decode
Set-VMGpuPartitionAdapter -VMName "$0VMName" -MinPartitionDecode $DECODEdivideMIN
Set-VMGpuPartitionAdapter -VMName "$0VMName" -MaxPartitionDecode $DECODEdivideMAX
Set-VMGpuPartitionAdapter -VMName "$0VMName" -OptimalPartitionDecode $DECODEdivideOPT

#Compute
Set-VMGpuPartitionAdapter -VMName "$0VMName" -MinPartitionCompute $COMPUTEdivideMIN
Set-VMGpuPartitionAdapter -VMName "$0VMName" -MaxPartitionCompute $COMPUTEdivideMAX
Set-VMGpuPartitionAdapter -VMName "$0VMName" -OptimalPartitionCompute $COMPUTEdivideOPT


<# 8 #>
# CPU Write-Combining�̗L����
Set-VM -GuestControlledCacheTypes $true -VMName "$0VMName"

# MMIO�̈�̍\��
Set-VM -LowMemoryMappedIoSpace 1Gb -VMName "$0VMName"
Set-VM -HighMemoryMappedIoSpace 33280Mb -VMName "$0VMName"


<# 9 #>
# �m�F�i = Get-VMGpuPartitionAdapter "$0VMName" -verbose �j
Get-VMGpuPartitionAdapter -VMName "$0VMName"

# �I�����b�Z�[�W
Write-Host "���ׂẴv���Z�X�͏I�����܂���"
####################################
###            FINISH            ###
####################################
  Write-Host "---Script Finish---"
  Write-Host "��ʂ����ɂ͉����L�[�������Ă�������..."
  $host.UI.RawUI.ReadKey() | Out-Null
  EXIT