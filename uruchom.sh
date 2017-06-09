#!/bin/bash

#################
#### FUNKCJE ####
#################

##################################################################################
## wiadomosc - wiadomosc wyswietlana na ekranie.
##     argumenty: $1 FID $2 tresc
##
wiadomosc() 
{ 
    echo -ne "$(date +"%D %T.%N") PID:$BASHPID FID: $1 : $2"
}

##################################################################################
## rozmyslanie
##     argumenty: $1 FID $2 nrPosilku $3 czas
##
rozmyslanie()
{
	wiadomosc $1 "Rozmyslanie po posilku $2. Czas rozmyslania: $3s\n"   
	sleep $3
	wiadomosc $1 "Koniec rozmyslania po posilku $2\n"
}

##################################################################################
## konsumpcja
##     argumenty: $1 FID $2 nrPosilku $3 czas
##
konsumpcja()
{ 
	wiadomosc $1 "Kosnumuje posilek $2, zajmie mi to $3 s\n"
	sleep $3
	wiadomosc $1 "Posilek nr $2 zjedzony \n"
}

##################################################################################
## czyPosprzatac
##     argumenty: $1 sciezkaBariery $2 sciezkaKatalogu
##	   			  $3 sciezkaPotoku $4 filozofowieLiczba
##
czyPosprzatac()
{
	wiadomosc "(:x:)" "Czy posprzatac po uczcie? (t/T) "
	read -n 1 wybor
	echo ""
	if [[ $wybor == "t" ]] || [[ $wybor == "T" ]]; then
		wiadomosc "(:x:)" "Usuwam widelce, plik bariery i pliki potokow\n"
		for i in $(seq 1 $4); do
			rm -f ${3}"_"${i}
		done
		rm -f $1
		rm -rf $2
		wiadomosc ":)" "Usunieto!\n"
	else
		wiadomosc ":)" "Nie sprzatam.\n"
	fi
}

##################################################################################
## czyRzeczywista
##     argumenty: $1 liczba
##
czyRzeczywista()
{
	local liczba=$1
	_liczba=$(echo "$_liczba" | awk '
	/^[+-]?[0-9]+[.]?[0-9]*$/ {print $0}; 
	$0 !~ /^[+-]?[0-9]+[.]?[0-9]*$/ {print "x"}')
	if [ "$liczba" == "a" ] ; then
		wiadomosc ":!:" "Blad, koniec procesu: Kod bledu: 0x4\n"
		exit 4	
	else
		local dodatnia=$( echo "${liczba} >= 0" | bc -l )
		if [ "$dodatnia" == "0" ] ; then 
			wiadomosc ":!:" "Blad, koniec pracy procesu. Kod bledu: 0x2\n"
			exit 2 
		fi
	fi
}

##################################################################################
## filozof
##     argumenty konieczne:  $1 FID $2 posilkiLiczba $3 filozofowieLiczba 
##	   				 		 $4 sciezkaKatalogu $5 sciezkaBariery
##				 	         $6 pierwszyWidelec $7 drugiWidelec 
##                           $8 sciezkaPotoku
##	   argumenty opcjonalne: $9 czasKonsumpcji $10 czasRozmyslania
##
filozof()
{
	#wiadomosc START W ZALEZNOSCI OD ILOSCI ARGUMENTOW
	if [ $# -eq  8 ]; then
		#wiadomosc STARTU
		wiadomosc $1 "^^^START^^^ Liczba posilkow:$2 | Liczba filozofow:$3 | Sciezka katalogu:$4 | Plik bariery:$5 |
		| Plik potoku: $8 | Bez. sciezka do pierwszego widelca (WID:$6): $(realpath $4/$6) | Drugi widelec WID:$7\n"
		local readonly PODANO_CZASY=0
	else
		#wiadomosc STARTU
		wiadomosc $1 "^^^START^^^ Liczba posilkow:$2 | Liczba filozofow:$3 | Sciezka katalogu:$4 | Plik bariery:$5 |
		| Plik potoku: $8 | Bez. sciezka do pierwszego widelca (WID:$6): $(realpath $4/$6) | Drugi widelec WID:$7 | Czas konsumowania:$9 s | Czas rozmyslania:${10} s\n"
		local readonly PODANO_CZASY=1
		local declare czasKonsumpcji=$9
		local declare czasRozmyslania=${10}
	fi

	local readonly FID=$1
	local readonly posilkiLiczba=$2
	local readonly filozofowieLiczba=$3
	local readonly sciezkaKatalogu=$4
	local readonly sciezkaBariery=$5
	local readonly pierwszyWidelec=$6
	local readonly drugiWidelec=$7
	local readonly sciezkaPotoku=$8

	declare -i skonsumowaneLiczba=0;
	(( polowa_posilkow = posilkiLiczba-posilkiLiczba/2 ))

	#ZADEKLAROWANIE DESKRYPTOROW
	local pierwszyDeskryptor=9
	local drugiDeskryptor=10

	#PRZYPISANIE DESKRYPTORÓW
	eval exec "${pierwszyDeskryptor}>${sciezkaKatalogu}/${pierwszyWidelec}"
	eval exec "${drugiDeskryptor}>${sciezkaKatalogu}/${drugiWidelec}"
	
	# "CYKL" FILOZOFA
	while [ true ]; do

		#LOSOWANIE CZASOW: ROZMYSLANIA, KONSUMPCJI
		if [ $# -eq 8 ] ; then 
			local declare czasKonsumpcji="0.$RANDOM"
			local declare czasRozmyslania="0.$RANDOM"
		fi
		#PROBA PODNIESIENIA PIERWSZEGO WIDELCA
		wiadomosc $FID "Probuje podniesc widelec (WID:$pierwszyWidelec)...\n"
		flock -e $pierwszyDeskryptor
		wiadomosc $FID "Podnioslem widelec (WID:$pierwszyWidelec) i zalozylem na nim blokade wylaczna\n"

		#PROBA PODNIESIENIA DRUGIEGO WIDELCA
		wiadomosc $FID "Probuje podniesc widelec (WID:$drugiWidelec)...\n"
		flock -e $drugiDeskryptor
		wiadomosc $FID "Podnioslem widelec (WID:$drugiWidelec) i zalozylem na nim blokade wylaczna\n"

		#KONSUMOWANIE
		nastepnyPosilek=$[skonsumowaneLiczba+1]
		konsumpcja $FID $nastepnyPosilek $czasKonsumpcji
		skonsumowaneLiczba=nastepnyPosilek

		#ODKLADANIE WIDELCOW W ODWROTNEJ KOLEJNOSCI	
		flock -u $drugiDeskryptor
		wiadomosc $FID "Odlozylem widelec (WID:$drugiWidelec) i zdjalem z niego blokade wylaczna\n" 
		flock -u $pierwszyDeskryptor
		wiadomosc $FID "Odlozylem widelec (WID:$pierwszyWidelec) i zdjalem z niego blokade wylaczna\n" 
		
		#wiadomosc WYSWIETLANY PO ZJEDZENIU POLOWY ZE WSZYSTKICH POSILKOW
		if [[ $skonsumowaneLiczba == $polowa_posilkow ]]; then
			wiadomosc $FID "---POLOWA--- Zjadlem juz $skonsumowaneLiczba posilkow(-ki)\n"
			coproc ncat -U  $sciezkaBariery -c 'read'   
			cat $sciezkaPotoku  >> /dev/null  # zeby oczekiwac na barierze
		fi
		
		#STOP PO ZJEDZENIU WSZYSTKICH POSILKOW
		if [[ $skonsumowaneLiczba == $posilkiLiczba ]]; then
			wiadomosc $FID "___STOP___ Zjadlem $skonsumowaneLiczba posilkow(-ki)\n" ;
			break;
		fi;
			
		#ROZMYSLANIE
		rozmyslanie $FID $skonsumowaneLiczba $czasRozmyslania   
		
	done

}

#########################################################################################################################


#ARGUMENTY PODAWANE PRZY URUCHOMIENIU
while getopts f:n:s:r:k: OPCJA
do
    case $OPCJA in
        f) declare -i liczbaFilozofow=$OPTARG;;
        n) declare -i liczbaPosilkow=$OPTARG;;
        s) declare sciezkaKatalogu=$OPTARG;;       
        r) declare czasRozmyslania=$OPTARG;;
        k) declare czasKonsumpcji=$OPTARG;;
        *) echo Nieznana opcja $OPTARG; exit 2;;
    esac
done

         
#ARGUMENTY DOMYSLNE		 
if [ ${liczbaFilozofow:-0} -lt 2 ]; then
	declare -r liczbaFilozofow=5
fi

declare -r liczbaFilozofow

if [ ${liczbaPosilkow:-0} -lt 2 ]; then
	declare -r liczbaPosilkow=7
fi

declare -r liczbaPosilkow
declare -r sciezkaKatalogu=${sciezkaKatalogu:-stolik}
declare -r sciezkaBariery=".bariera"
declare sciezkaPotoku="potok_filozofa"

#SPRAWDZANIE POPRAWNOSCI CZASOW
if [ -z $czasKonsumpcji ] && [ -z $czasRozmyslania ] ; then
	true
else
	czyRzeczywista $czasKonsumpcji
	czyRzeczywista $czasRozmyslania
fi


#STOL
if [ ! -d $sciezkaKatalogu ]; then
	mkdir $sciezkaKatalogu
fi

#WIDELCE
for (( i=1; i<=${liczbaFilozofow} ; i++ )); do
	declare widelec="$sciezkaKatalogu/$liczbaFilozofow"
	if [ ! -f $widelec ]; then
		touch $widelec
	fi
done


declare -r oczekiwanaLiczbaPolaczen=$(( liczbaFilozofow+1 ))
export oczekiwanaLiczbaPolaczen 
export sciezkaBariery 
rm -f ${sciezkaBariery}
coproc podprocesBariery { ncat -v -m $oczekiwanaLiczbaPolaczen -U -k -l $sciezkaBariery -c 'liczbaPolaczen=$(netstat -x | grep "$sciezkaBariery" | wc -l) ; if [ $liczbaPolaczen -eq $oczekiwanaLiczbaPolaczen ]; then fuser -k $sciezkaBariery; else cat; fi ' ;} 2>&1  

# Sprawdzenie czy udalo sie utworzyc proces ncat 
read odbior <&${podprocesBariery[0]}
read odbior <&${podprocesBariery[0]}
if [ "Ncat: Listening on $sciezkaBariery" != "$odbior" ]; then
   echo "Zakonczenie z powodu nieudanej proby otwarcia gniazda $sciezkaBariery"
   exit 1;
fi

#URUCHOMIENIE FILOZOFOW
for i in `shuf -i 1-$liczbaFilozofow`; do

	sciezkaTymczasowa=${sciezkaPotoku}"_"${i}
    rm -f ${sciezkaTymczasowa};
    mkfifo ${sciezkaTymczasowa};

	#USTALANIE KOLEJNOSCI DOBIERANIA WIDELCOW
	if [[ $(($i % 2)) == 1 ]]; then
		declare pierwszyWidelec="$i"
	    declare drugiWidelec="$(($i + 1))"
	    if [[ $drugiWidelec == "$(($liczbaFilozofow + 1))" ]]; then
	    	drugiWidelec=1
	    fi
    else
      	declare drugiWidelec="$i"
	    declare pierwszyWidelec="$(($i + 1))"
	    if [[ $pierwszyWidelec == "$(($liczbaFilozofow + 1))" ]]; then 
	    	pierwszyWidelec=1
	    fi
    fi   
    
    
	
    #KOMUNIKAT URUCHAMIANIE PROCESU FILOZOFA    
	if test ${czasRozmyslania:-losowe} = "losowe"  ;then
		wiadomosc "(-)" "<$(hostname)> STARTUJE FILOZOF o FID:$i | Liczba posilkow:$liczbaPosilkow | Liczba filozofow:$liczbaFilozofow 
		| Sciezka katalogu-stolu:$sciezkaKatalogu | Plik bariery:$sciezkaBariery | Plik potoku: $sciezkaTymczasowa | Pierwszy widelec WID:$pierwszyWidelec | Drugi widelec WID:$drugiWidelec\n"
	  	filozof $i $liczbaPosilkow $liczbaFilozofow $sciezkaKatalogu $sciezkaBariery $pierwszyWidelec $drugiWidelec $sciezkaTymczasowa &
	else
		wiadomosc "(-)" "<$(hostname)> STARTUJE FILOZOF o FID:$i | Liczba posilkow:$liczbaPosilkow | Liczba filozofow:$liczbaFilozofow 
		| Sciezka katalogu-stolu:$sciezkaKatalogu | Plik bariery:$sciezkaBariery | Plik potoku: $sciezkaTymczasowa | Pierwszy widelec WID:$pierwszyWidelec | Drugi widelec WID:$drugiWidelec | Czas konsumpcji:$czasKonsumpcji s | Czas rozmyslania: $czasRozmyslania s\n"
		filozof $i $liczbaPosilkow $liczbaFilozofow $sciezkaKatalogu $sciezkaBariery $pierwszyWidelec $drugiWidelec $sciezkaTymczasowa $czasKonsumpcji $czasRozmyslania &
	fi
done

#oczekiwanie na wszystkich filozofow
wiadomosc "(-)" "********** Oczekuje na zgloszenie dotarcia do bariery od kazdego filozofa\n"
ncat -U $sciezkaBariery -c 'read'
wiadomosc "(-)"  "********** Bariera polowy posilkow zwolniona - Wszyscy filozofowie zjedli polowe posilkow\n"

# zwolnienie bariery polowy posilkow
for i in `shuf -i 1-$liczbaFilozofow`; do
    declare sciezkaPotokuFilozofa="${sciezkaPotoku}_$i"
    echo "kontynuuj" >> ${sciezkaPotokuFilozofa}
done
# filozofowie kontynuuja uczte


wait

czyPosprzatac $sciezkaBariery $sciezkaKatalogu $sciezkaPotoku $liczbaFilozofow

exit 0


# MOZLIWE KODY WYJSCIA "uruchom.sh"
#	1 - Zakonczenie z powodu nieudanej proby otwarcia gniazda
#	2 - Nieprawidlowy parametr: podano ujemna liczbe zamiast dodatniej
#	3 - Nieprawidlowy parametr: podano liczbe niecalkowita zamiast naturalnej
#	4 - Nieprawidlowy parametr: podano znaki zamiast liczby 
