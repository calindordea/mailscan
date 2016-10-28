#!/bin/sh

#
### BEGIN INIT INFO
# Provides:          ClamAv
# Short-Description: Un scan supplementaire anti-virus 
# Description:       Efectue des scan periodiques sur les BAL avec ClamAV et envoie des messages avec les logs.
### END INIT INFO

#set -x

notification="calin.dordia@ro.auf.org"
notif_prefix="ClamAV Log :"

dir_scan="/var/vmail/"
rep_virus="/var/tmp/VIRUS/"
premier_scan_base="/var/log/clamav/premier_mailscan.log"
log_base="/var/log/clamav/hebdo_clamscan.log"

# date du jour
today="`date +%Y-%m-%d`"

# s'assurer que le dossier de quarantaine existe
mkdir -p "$rep_virus"

# parcourir les domaines de courriels
for domain in `ls -1 "$dir_scan"`
do
  # parcourir les boîtes aux lettres du domaine
  for dir in `ls -1 "$dir_scan/$domain"`
  do
    #DIRSIZE=$(du -sh "$S" 2>/dev/null | cut -f1);
    #echo "Start le scan hebdomadaire du repertoire "$S".
    #Le scan volume est "$DIRSIZE".";

    # fichiers de travail pour ce dossier
    premier_scan_file="$premier_scan_base $dir"
    log_file="$log_base $dir"

    if [ ! -f "$premier_scan_file" ]
    then # La premiere analyse
      clamscan -i -l "$premier_scan_file" -r --move="$rep_virus" "$dir_scan"

      # Verifier si le fichier log existe et envoyer par e-mail
      VN="`tail "$premier_scan_file" | grep Infected | cut -d" " -f3`"
      if [ "$VN" != "0" ]
      then
        cat "$premier_scan_file" | mail -s "$notif_prefix $VN virus" "$notification"
	echo "Send OK"
        #cp "$premier_scan" "ClamAV_log`date +%d-%m-%Y`
	cp -af "$premier_scan_file" "$log_file $dir"
        #echo "" > "$premier_scan"
      else
        echo "Aucun virus trouve" | mail -s "$notif_prefix aucun virus" "$notification"
        #echo "Une erreur de scan envoyee par courriel"
      fi

    else # l'analyse hebdomadaire 
      # creation du fichier temporaire pour la liste de noveaux fichiers 
      list_file="`mktemp -t clamscan.XXXXXX`" || exit 1

      # la liste des noveaux fichiers (derniere semaine)
      if [ -f  "$log_file" ]
      then
        # utiliser les fichiers le plus nouveaux que le fichier temporaire de logs
        find "$dir" -type f -cnewer "$log_file" -fprint "$list_file"
      else
        # identifier les messages du derniers 7 jours
        find "$dir" -type f -ctime 7 -fprint "$list_file"
      fi

      if [ -s "$list_file" ]
      then
        # Scan les fichiers et les deplace dans un rep. des  infectes.
        clamscan -i -f "$list_file" --move="$rep_virus" > "$log_file"
        # envoyer un courriel d'alerte
        VN="`cat "$log_file" | grep Infected | grep -v 0 | wc -l`"
        if [ "$VN" != "0" ]
        then
          echo "`grep "FOUND" "$log_file"` $dir" | mail -s "$notif_prefix nouveau(x) virus sur `hostname`" "$notification"
        fi
      else
        # elenver la liste vide, pas d'information relevante
        rm -f "$list_file"
      fi
    fi

  done
done

#set +x
exit 0
