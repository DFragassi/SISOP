<#
.SYNOPSIS
TP2 - Ejercicio 2 - reorganiza archivos por extension que se agreguen a la ruta especificada a monitorizar

.DESCRIPTION
Cada vez que se agregue un archivo a la ruta especificada por parametro a monitorear,se moveran los archivos al directorio destino especificada por parametro dentro de un subdirectorio que tendra como nombre la extension del archivo o se copiara el archivo en caso de no poseer una extensión

.PARAMETER Descargas
Indicia el directorio a monitorear

.PARAMETER Destino
Indicia el directorio que contendra los subdirectorios "extensión".Si no se pasa valor para este parametro, el directorio destino sera el de "Descargas".

.PARAMETER Detener
Parametro tipo switch.Si esta presente, se debe detener la detección de archivos. No puede pasarse al mismo tiempo que otros parámetros.

#>

[CmdletBinding(DefaultParameterSetName="Start")]
Param(
    [Parameter(Mandatory=$True)] 
    [string]$c,

    [Parameter(Mandatory=$True)]
    [ValidateCount(1,4)]
    [ValidateSet("peso","listar","compilar","publicar")]
    [String[]]$a,

    # #Op. Backup
    [Parameter(Mandatory=$False)]
    [string]$s
)
$global:flagPub=0;
$global:flagComp=0;
$global:flagListar=0;
$global:flagPeso=0;

foreach($linea in $a){
   if($linea -eq "compilar"){
       $global:flagComp=1;
       if(!(Test-Path "./bin")){
            #creo el path si no existe    
            New-Item -Path "./bin" -ItemType directory | Out-Null
        }
   }
   if($linea -eq "publicar"){
      $global:flagPub=1;
   }
   if($linea -eq "listar"){
       $global:flagListar=1;
   }
   if($linea -eq "peso"){
       $global:flagPeso=1;
   }
}

if($global:flagPub -eq 1){
    if(!($global:flagComp -eq 1)){
        Write-Error ("No se puede publicar sin compilar. Intentelo nuevamente.");
    }
}


if(!$s -and $global:flagPub -eq 1){
    write-Error("No se puede publicar sin una direccion. Intentelo nuevamente.")
} else {
    if($global:flagPub -eq 1 -and $s){
        if(!(Test-Path  $s)){
            #creo el path si no existe    
            New-Item -Path $s -ItemType directory | Out-Null
        }

    }
}

#como obtener el path absoluto a monitorear, además valida que exista o no el path en -c:
$global:pathMonitorear = (Resolve-Path -Path "$c").Path;
if(!(Test-Path $c)){
    exit 1;
}

function Start-Watcher() {
  
  Get-EventSubscriber -SourceIdentifier  FilesWatcher -ErrorAction SilentlyContinue | Unregister-Event
   Get-EventSubscriber -SourceIdentifier  Changed -ErrorAction SilentlyContinue | Unregister-Event
    Get-EventSubscriber -SourceIdentifier  Deleted -ErrorAction SilentlyContinue | Unregister-Event
     Get-EventSubscriber -SourceIdentifier  Renamed -ErrorAction SilentlyContinue | Unregister-Event

  $watcher = New-Object IO.FileSystemWatcher
  $watcher.Path = Resolve-Path -Path $c
  $watcher.IncludeSubdirectories = $true
  $watcher.EnableRaisingEvents = $true
  # # Defino la acción a ejecutar al detectar un cambio
  $action = {
      
    # Información del cambio:
    $details = $event.SourceEventArgs
    $FullPath = $details.FullPath
    $OldFullPath = $details.OldFullPath
    $Name = $details.Name
    $OldName = $details.OldName
      
    # Tipo de cambio:
    $ChangeType = $details.ChangeType
      
     switch ($ChangeType)
            {
            'Changed'  { 
                 if($global:flagListar -eq 1){
                    $text = "El archivo {0} fue modificado." -f $Name
                    Write-Host $text -ForegroundColor Yellow
                 }
                 if($global:flagPeso -eq 1){
                    $text = "El archivo {0} pesa: {1} KB" -f $Name, ((Get-Item $FullPath).length/1KB)
                    Write-Host $text  -ForegroundColor Yellow
                 }
                 if($global:flagComp -eq 1){
                    Get-ChildItem -Path $global:pathMonitorear -Recurse | Get-Content | Out-File -FilePath ./bin/test.txt
                 }
                 if($global:flagPub -eq 1){
                      Copy-Item -Path ./bin/test.txt -Destination $global:pathSalida
                 }
            }
            'Created'  { 
                if($global:flagListar -eq 1){
                    $text = "El archivo {0} fue creado." -f $Name
                    Write-Host $text -ForegroundColor Yellow
                }
                if($global:flagPeso -eq 1){
                    $text = "El archivo {0} pesa: {1} KB" -f $Name, ((Get-Item $FullPath).length/1KB)
                    Write-Host $text  -ForegroundColor Yellow
                }
                if($global:flagComp -eq 1){
                    Get-ChildItem -Path $global:pathMonitorear -Recurse | Get-Content | Out-File -FilePath ./bin/test.txt
                 }
                 if($global:flagPub -eq 1){
                      Copy-Item -Path ./bin/test.txt -Destination $global:pathSalida
                 }
                    }   
            'Deleted'  { 
                 if($global:flagListar -eq 1){
                    $text = "El archivo {0} fue eliminado." -f $Name
                    Write-Host $text -ForegroundColor Yellow
                 }
                if($global:flagPeso -eq 1){
                    $text = "El archivo {0} pesa: {1} KB" -f $Name, ((Get-Item $FullPath).length/1KB)
                    Write-Host $text  -ForegroundColor Yellow
                }
                if($global:flagComp -eq 1){
                    Get-ChildItem -Path $global:pathMonitorear -Recurse | Get-Content | Out-File -FilePath ./bin/test.txt
                }
                if($global:flagPub -eq 1){
                      Copy-Item -Path ./bin/test.txt -Destination $global:pathSalida
                 }

            }
            'Renamed'  {
                if($global:flagListar -eq 1){
                    $text = "El archivo {0} fue renombrado a {1}" -f $OldName, $Name
                    Write-Host $text -ForegroundColor Yellow
                }
                 if($global:flagPeso -eq 1){
                    $text = "El archivo {0} pesa: {1} KB" -f $Name, ((Get-Item $FullPath).length/1KB)
                    Write-Host $text  -ForegroundColor Yellow
                }
                 if($global:flagComp -eq 1){
                    Get-ChildItem -Path $global:pathMonitorear -Recurse | Get-Content | Out-File -FilePath ./bin/test.txt
                }
                 if($global:flagPub -eq 1){
                      Copy-Item -Path ./bin/test.txt -Destination $global:pathSalida
                 }
            }
            default   { }
            }
   
  }
  
  #Me suscribo a los eventos que necesito

  Register-ObjectEvent -InputObject $watcher -EventName Created  -Action $action -SourceIdentifier FilesWatcher
  Register-ObjectEvent -InputObject $watcher -EventName Changed  -Action $action -SourceIdentifier Changed
  Register-ObjectEvent -InputObject $watcher -EventName Renamed  -Action $action -SourceIdentifier Renamed
  Register-ObjectEvent -InputObject $watcher -EventName Deleted  -Action $action -SourceIdentifier Deleted

  Write-Warning "Monitoreando cambios en $global:pathMonitorear"
}

function Stop-Watcher() {
  # this gets executed when user presses CTRL+C:
    
  Remove-Variable -Name c -Scope global -ErrorAction SilentlyContinue
  Remove-Variable -Name a -Scope global -ErrorAction SilentlyContinue
  Remove-Variable -Name s -Scope global -ErrorAction SilentlyContinue
  exit
}

try{
    if ($c) {
    Start-Watcher
    }
}
finally
{
  Stop-Watcher
  
}

