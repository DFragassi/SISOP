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
$global:pathSalida = $s;
$Path = $global:pathMonitorear;
$FileFilter = '*'  
$IncludeSubfolders = $true
$AttributeFilter = [IO.NotifyFilters]::FileName, [IO.NotifyFilters]::LastWrite 

try
{
  $watcher = New-Object -TypeName System.IO.FileSystemWatcher -Property @{
    Path = $Path
    Filter = $FileFilter
    IncludeSubdirectories = $IncludeSubfolders
    NotifyFilter = $AttributeFilter
  }
        $action = {
            $details = $event.SourceEventArgs
            $Name = $details.Name
            $FullPath = $details.FullPath
            $OldFullPath = $details.OldFullPath
            $OldName = $details.OldName
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
   
        $handlers = . {
            Register-ObjectEvent -InputObject $watcher -EventName Changed  -Action $action 
            Register-ObjectEvent -InputObject $watcher -EventName Created  -Action $action 
            Register-ObjectEvent -InputObject $watcher -EventName Deleted  -Action $action 
            Register-ObjectEvent -InputObject $watcher -EventName Renamed  -Action $action 
        }
    
    
  # monitoring starts now:
  $watcher.EnableRaisingEvents = $true
  Write-Host "Esperando cambios en $Path."

  do
  {
    Wait-Event -Timeout 1
  } while ($true)
}

finally
{
  # this gets executed when user presses CTRL+C:
  
  # stop monitoring
  $watcher.EnableRaisingEvents = $false
  
  # remove the event handlers
  $handlers | ForEach-Object {
    Unregister-Event -SourceIdentifier $_.Name
  }

  $handlers | Remove-Job
  
  $watcher.Dispose()
  
  Write-Warning "El monitoreo ha terminado."
}