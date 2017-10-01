#!/bin/bash
# DAVID DELEMOTTE - CIR 3 ALTERNANTS - CQPM
# Script de création d'un groupe


  #---------------------------------------------#
  #--------------- Initialisation des variables #
  #---------------------------------------------#

EXIT_CODE_SUCCESS=0
EXIT_CODE_FAILURE=2

ERREURMESSAGE="ERREUR:"
AVERTMESSAGE="AVERTISSEMENT:"
SUCCESSMESSAGE="SUCCES:"

  #---------------------------------------------#
  #------------------------ Contrôle des droits #
  #---------------------------------------------#

# Source pour l'idée de la comparaison a faire: http://www.cyberciti.biz/tips/shell-root-user-check-script.html
if [[ "$(id -u)" -ne "0" ]]; then
  echo "$ERREURMESSAGE Seul un utilisateur root peut utiliser ce script"
  echo "Usage: sudo ./create-user.sh nomgroupe"
	exit $EXIT_CODE_FAILURE

  #---------------------------------------------#
  #-------------------- Contrôle des paramétres #
  #---------------------------------------------#

elif [[ "$#" -ne 1 ]]; then
  echo "$ERREURMESSAGE Nombre d'arguments invalide"
  echo "Usage: sudo ./create-user.sh nomgroupe"
  exit $EXIT_CODE_FAILURE
else
  # Récupération du paramêtre
  group=$1

  #---------------------------------------------#
  #---------- Contrôle de l'existence du groupe #
  #---------------------------------------------#

  # Le groupe ne doit pas déjà exister
  # Source pour getent: http://man7.org/linux/man-pages/man1/getent.1.html
  if [ $(getent group $group) ]; then
    echo "$ERREURMESSAGE Le groupe $group existe déjà"
    exit $EXIT_CODE_FAILURE
  fi

  #---------------------------------------------#
  #------------------------- Création du groupe #
  #---------------------------------------------#

  groupadd $group

  #---------------------------------------------#
  #----------- Création du répertoire du groupe #
  #---------------------------------------------#

  mkdir /home/$group
  # Le groupe du service est propriétaire du répertoire du groupe
  chgrp $group /home/$group
  # Droit en lecture et ecriture pour les utilisateurs du groupe et rien pour les autres
  chmod 770 /home/$group

  #---------------------------------------------#
  #---- Création du répertoire commun du groupe #
  #---------------------------------------------#

  mkdir /home/$group/commun
  # Le groupe du service est propriétaire du répertoire commun
  chgrp $group /home/$group/commun
  # Droit en lecture et ecriture pour les utilisateurs du groupe et rien pour les autres
  chmod 770 /home/$group/commun
  # Ajour du sticky bit pour empécher la destruction d'un fichier par un autre
  chmod +t /home/$group/commun

  echo "$SUCCESSMESSAGE Le groupe $group a été créé avec son répertoire et son répertoire commun"
fi

exit $EXIT_CODE_SUCCESS
