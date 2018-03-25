
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

. $scriptDir\LoadEnvironment.ps1 'pf_367.dnndev' 'DNN_Platform_9.2.0.367-778_Install'

#Create-Database "pf_12_8_2017_701pm_db" "pf_12_8_2017_701pm_adm" "admpws"

