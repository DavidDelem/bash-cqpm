#!/bin/bash
# DAVID DELEMOTTE - CIR 3 ALTERNANTS - CQPM
# Script de création d'un utilisateur


  #---------------------------------------------#
  #--------------- Initialisation des variables #
  #---------------------------------------------#

EXIT_CODE_SUCCESS=0
EXIT_CODE_FAILURE=2

ERREURMESSAGE="ERREUR:"
AVERTMESSAGE="AVERTISSEMENT:"
INFOMESSAGE="INFORMATION:"
SUCCESSMESSAGE="SUCCES:"

  #---------------------------------------------#
  #------------------------ Contrôle des droits #
  #---------------------------------------------#

# Source pour l'idée de la comparaison a faire: http://www.cyberciti.biz/tips/shell-root-user-check-script.html
if [[ "$(id -u)" -ne "0" ]]; then
  echo "$ERREURMESSAGE Seul un utilisateur root peut utiliser ce script"
  echo "Usage: sudo ./create-user.sh nomuser groupeprimaire [groupesecondaire1 groupesecondaire2 ...]"
	exit $EXIT_CODE_FAILURE

  #---------------------------------------------#
  #-------------------- Contrôle des paramétres #
  #---------------------------------------------#

elif [[ "$#" -lt 2 ]]; then
  echo "$ERREURMESSAGE Nombre d'arguments invalide"
  echo "Usage: sudo ./create-user.sh nomuser groupeprimaire [groupesecondaire1 groupesecondaire2 ...]"
  exit $EXIT_CODE_FAILURE

  #---------------------------------------------#
  #------------- Traitements si données valides #
  #---------------------------------------------#

else
  # Récupération des paramêtres
  utilisateur=$1
  groupe_primaire=$2
  declare -a groupes_sec_array

  # Controle de l'existance de l'utilisateur
  if [ $(getent passwd $utilisateur) ]; then
    echo "$ERREURMESSAGE L'utilisateur $utilisateur existe déjà"
    exit $EXIT_CODE_FAILURE
  fi

  # Controle de l'existance du répertoire du groupe primaire
  if [ ! -d "/home/$groupe_primaire" ]; then
    echo "$ERREURMESSAGE Le répertoire /home/$groupe_primaire n'existe pas, utilisez create-group.sh"
    exit $EXIT_CODE_FAILURE
  fi

  #---------------------------------------------#
  #------- Récupération des groupes secondaires #
  #-------------- et controle de leur existence #
  #---------------------------------------------#

  # i sert pour le parcours des parametres
  # j sert pour l'indexation dans le tableau des groupes
  i=0
  j=0
  for parametre in "$@"; do
    i=$((i+1))
    # Les groupes secondaires commencent a partir du 3éme argument
    if [[ i -gt 2 ]]; then
      # Controle de l'existance du groupe
      if [ $(getent group $parametre) ]; then
        # Ajout au tableau des groupes secondaires de l'utilisateur
        groupes_sec_array[$j]=$parametre
        j=$((j+1))
      else
        echo "$AVERTMESSAGE Le groupe $parametre n'existe pas et ne sera pas ajouté en groupe secondaire"
      fi
    fi
  done

  #---------------------------------------------#
  #------------------ CREATION DE L'UTILISATEUR #
  #---------------------------------------------#

  # Répertoire de l'utilisateur
  repertoire_personnel="/home/$groupe_primaire/$utilisateur"
  # Mot de passe par défaut de l'utilisateur
  password_default="isen"

  # On transforme le tableau en une chaine séparée par des virgules avec IFS
  # Source pour utilisation d'IFS (premiere reponse): http://stackoverflow.com/questions/13470413/bash-array-to-delimited-string
  groupes_sec_string=$(IFS=, ; echo "${groupes_sec_array[*]}")

  # Création de l'utilisateur, du répertoire personnel, ajout du groupe primaire, ajout éventuel des groupes secondaires
  if [ -z "$groupes_sec_string" ]; then
    useradd -d $repertoire_personnel $utilisateur --create-home --gid $groupe_primaire
  else
    useradd -d $repertoire_personnel $utilisateur --create-home --gid $groupe_primaire --groups $groupes_sec_string
  fi

  # Mot de passe par défaut, sinon le compte utilisateur n'est pas activé
  # Source pour chpasswd: http://ccm.net/faq/790-changing-password-via-a-script
  echo "$utilisateur:$password_default" | chpasswd

  # Le répertoire de l'utilisateur ne doit pas appartenir à root mais à lui même et a son groupe
  chown $utilisateur:$groupe $repertoire_personnel

  # Controle de la réussite de la création de l'utilisateur ou non
  if [ $(getent passwd $utilisateur) ]; then
    echo "$SUCCESSMESSAGE Utilisateur et répertoire personnel créés"
    echo "$SUCCESSMESSAGE Utilisateur associé au groupe primaire $groupe_primaire"
    echo "$SUCCESSMESSAGE Utilisateur associé au groupes secondaires $groupes_sec_string"
  else
    echo "$ERREURMESSAGE Impossible de créer l'utilisateur $utilisateur"
    exit $EXIT_CODE_FAILURE
  fi

  #---------------------------------------------#
  #----------------- CREATION DU FICHIER BASHRC #
  #---------------------------------------------#

  bashrc_text="#FICHIER BASHRC GENERE AUTOMATIQUEMENT"
  echo "$bashrc_text" > "$repertoire_personnel/.bashrc"

  # droits par défaut
  bashrc_text="umask 027"
  echo "$bashrc_text" >> "$repertoire_personnel/.bashrc"

  # Parcours des groupes secondaires valides et ajout dans le fichier bashrc
  for group in ${groupes_sec_array[*]}
  do
     echo "./etc/environnement/$group.sh" >> "$repertoire_personnel/.bashrc"
  done

  echo "$SUCCESSMESSAGE Fichier .bashrc créé. Il est possible qu'il ne soit pas visible"
  echo "$INFOMESSAGE Le mot de passe par défaut de $utilisateur est isen (en minuscule)"
fi

exit $EXIT_CODE_SUCCESS
