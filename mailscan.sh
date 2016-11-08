#!/bin/bash

#
### BEGIN INIT INFO
# v1 - QUARANTINES DANS LES BAL
# Besoin:          ClamAv
# Description: Un scan supplementaire anti-virus pour les BAL des utilisateurs
# Description: Efectue des scan sur les BAL avec ClamAV et envoie des messages avec les logs.
# Description: Il peut etre instale dans /etc/cron/weekly
### END INIT INFO

#trap "pkill -f 'sleep 1h'" INT
#trap "set +x; sleep 1h; set -x" DEBUG


notification="calin.dordia@ro.auf.org"
notif_prefix="ClamAV Log :"
dir_scan="/var/vmail/"
rep_virus="/var/tmp/VIRUS/"
premier_scan_base="/var/log/clamav/premier_mailscan_"
log_base="/var/log/clamav/hebdo_clamscan_"
log_dir="/var/log/clamav/"

# date du jour
#today="`date +%Y-%m-%d`"

# s'assurer que le dossier de quarantaine existe
mkdir -p "$rep_virus"

# parcourir les domaines de courriels
for domain in `ls -1 "$dir_scan"`
do
  # parcourir les boîtes aux lettres du domaine
  for bal in `ls -1 "$dir_scan$domain"`
  do
    #DIRSIZE=$(du -sh "$S" 2>/dev/null | cut -f1);
    #echo "Start le scan hebdomadaire du repertoire "$S".
    #Le scan volume est "$DIRSIZE".";

    # s'assurer que le dossier de quarantaine existe dans chaque BAL
    mkdir -p "$dir_scan$domain"/"$bal"/"".VirusMail""
     
    # fichiers de travail pour ce dossier
    premier_scan_file="$premier_scan_base$bal"
    log_file="$log_base$bal"
    quarantine="$dir_scan$domain"/"$bal"/"".VirusMail""

    if [ ! -f "$premier_scan_file" ]
    then # La premiere analyse
      clamscan -i  --exclude-dir="$quarantine" -l "$premier_scan_file" -r --move="$quarantine"   "$dir_scan"

      # Verifier si le fichier log existe et envoyer par e-mail
      VN="`tail "$premier_scan_file" | grep Infected | cut -d" " -f3`"
      if [ "$VN" != "0" ]
      then
        cat "$premier_scan_file" | mail -s "$notif_prefix $VN virus" "$notification"
	echo "Send OK"
        #cp "$premier_scan" "ClamAV_log`date +%d-%m-%Y`
	cp -af "$premier_scan_file" "$log_file"
        #echo "" > "$premier_scan"
      else
        echo "Aucun virus trouve" | mail -s "$notif_prefix aucun virus" "$notification"
        #echo "Une erreur de scan envoyee par courriel"
      fi

    else # l'analyse hebdomadaire 
      # creation du fichier temporaire pour la liste de noveaux fichiers 
      list_file="`mktemp -t clamscan.XXXXXX`" || exit 1

      # la liste des noveaux fichiers (derniere semaine)
      #if [ -f  "$log_file" ]
      #then
        # utiliser les fichiers le plus nouveaux que le fichier temporaire de logs
        #find "$dir_scan$domain/$bal" -type f -cnewer "$log_file" -fprint "$list_file"
      #else
        # identifier les messages du derniers 7 jours
        find "$dir_scan$domain/$bal" -type f -mtime -60 -fprint "$list_file"
      #fi

      if [ -s "$list_file" ]
      then
        # Scan les fichiers et les deplace dans un rep. des  infectes.
        clamscan -i --exclude-dir="$quarantine"  -f "$list_file"  -r  --move="$quarantine"  > "$log_file"
        # envoyer un courriel d'alerte
        VN="`cat "$log_file" | grep Infected | grep -v 0 | wc -l`"
        if [ "$VN" != "0" ]
        then
          echo "`grep "FOUND" "$log_file"` $bal" | mail -s "$notif_prefix nouveau(x) virus sur `hostname`" "$notification"
        fi
      else
        # elenver la liste vide, pas d'information relevante
        rm -f "$list_file"
      fi
    fi
    #changer le propritaire de la quarantine pour que l'utilisateur puisse y operer
    chown -R "vmail":"vmail" "$quarantine"
  done
done

#set +x
exit 0
