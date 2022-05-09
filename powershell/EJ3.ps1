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

$flagPub=0;
$flagComp=0;

foreach($linea in $a){
   if($linea -eq "compilar"){
       $flagComp=1;
   }
   if($linea -eq "publicar"){
       $flagPub=1;
   }
}

if($flagPub -eq 1){
    if(!($flagComp -eq 1)){
        Write-Error ("No se puede publicar sin compilar. Intentelo nuevamente.");
    }
}


if(!$s -and $flagPub -eq 1){
    write-Error("No se puede publicar sin una direccion. Intentelo nuevamente.")
} else {
    if($flagPub -eq 1 -and $s){
        if(!(Test-Path  $s)){
            #creo el path si no existe    
            New-Item -Path $s -ItemType directory | Out-Null
        }
    }
}

#como obtener el path absoluto:
#$pathMonitorear = (Resolve-Path -Path "$c").Path;



