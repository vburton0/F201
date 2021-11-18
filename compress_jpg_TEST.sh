#!/bin/bash

# Message

SHORT_USAGE="USAGE :
    ${0} [-c] [-r] [-e extension] resolution [filename_or_directory]
ou
    ${0} --help
Pour plus d'aide."
USAGE="$SHORT_USAGE"

aide="
------------------------------------------------------------------------------------------
Pour la commande :

./compress_jpg.sh [-c] [-r] [-e extension] resolution [filename_or_directory]

L'argument résolution est obligatoire et est un entier

Les autres argument sont des options :

[-c] : active le passage de l’argument -strip à convert.

[-r] : Si un dossier est donné en entrée, compress_jpg.sh travaille aussi dans les sous-dossiers récursivement. Sinon, cette option n’a pas d’effet.

[-e extension] : Sert a changer l'extension du fichier donné par l'extension donné.

[filename_or_directory] : Le nom du fichier ou du dossier sur lequel vous voulez travailler

------------------------------------------------------------------------------------------

"


# Return values
BAD_USAGE=1
CONVERT_ERR=2
NO_EXIST=3

#=========================================================================================

function check_extension () {
	# Renvoi 0 si l'extension est bonne, et 1 si pas

	case "$1" in 
		jpg|jpeg|jpe|jif|jfif|JPG|JPEG|JPE|JIF|JFIF|JFI)
			return 0 	# Renvoi 0 si l'extension est bonne
			;;
		*)
			return 1 	# Renvoi 1 sinon
			;;
	esac

}

# Vérification des arguments

function parse_args () {

	# Dans le cas où help est demandé

	for arg ; do
		if [ $arg = -h ] || [ $arg = --help ] || [ $arg = help ]; then 
			echo "$aide"
			exit
		fi
	done

	# Dans les autres cas 

	while [ $# -gt 0 ]; do
		case "$1" in
			-r|--recursive)
				R=1
				shift
				;;
			-c|--strip)
				C=1
				shift
				;;
			-e|--ext)
				if [ $# -lt 2 ] ; then
					echo "-e|--ext doit être accompagné d'un argument" 1>&2
					echo "$USAGE"
					exit "$BAD_USAGE"
				else 
					check_extension "$2"
					check_ext=$?
					if [ $check_ext -ne 1 ]; then
						EXTENSION="$2"
					else 
						echo "l'argument -e doit être un de ceux là : jpg, jpeg, jpe, jif, jfif, jfi (ou les mêmes en majuscule)"
						echo "$USAGE"
						exit "$BAD_USAGE"
					fi
				fi
				shift ; shift
				;;
			-*)
	            echo "Option inconnue: $1"
	            exit $BAD_USAGE
	            ;;

	        ''|*[!0-9]*)
				FILE="$1"
				shift
				;;
			*)
				RESOLUTION="$1"
				shift
				;;

		esac
	done

	#Si la resolution n'est pas donnée
	if [ -z $RESOLUTION ]; then
		echo "La resolution est un argument obligatoire"
		echo "$USAGE"
		exit $BAD_USAGE
	fi 	
}

parse_args "$@"

#=========================================================================================

function change_extension () {
	#Prends et changer l'extension
	echo "$1"
	if $(file -i "$1" | grep -q "image/jpeg" ); then 	# Si fichier est un JPEG
		echo "jpeg"
		if [ -e "${1%.*}".$EXTENSION ]; then 
			echo " Le fichier {$1} ne peut pas renommé car il existe déjà un fichier de ce nom : '${1%.*}'.$EXTENSION" 
		else 
			mv ./"$1" "${1%.*}".$EXTENSION

		fi

		if [[ $1 != . ]];then
			mv $1 "${1}".$EXTENSION

		fi
	fi
}

function print_file () {
	if [ $EXTENSION ]; then		#Si changement d'extension demandé
		echo "$1"
		change_extension "$1"
		echo "$1"
	else						# Au sinon
		echo "$1" #| sed 's/\\e\[[0-9;]\+m//g'
	fi

}

#=========================================================================================

function is_file () { 					# Fichier
	print_file "$FILE"
}

function is_directory () {				# Répertoire non récursif
	for f in "$FILE"/*; do
		if $(file -i $f | grep -q "image/jpeg" ); then	# Si fichier est un JPEG
			print_file $f
		fi
	done

}

function is_directory_recursif () { 	# Répertoire récursif
	for f in `ls $FILE ` ; do
		if [[ $f =~ \.jpeg$ ]]; then
			print_file $f
		fi
	done
}


#=========================================================================================

# Check si on travail sur un dossier ou un fichier

if [ -d $FILE ]; then	# Si dossier
	if [ $R ]; then 	# Récursif
		is_directory_recursif
	else 				# Non récursif
		is_directory
	fi
elif [ -e $FILE ]; then # Si Fichier
	is_file
fi
