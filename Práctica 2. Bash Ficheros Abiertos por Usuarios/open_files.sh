# Universidad de La Laguna
# Escuela Superior de Ingeniería y Tecnología
# Grado en Ingeniería Informática
# Curso: 2º
# Práctica de BASH Ficheros Abiertos por Usuarios
# Autor: José Javier Díaz González
# Fecha: 28-11-2020

#!/bin/bash

#Constantes
TITLE="Script open_file"

#Variables

NOMBRE=
NUMERO_FICHEROS_ABIERTOS=
UUID=
PID_PROCESO_MAS_ANTIGUO=
NUMERO_FICHEROS_ABIERTOS_PATRON=
patron=
valor=
valor_entrada=
size=
valor_parametros=
cadenas_valores=
size_1=
size_2=
zero=0

##### Estilos

TEXT_BOLD=$(tput bold)

TEXT_GREEN=$(tput setaf 2)
TEXT_YELLOW=$(tput setaf 3)
TEXT_MAGENTA=$(tput setaf 5)
TEXT_BLUE=$(tput setaf 14)
TEXT_RESET=$(tput sgr0)
TEXT_RED=$(tput setaf 1)

#Funciones

PROGNAME=$(basename $0)

# comprobar si el lsof está instalado
comprobar_lsof() 
{
  if [ $(which lsof) ]; then

    echo "El comando$TEXT_BLUE lsof$TEXT_RESET está instalado. OK"
    else
      error_exit $TEXT_BOLD$TEXT_RED"No existe el comando lsof!"$TEXT_RESET
	fi
}


usuarios_who() # ./open_files.sh
{ 
  echo ""
  echo "Usuarios de who:"
  echo $TEXT_BOLD$TEXT_GREEN"NOMBRE  |  NUMERO_FICHEROS_ABIERTOS  |  UID  |  PID_PROCESO_MAS_ANTIGUO"$TEXT_RESET
  for usuario in $(who | awk '{ print $1 }' | sort -u ); do    # usuarios conectados (recorremos el for)  # -u = unique (sin duplicados)

    NOMBRE=$usuario                                         # Usuario
    NUMERO_FICHEROS_ABIERTOS=$(lsof -w -u $usuario | wc -l)    # Numero ficheros abiertos (wc = word counter) -l (lineas)
    UUID=$(ps -u $usuario --no-headers -o uid | head -n1)   # UID + quitamos warnings por el fuse (por si acaso)
    PID_PROCESO_MAS_ANTIGUO=$(ps -u $usuario --no-headers -o pid | head -n1) # Procesos más antiguos

    echo " $NOMBRE              $NUMERO_FICHEROS_ABIERTOS                $UID        $PID_PROCESO_MAS_ANTIGUO"
  done
  echo ""
}

archivo_patron () # ./open_files.sh -f .ttf
{
  echo "Extensión a usar: $patron"
  echo ""
  echo "Filtrar por patrón:"
  echo $TEXT_BOLD$TEXT_GREEN"NOMBRE  |  NUMERO_FICHEROS_ABIERTOS  |  UID  |  PID_PROCESO_MAS_ANTIGUO"$TEXT_RESET
  for usuario in $(who | awk '{ print $1 }' | sort -u ); do 

    NOMBRE=$usuario
    NUMERO_FICHEROS_ABIERTOS_PATRON=$(sudo lsof -w -u $usuario | awk '{ print $9 }' | grep -h $patron | wc -l)    # ultimo campo es el 9 (name) + grep (mostrar solo la cadena que tengo (patron))
    UUID=$(ps -u $usuario --no-headers -o uid | head -n1)                                                          # la siguientes cuentas de otro usuario = sudo
    PID_PROCESO_MAS_ANTIGUO=$(ps -u $usuario --no-headers -o pid | head -n1)                                       # -h elimina el prefijo 

    echo " $NOMBRE                $NUMERO_FICHEROS_ABIERTOS_PATRON                $UID        $PID_PROCESO_MAS_ANTIGUO"
   done
   echo ""
}

usuarios_no_conectados () # ./open_files.sh -o
{
  echo $TEXT_BOLD$TEXT_GREEN"NOMBRE_OFF | NUMERO_FICHEROS_ABIERTOS | UID | PID_PROCESO_MAS_ANTIGUO"$TEXT_RESET
   echo ""
  for usuario in $(ps -A --no-headers -o user | sort -u); do  # -a (all) todos los usuarios y no duplicados
    valor=0
  
		for usuarios_conectados in $(who | awk '{ print $1 }'); do  # recorremos para usuarios conectados
			if [ "$usuario" == "$usuarios_conectados" ]; then
				valor=1					# usuarios conectados tiene valor 1
			fi					
		done

    if [ "0" = "$valor" ]; then # los no conectados = 0
      NOMBRE=$usuario                                         # Usuario
      NUMERO_FICHEROS_ABIERTOS=$(lsof -w -u $usuario | wc -l)    # Numero ficheros abiertos (wc = word counter)
      UUID=$(ps -w -u $usuario --no-headers -o uid | head -n1)   # UID + quitamos warnings por el fuse (por si acaso)
      PID_PROCESO_MAS_ANTIGUO=$(ps -u $usuario --no-headers -o pid | head -n1) # Procesos más antiguos
      
      echo "$TEXT_MAGENTA$NOMBRE$TEXT_RESET  $NUMERO_FICHEROS_ABIERTOS   $UID$PID_PROCESO_MAS_ANTIGUO"
		fi
	done
  echo ""
}
filtra_usuario () # ./open_files.sh -u javi (etc)
{
  valor_entrada=0
  while [ "$valor_entrada" -lt $size ]; do              #   valor que entra < tparametro- 2   (- u javi pepito -f .ttf (me quita el -f y .ttf )  
    echo $TEXT_YELLOW"Usuario:$TEXT_RESET" ${valor_parametros[valor_entrada]}
    echo $TEXT_YELLOW"NUMERO DE PROGRAMAS: $TEXT_RESET$(sudo lsof -w -u ${valor_parametros[valor_entrada]} | awk '{ print $9 }' | grep -h $cadenas_valores | wc -l )"
    valor_entrada=$(($valor_entrada + 1)) # valor_entrada++

    echo ""
  done

}


usage()
{
  echo $TEXT_BOLD$TEXT_GREEN"-h | --help"$TEXT_RESET 
	echo "	./open_files $TEXT_BLUE[-h][--help]$TEXT_RESET"
	echo "	Comando de ayuda que trae este práctica"

  echo $TEXT_BOLD$TEXT_GREEN"-f | --filtro ['.*filtro'] "$TEXT_RESET
	echo "	./open_files $TEXT_BLUE[-f] | [--filtro] '.*filtro'$TEXT_RESET"
	echo "	Se mostrará para filtrar la salida de lsof en base a la última columna"

  echo $TEXT_BOLD$TEXT_GREEN"-o | --offline"$TEXT_RESET
	echo "	./open_files $TEXT_BLUE[-o][--offline]$TEXT_RESET"
	echo "	Se mostrará la información de usuarios falsos y que no esten conectados en el sistema."

  echo $TEXT_BOLD$TEXT_GREEN"-u | --user"$TEXT_RESET
  echo " --> Existen$TEXT_BOLD$TEXT_MAGENTA 4 formas$TEXT_RESET para ejecutar el comando:"
  echo ""
	echo "	./open_files $TEXT_BLUE[-u][--user] (Nombre_Usuario_X)$TEXT_RESET"
  echo "	./open_files $TEXT_BLUE[-u][--user] (Nombre_Usuario_1), ... , (Nombre_Usuario_N)$TEXT_RESET"
	echo "	Se mostrará la información de lsof para aquellos archivos abiertos por los usuario especificados en la opción -u."
  echo ""
  echo "	./open_files $TEXT_BLUE[-u][--user] (Nombre_Usuario_X) -f ('.*filtro')$TEXT_RESET"
  echo "	./open_files $TEXT_BLUE[-u][--user] (Nombre_Usuario_1), ... , (Nombre_Usuario_N) -f ('.*filtro')$TEXT_RESET"
  echo "	Se mostrará la información para aquellos archivos terminados en 'sh' que además hayan sido abiertos por el usuario especificado."
  
  echo ""
}

error_exit()
{
#        --------------------------------------------------------------
#        Función para salir en caso de error fatal
#        --------------------------------------------------------------
  echo "./${PROGNAME}: ${1:-"Error desconocido. Revise de nuevo!" }" 1>&2
  #exit 1
}

funcion_error()
{
  
  echo $TEXT_BOLD$TEXT_RED"Introduzca una opción VALIDA!"$TEXT_RESET
  error_exit  # salida exit
  echo ""
  echo $TEXT_BOLD$TEXT_YELLOW"Mensaje de ayuda automática" $TEXT_RESET
  echo ""
  usage 
  exit 1
  
}

# Sin parametros = open_file
echo $TEXT_BOLD$TITLE$TEXT_RESET
echo ""

while [ "$1" != "" ]; do

  case $1 in
    -h | --help )  

      if [ "$#" = "1" ]; then   # = 1 -> se muestra el usage
        usage
        else    #  > 2 -> error
          echo "--> Has puesto 2 parametros de más." $TEXT_RED"Error"$TEXT_RESET
          echo ""
          funcion_error
      fi
      exit 0
    ;;
  
    -f | --filtro )     

      if [ "$#" != "2" ]; then ## = 2 parametros
        echo "--> Has puesto 3 parametros de más." $TEXT_RED"Error"$TEXT_RESET
        echo ""
        funcion_error
        else
          shift
          patron=$1
          archivo_patron
      fi
      exit 0
    ;;

    -o | --offline  )
    
      if [ "$#" = "1" ]; then  # = 1 -> usuarios no conectados
        usuarios_no_conectados
        else 
        echo "--> Has puesto 2 parametros de más." $TEXT_RED"Error"$TEXT_RESET
        echo ""
        funcion_error
      fi
      exit 0
    ;;
           
    -u | --user )

      if  [ "$#" = "1" ]; then 
        echo "--> Has puesto 1 parametro." $TEXT_RED"Error"$TEXT_RESET
        echo ""
        funcion_error                
      fi

      shift
        
      valor_entrada=0
      size_1=$#   # parametros
      size_2=$#   # reseteamos parametros 2
      size=$(($# - 2)) # el valor del paramentro - 2 (otros casos)
      
      if [ "$#" -le "2" ]; then # menor igual   ./open_file.sh -u javi root
        echo $TEXT_BOLD$TEXT_GREEN"NOMBRE  |  NUMERO_FICHEROS_ABIERTOS  |  UID  |  PID_PROCESO_MAS_ANTIGUO"$TEXT_RESET

        while [ "$size_2" != $zero ]; do

          echo " $1               $(lsof -w -u $1 | wc -l)               $(ps -w -u $1 --no-headers -o uid | head -n1)        $(ps -u $1 --no-headers -o pid | head -n1) "
          shift # lo movemos
          size_2=$# # guardamos el parametro

        done 

        else # los que son > 2 (casos de -f etc etc)

          while [ "$size_2" != $zero ]; do # distinto igual   si el nuevo parametro recogido es != 0 

            valor_parametros[valor_entrada]=$1  # lo marcamos     javi -> ./open_file.sh javi pepito -f .ttf
            shift   # desplazamos                                 desplazas
            size_2=$#   # ahora es el desplazamiento nuevo        = pepito-f .ttf (3)

            if [[ "$1" = "-f" ]] || [[ "$1" = "--filtro" ]]; then # el $1 es la siguiente parametros ./open_file.sh javi (pepito) (marcas si pepito a punta a -f)

              shift   # lo movemos para comparar la otra posicion
              cadenas_valores=$1    #comparamos con esto
              filtra_usuario # llamamos la funcion
              exit 0 # cumple lo pedido

              elif [ "" = "$1" ]; then # el siguiente parametro (""), es decir cuando es de 3 (-u javi root colord)

                valor_entrada=0
                  echo $TEXT_BOLD$TEXT_GREEN"NOMBRE  |  NUMERO_FICHEROS_ABIERTOS  |  UID  |  PID_PROCESO_MAS_ANTIGUO"$TEXT_RESET

                while [ "$valor_entrada" -lt "$size_1" ]; do   # menores que size ( $# )

                  echo " ${valor_parametros[valor_entrada]}               $(lsof -w -u ${valor_parametros[valor_entrada]} | wc -l)               $(ps -w -u ${valor_parametros[valor_entrada]} --no-headers -o uid | head -n1)        $(ps -u ${valor_parametros[valor_entrada]} --no-headers -o pid | head -n1) "
                  valor_entrada=$(($valor_entrada + 1))

                done

              else
                valor_entrada=$(($valor_entrada + 1))

            fi
          done # primer while fin 
      fi # primer if fin
      
      exit 0         # 0 bien, 1 mal
    ;;

    * ) # por defecto (casos errores)
      funcion_error
    ;;
  esac
  shift
done

if ["$1" = ""]; then

  comprobar_lsof  # comprobar si el comando lsof está instalado
  usuarios_who  # funcion usuarios_who
  
fi