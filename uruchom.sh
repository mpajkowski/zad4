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
	wiadomosc $1 "Jem posilek $2, zajmie mi to $3 s\n"
	sleep $3
	wiadomosc $1 "Juz zjadlem posilek nr $2\n"
}

##################################################################################
## czyPosprzatac
##     argumenty: $1 sciezkaBariery $2 sciezkaKatalogu
##	   			  $3 sciezkaPotoku $4 filozofowieLiczba
##
czyPosprzatac()
{
	wiadomosc "(:x:)" "Czy posprzatac po filozofach? (t/T) "
	read -n 1 wybor
	echo ""
	if [[ $wybor == "t" ]] || [[ $wybor == "T" ]]; then
		wiadomosc "(:x:)" "Usuwam widelce, plik bariery i pliki potokow\n"
		for i in $(seq 1 $4); do
			rm -f ${3}"_"${i}
		done
		rm -f $1
		rm -rf $2
		wiadomosc ":x:" "Usunieto!\n"
	else
		wiadomosc ":x:" "Nie sprzatam.\n"
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
		local declare czas_konsumpcji=$9
		local declare czas_rozmyslania=$10
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

	#ZADEKLAROWANIE DESKRYPTOROW (NIE MOZNA UZYWAC LITERALOW)
	local pierwszy_deskryptor=9
	local drugi_deskryptor=10

	#PRZYPISANIE DESKRYPTORÓW
	eval exec "${pierwszy_deskryptor}>${sciezkaKatalogu}/${pierwszyWidelec}"
	eval exec "${drugi_deskryptor}>${sciezkaKatalogu}/${drugiWidelec}"
	
	# "CYKL" FILOZOFA
	while [ true ]; do

				
		#LOSOWANIE CZASOW_ROZMYSLANIA I KONSUMPCJI JESLI NIE BYLY PODANE
		if [ $# -eq 8 ] ; then 
			local declare czas_konsumpcji="0.$RANDOM"
			local declare czas_rozmyslania="0.$RANDOM"
		fi;
		
		#PROBA PODNIESIENIA PIERWSZEGO WIDELCA
		wiadomosc $FID "Probuje podniesc widelec (WID:$pierwszyWidelec)...\n"
		flock -e $pierwszy_deskryptor
		wiadomosc $FID "Podnioslem widelec (WID:$pierwszyWidelec) i zalozylem na nim blokade wylaczna\n"

		#PROBA PODNIESIENIA DRUGIEGO WIDELCA
		wiadomosc $FID "Probuje podniesc widelec (WID:$drugiWidelec)...\n"
		flock -e $drugi_deskryptor
		wiadomosc $FID "Podnioslem widelec (WID:$drugiWidelec) i zalozylem na nim blokade wylaczna\n"

		#KONSUMOWANIE
		nastepnyPosilek=$[skonsumowaneLiczba+1]
		konsumpcja $FID $nastepnyPosilek $czas_konsumpcji
		skonsumowaneLiczba=nastepnyPosilek

		#ODKLADANIE WIDELCOW W ODWROTNEJ KOLEJNOSCI	
		flock -u $drugi_deskryptor
		wiadomosc $FID "Odlozylem widelec (WID:$drugiWidelec) i zdjalem z niego blokade wylaczna\n" 
		flock -u $pierwszy_deskryptor
		wiadomosc $FID "Odlozylem widelec (WID:$pierwszyWidelec) i zdjalem z niego blokade wylaczna\n" 
		
		#wiadomosc WYSWIETLANY PO ZJEDZENIU POLOWY ZE WSZYSTKICH POSILKOW
		if [[ $skonsumowaneLiczba == $polowa_posilkow ]]; then
			wiadomosc $FID "---POLOWA--- Zjadlem juz $skonsumowaneLiczba posilkow(-ki)\n"
			coproc ncat -U  $sciezkaBariery -c 'read'   
			#fuser -k $sciezkaBariery 
			cat $sciezkaPotoku  >> /dev/null  # zeby oczekiwac na barierze
		fi
		
		#STOP PO ZJEDZENIU WSZYSTKICH POSILKOW
		if [[ $skonsumowaneLiczba == $posilkiLiczba ]]; then
			wiadomosc $FID "___STOP___ Zjadlem $skonsumowaneLiczba posilkow(-ki)\n" ;
			break;
		fi;
			
		#ROZMYSLANIE
		rozmyslanie $FID $skonsumowaneLiczba $czas_rozmyslania   
		
	done

}

#########################################################################################################################


#ARGUMENTY PODAWANE PRZY URUCHOMIENIU
while getopts f:n:s:r:k: OPCJA
do
    case $OPCJA in
        f) declare -i LICZBA_FILOZOFOW=$OPTARG;;
        n) declare -i LICZBA_POSILKOW=$OPTARG;;
        s) declare SCIEZKA_KATALOGU=$OPTARG;;       
        r) declare CZAS_ROZMYSLANIA=$OPTARG;;
        k) declare CZAS_KONSUMPCJI=$OPTARG;;
        *) echo Nieznana opcja $OPTARG; exit 2;;
    esac
done

         
#ARGUMENTY DOMYSLNE		 
if test ${LICZBA_FILOZOFOW:-0} -lt 2; then declare -r LICZBA_FILOZOFOW=5; fi;
declare -r LICZBA_FILOZOFOW
if test ${LICZBA_POSILKOW:-0} -lt 2; then declare -r LICZBA_POSILKOW=7; fi;
declare -r LICZBA_POSILKOW
declare -r SCIEZKA_KATALOGU=${SCIEZKA_KATALOGU:-stolik}
declare -r SCIEZKA_BARIERY=".bariera"
declare SCIEZKA_POTOKU="potok_filozofa"

#SPRAWDZANIE POPRAWNOSCI CZASOW
if  test -z $CZAS_KONSUMPCJI && test -z $CZAS_ROZMYSLANIA ; then
	true;
else
	czyRzeczywista $CZAS_KONSUMPCJI
	czyRzeczywista $CZAS_ROZMYSLANIA
fi


#STOL
if [ ! -d $SCIEZKA_KATALOGU ]; then
	mkdir $SCIEZKA_KATALOGU
fi

#WIDELCE
for (( i=1; i<=${LICZBA_FILOZOFOW} ; i++ )); do
	declare widelec="$SCIEZKA_KATALOGU/$LICZBA_FILOZOFOW"
	if [ ! -f $widelec ]; then
		touch $widelec
	fi
done


declare -r OCZEKIWANA_LICZBA_POLACZEN=$(( LICZBA_FILOZOFOW+1 ))
export OCZEKIWANA_LICZBA_POLACZEN 
export SCIEZKA_BARIERY 
rm -f ${SCIEZKA_BARIERY}
coproc PODPROCES_bariery { ncat -v -m $OCZEKIWANA_LICZBA_POLACZEN -U -k -l $SCIEZKA_BARIERY -c 'liczba_polaczen=$(netstat -x | grep "$SCIEZKA_BARIERY" | wc -l) ; if [ $liczba_polaczen -eq $OCZEKIWANA_LICZBA_POLACZEN ]; then fuser -k $SCIEZKA_BARIERY; else cat; fi ' ;} 2>&1  

# Sprawdzenie czy udalo sie utworzyc proces ncat 
read odbior <&${PODPROCES_bariery[0]}
read odbior <&${PODPROCES_bariery[0]}
if [ "Ncat: Listening on $SCIEZKA_BARIERY" != "$odbior" ]; then
   echo "Zakonczenie z powodu nieudanej proby otwarcia gniazda $SCIEZKA_BARIERY"
   exit 1;
fi

#URUCHOMIENIE FILOZOFOW
for i in `shuf -i 1-$LICZBA_FILOZOFOW`; do

	SCIEZKA_TYMCZASOWA=${SCIEZKA_POTOKU}"_"${i}
    rm -f ${SCIEZKA_TYMCZASOWA};
    mkfifo ${SCIEZKA_TYMCZASOWA};

	#USTALANIE KOLEJNOSCI DOBIERANIA WIDELCOW
	if [[ $(($i % 2)) == 1 ]]; then
		declare PIERWSZY_WIDELEC="$i"
	    declare DRUGI_WIDELEC="$(($i + 1))"
	    if [[ $DRUGI_WIDELEC == "$(($LICZBA_FILOZOFOW + 1))" ]]; then DRUGI_WIDELEC=1; fi;
    else
      	declare DRUGI_WIDELEC="$i"
	    declare PIERWSZY_WIDELEC="$(($i + 1))"
	    if [[ $PIERWSZY_WIDELEC == "$(($LICZBA_FILOZOFOW + 1))" ]]; then 
	    	PIERWSZY_WIDELEC=1; fi;
    fi;   
    
    
	
    #KOMUNIKAT URUCHAMIANIE PROCESU FILOZOFA    
	if test ${CZAS_ROZMYSLANIA:-losowe} = "losowe"  ;then
		komunikat "(-)" "<$(hostname)> STARTUJE FILOZOF o FID:$i | Liczba posilkow:$LICZBA_POSILKOW | Liczba filozofow:$LICZBA_FILOZOFOW 
		| Sciezka katalogu-stolu:$SCIEZKA_KATALOGU | Plik bariery:$SCIEZKA_BARIERY | Plik potoku: $SCIEZKA_TYMCZASOWA | Pierwszy widelec WID:$PIERWSZY_WIDELEC | Drugi widelec WID:$DRUGI_WIDELEC\n"
	  	filozof $i $LICZBA_POSILKOW $LICZBA_FILOZOFOW $SCIEZKA_KATALOGU $SCIEZKA_BARIERY $PIERWSZY_WIDELEC $DRUGI_WIDELEC $SCIEZKA_TYMCZASOWA &
	else
		komunikat "(-)" "<$(hostname)> STARTUJE FILOZOF o FID:$i | Liczba posilkow:$LICZBA_POSILKOW | Liczba filozofow:$LICZBA_FILOZOFOW 
		| Sciezka katalogu-stolu:$SCIEZKA_KATALOGU | Plik bariery:$SCIEZKA_BARIERY | Plik potoku: $SCIEZKA_TYMCZASOWA | Pierwszy widelec WID:$PIERWSZY_WIDELEC | Drugi widelec WID:$DRUGI_WIDELEC | Czas konsumpcji:$CZAS_KONSUMPCJI s | Czas rozmyslania: $CZAS_ROZMYSLANIA s\n"
		filozof $i $LICZBA_POSILKOW $LICZBA_FILOZOFOW $SCIEZKA_KATALOGU $SCIEZKA_BARIERY $PIERWSZY_WIDELEC $DRUGI_WIDELEC $SCIEZKA_TYMCZASOWA $CZAS_KONSUMPCJI $CZAS_ROZMYSLANIA &
	fi
done

#oczekiwanie na wszystkich filozofow
komunikat "(-)" "********** Oczekuje na zgloszenie dotarcia do bariery od kazdego filozofa\n"
ncat -U $SCIEZKA_BARIERY -c 'read'
komunikat "(-)"  "********** Bariera polowy posilkow zwolniona - Wszyscy filozofowie zjedli polowe posilkow\n"

# zwolnienie bariery polowy posilkow
for i in `shuf -i 1-$LICZBA_FILOZOFOW`; do
    declare SCIEZKA_POTOKU_FILOZOFA="${SCIEZKA_POTOKU}_$i"
    echo "kontynuuj" >> ${SCIEZKA_POTOKU_FILOZOFA}
done
# filozofowie kontynuuja uczte


wait

czyPosprzatac $SCIEZKA_BARIERY $SCIEZKA_KATALOGU $SCIEZKA_POTOKU $LICZBA_FILOZOFOW

exit 0


# MOZLIWE KODY WYJSCIA "uruchom.sh"
#	1 - Zakonczenie z powodu nieudanej proby otwarcia gniazda
#	2 - Nieprawidlowy parametr: podano ujemna liczbe zamiast dodatniej
#	3 - Nieprawidlowy parametr: podano liczbe niecalkowita zamiast naturalnej
#	4 - Nieprawidlowy parametr: podano znaki zamiast liczby 
