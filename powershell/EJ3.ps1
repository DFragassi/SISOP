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
foreach($linea in $a){
    write-host $linea
}
