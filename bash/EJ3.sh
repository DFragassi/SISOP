#!/bin/bash

cantParametrosIn=$#

ayuda() {
    echo "**************************  MENÚ DE AYUDA  **************************"
    echo " "
    echo "Sintaxis: -c nombre_directorio -s directorio_salida -a limpiar,compilar -h"
    echo " "
    echo "Parametros:"
    echo "-c     OBLIGAROIO. Ruta del directorio a monitorear."
    echo "-a     OBLIGATORIO. Lista de acciones separadas con coma a ejecutar. Listar, peso, publicar y compilar."
    echo "-s     Ruta del directorio utilizado por la accion "publicar" listada en -a, OBLIGATORIA si publicar."
    echo "-h     Ayuda sobre la sintaxis del script"
    echo "-?     Ayuda sobre la sintaxis del script"
    echo "--help Ayuda sobre la sintaxis del script"
    echo " "
    echo "************************ FIN DE MENÚ DE AYUDA  ***********************"
   
}

validarDirectorio() {
    if [ -z "$1" -o ! -d "$1" ] ; then
        echo "El directorio "$1" del parametro "$2" no es valido o es inexistente."
        if [ "$2" = "-s" ] && [ ! -z "$1" ] && [ "$1" != "-a" ] && [ "$1" != "-c" ]; then 
          flagSalida=1
        else  
          ayuda
          exit 1
        fi
    fi
    if [[ ! -r "$1" ]] ; then
      if [ "$flagSalida" -ne 1 ]; then
        echo "No tiene permisos de lectura sobre el directorio "$1"."
        exit 1
      fi
    fi
}
 
validarAcciones() {

  flagcomp=0;
  flagpub=0;

  if [ -z "$1" ]; then
   echo "Esta vacía la lista de -a." 
   exit
  fi

  IFS=',' read -r -a array <<< $1

  for element in "${array[@]}"
  do
      case "$element" in
      listar|peso)
        ;;
      publicar)
        flagpub=1
        ;;
      compilar)
        flagcomp=1
        ;;
      *)
        echo "La accion $element no pertenece."
        exit 1;
      esac
  done

  if [[ $flagpub -eq "1" ]] ; then
    if [[ $flagcomp != "1" ]]; then
      echo "No se puede publicar sin compilar"
      exit 1;
    fi
  fi
}

validarArchivo() {
    if [ -z "$1" -o ! -f "$1" -o ! -r "$1" ] ; then
        echo "El archivo no es valido o es inexistente"
        exit 1
    fi
    if [ ! -w "$1" ] ; then
        echo "No tiene permisos de escritura sobre el archivo "$1"."
        exit 1
    fi
}

acciones() {
      IFS=' '
      arch_act=$(echo "$1" | awk '{print $9}')
      peso_act=$(echo "$1" | awk '{print $5}')
      flagPublicar=0
      IFS=',' read -r -a array <<< $2

      for element in "${array[@]}" 
      do
          case "$element" in
          listar)
              echo "EL ARCHIVO $arch_act HA SUFRIDO CAMBIOS."                    
              ;;
          peso)
              echo "EL ARCHIVO $arch_act PESA: $peso_act" 
              ;; 
          compilar)
              compilarR "$3"
              ;;
          publicar)
              flagPublicar=1
              ;;
          esac
      done
  if [[ $flagPublicar -eq 1 ]]; then
    publicarR "$4"
  fi
}
compilarR() {
    if [ -z "./bin" -o ! -d "./bin" ] ; then
        ( mkdir ./bin )
    fi
    if [ -z "./bin/compilar.txt" -o ! -f "./bin/compilar.txt" -o ! -r "./bin/compilar.txt" ] ; then
      find "$1" -type f -name "*" -exec cat {} + >> ./bin/compilar.txt 2>/dev/null
    else
      ( rm "./bin/compilar.txt" )
      find "$1" -type f -name "*" -exec cat {} + >> ./bin/compilar.txt 2>/dev/null
    fi
}
publicarR() {
    if [ -z "./bin/compilar.txt" -o ! -f "./bin/compilar.txt" ] ; then
        echo "El archivo no es valido."
    else
        cp "./bin/compilar.txt" "$1"
    fi
}
  
daemon() {

  #find . -type f -exec ls -l {} +
  lista_estatica=$(find "$1" -type f -exec ls -l {} +)

  while true;
  do
      flag_elim_ren=0
      flag_nue=0

      lista_act=$(find "$1" -type f -exec ls -l {} +)
      IFS=$'\n'

      for line in $lista_act;do
          flag_nue=0

          for estatica in $lista_estatica;do
              if [ "$estatica" = "$line" ]; then
                  flag_nue=1;
              fi
          done 

          if [[ $flag_nue -eq "0" ]]; then 
            
            IFS=' '
            arch_act=$(echo "$line" | awk '{print $9}')
            if [ -n "$arch_act" ] ; then
                  if [ "$arch_act" != " " ] ; then
                      acciones "$line" "$3" "$1" "$2" 
                      lista_estatica=$(find "$1" -type f -exec ls -l {} +)
                  fi
            fi
          fi
          IFS=$'\n'
      done

      for lineEst in $lista_estatica; do
          flag_elim_ren=0

          for lineAct in $lista_act;do
              if [ "$lineAct" = "$lineEst" ]; then
                  flag_elim_ren=1 
              fi
          done

          if [[ $flag_elim_ren -eq "0" ]]; then 
              acciones "$lineEst" "$3" "$1" "$2" 
              lista_estatica=$(find "$1" -type f -exec ls -l {} +)
          fi
          IFS=$'\n'
      done

    sleep 1
  done
}

if [ $cantParametrosIn -eq 0 ] || [ $cantParametrosIn -gt 7 ] ; then
    echo "Cantidad de parametros invalida."
    ayuda
    exit 1
fi
flagDaemon=0
flagSalida=0
flagC=0
flagA=0
while [[ "$#" -gt 0 ]] 
do
  case "$1" in
    -c) 
    if [ "$flagDaemon" -eq 0 ]; then
      validarDirectorio "$2" "$1" #primero el path desp lel command
    fi
      flagC=1
      path_in="$2"
      shift 2 
      ;; 
    -s)
    if [ "$flagDaemon" -eq 0 ]; then
      validarDirectorio "$2" "$1" 
    fi
      path_out="$2" 
      shift 2
      ;;
    -a)
    if [ "$flagDaemon" -eq 0 ]; then
        validarAcciones "$2"
    fi
        flagA=1
        acciones="$2" #-a listar,peso,compilar,publicar
        shift 2 
      ;;
    -?|-h|--help)
      ayuda
      exit
      ;;
    --silent)
      flagDaemon=1
      shift
      ;;
    *)
      ayuda
      exit
      ;;
  esac
done

if [[ "$flagpub" -eq "1" ]]; then
  if [[ -z "$path_out" ]]; then
    echo "No se puede publicar sin una direccion."
    ayuda
    exit 1
  fi
fi
if [ "$flagC" -eq 0 ]; then
  echo "El parametro -c es inexistente."
  ayuda
  exit
fi
if [ "$flagA" -eq 0 ]; then
  echo "El parametro -a es inexistente."
  ayuda
  exit
fi
#MONITOREAR
listaProcesos=$(ps -aux | grep EJ3.sh | awk '{
    i = 15;
    flag = 0;
    while (i <= NF) {

      if ($i == "-a"){
        i=NF;
        printf "\n";
      }
      else {
        printf "%s ", $i;
      }
      i++;
    }
}')

 
#acá lo que hago es que el caracter delimitador sea - ya que hay un problema entre los espacios y \n entonces hago un tr

#listaProcesos=`echo $listaProcesos` #limpio los espacios de mas
#echo "$listaProcesos"
flagError=0
IFS=$'\n'
#path_in_aux=`echo $path_in | sed 's/ //g'`
path_in_aux=$(readlink -f "$path_in" 2>/dev/null | xargs )
#echo "PATH_IN_AUX:  $path_in_aux"
#echo "$path_in_aux"
for linea in $listaProcesos; do
  linea=$(readlink -f "$linea" 2>/dev/null | xargs )

  if [[ "$linea" == "$path_in_aux" ]]; then
    flagError=$((flagError+1))
  #else
    #echo "$linea VS $path_in_aux" DEBUG
  fi  
done

if [ $flagError -gt 2 ]; then
      echo "El directorio "$path_in" ya está siendo monitoreado. "
      exit 1
fi

if [ "$flagSalida" -eq "1" ]; then
  if [ "$flagpub" -eq "1" ]; then
      echo "Creacion del path "$path_out" para -s."
      mkdir "$path_out" 
  else
    echo "No se creará el directorio de salida ya que la opcion "publicar" no se encuentra en la lista."
  fi
fi

path_absoluto=$(readlink -f "$path_in" 2>/dev/null | xargs ) 
    
if [[ $flagDaemon -eq 0 ]]; then
  ./"$0" --silent -c "$path_absoluto" -a "$acciones" -s "$path_out" &
else
  daemon "$path_absoluto" "$path_out" "$acciones"
fi




