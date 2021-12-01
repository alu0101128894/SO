#!/bin/bash

## ./sysinfo - u root -> funcion crear que muestre los procesos del usuario ordenados por CPU

##### Funciones

TITLE="Información del sistema para $HOSTNAME"
RIGHT_NOW=$(date +"%x %r%Z")
TIME_STAMP="Actualizada el $RIGHT_NOW por $USER"

TEXT_ULINE=$(tput sgr 0 1)
TEXT_RESET=$(tput sgr0)

system_info()
{
   echo
   echo "${TEXT_ULINE}Versión del sistema${TEXT_RESET}" 
   uname -a
}

show_uptime()
{
   echo
   echo "${TEXT_ULINE}Tiempo de encendido del sistema${TEXT_RESET}"
   uptime
}

drive_space()
{
   echo
   echo "${TEXT_ULINE}Espacio en el sistema de archivos${TEXT_RESET}"
   df # -h para MB (forma humana)
}

home_space()
{
   if [ "$USER" = "root" ]; then # Solamente para el superusuario
        echo    
        echo "${TEXT_ULINE}Espacio en home por usuario${TEXT_RESET}"
        echo "Bytes Directorio"
        du -s /home/* | sort -nr # -s para bytes si queremos para mas "humanos" = -hs (saldrá en MB)
   fi
}

root() 
{  
   if [ "$USER" = "root" ]; then
      echo
      echo "${TEXT_ULINE}Procesos del usuario ordenados por CPU${TEXT_RESET}"
      ps -e | sort
   fi
}

usage()
{
    echo "usage: 'fichero.sh' -u root (muestra solo la funcion root)" # comando a usar -> ./while_casos_semana4_practicar.sh -f fichero.txt
    echo "usage2: 'fichero.sh' -t (muestra todos los mensajes)"
}

write_page()
{
   cat << _EOF_

      $TEXT_BOLD$TITLE$TEXT_RESET
      $(system_info)
      $(show_uptime)
      $(drive_space)
      $(home_space)
      $(root)
      $TEXT_GREEN$TIME_STAMP$TEXT_RESET

_EOF_
}
# Procesar la línea de comandos del script para leer las opciones
while [ "$1" != "" ]; do
   case $1 in

      -u | --root )
         root
         write_page > root
         exit
         ;;

      -t | -todo )
         write_page
         exit
         ;;

      -h | --help )
             usage
             exit
             ;;
         
      * )
         usage
         exit 1
   esac
   shift
done




