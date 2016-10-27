#!/bin/sh

#
### BEGIN INIT INFO
# Provides:          ClamAv
# Short-Description: Un scan supplementaire anti-virus 
# Description:       Efectue des scan periodiques sur les BAL avec ClamAV et envoie des messages avec les logs.
### END INIT INFO

#set -x

LOGFILE="/var/log/clamav/premier_mailscan.log"
rep_virus="/var/tmp/VIRUS/"
dir_scan="/var/vmail/"
notification="calin.dordia@ro.auf.org"
log_file="/var/log/clamav/hebdo_clamscan.log"

for dir in `ls $dir_scan`;

do

    for subdir in `ls $dir_scan/$dir`;

    do

$(#for S in ${dir_scan}; do 
#DIRSIZE=$(du -sh "$S" 2>/dev/null | cut -f1);

#echo "Start le scan hebdomadaire du repertoire "$S".
# Le scan volume est "$DIRSIZE".";

# La premiere analyse

if [ ! -d "$rep_virus" ] 

then mkdir "$rep_virus" 

fi

if [ ! -f  "$LOGFILE $dir" ] 

then

 clamscan -i -l "$LOGFILE $dir" -r --move="$rep_virus" "$dir_scan"

### Verifier si le fichier log existe et envoyer par e-mail

VN=$(tail "$LOGFILE $dir"|grep Infected|cut -d" " -f3)

if [ "$VN" -ne "0" ]

then    
    mail -s "ClamAV Log du `date +%d-%m-%Y`" "$notification" < "$LOGFILE $dir"
	echo "Send OK"
#	cp "$LOGFILE" "ClamAV_log`date +%d-%m-%Y`
	cp "$LOGFILE $dir" "$log_file $dir"
#    echo "" > "$LOGFILE"
else
    echo "Aucun virus trouve" | mail -s "Aucun Virus ClamAV `date +%d-%m-%Y`" "$notification"
#    echo "Une erreur de scan envoyee par courriel"
fi

# l'analyse hebdomadaire 

else

# creation du fichier temporaire pour la liste de noveaux fichiers 

list_file=$(mktemp -t clamscan.XXXXXX) || exit 1

# la liste des noveaux fichiers (derniere semaine)


if [ -f  "$log_file $dir" ]
then
        # utiliser les fichiers le plus nouveaux que le fichier temporaire de logs
        find "$dir_scan" -type f -cnewer "$log_file $dir" -fprint "$list_file"
else
        # identifier les messages du derniers 7 jours
        find "$dir_scan" -type f -ctime 7 -fprint "$list_file"
fi

if [ -s "$list_file" ]
then
        # Scan les fichiers et les deplace dans un rep. des  infectes.
        clamscan -i -f "$list_file" --move="$rep_virus" > "$log_file $dir"

        # envoyer un courriel d'alerte
        if [ `cat "$log_file $dir" | grep Infected | grep -v 0 | wc -l` != 0 ]
        then
                HOSTNAME=`hostname`
                echo "$(egrep "FOUND" "$log_file $dir") $dir" | mail -s "Nouvelle parution des viruses on $HOSTNAME"   "$notification"
        fi
else
        # elenver la liste vide, pas d'information relevante
        rm -f "$list_file"
fi
fi
);
done
done
exit

#set +x