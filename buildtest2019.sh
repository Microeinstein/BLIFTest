#!/bin/bash

function ask {
	while true; do
		read -p "$1 [y/N]? " yn
		case $yn in
			[Yy]* )
				return 1;
				break;;
			* )
				return 0;
				break;;
			#* ) echo "Formato della risposta non valido.";;
		esac
	done
}
echo "La macchina controlla con uno stato in più..."
emplus=$(ask "  ...l'errore di EM=0  "; echo $?)
scplus=$(ask "  ...l'errore di SCARTO"; echo $?)
nbplus=$(ask "  ...l'overflow di NB  "; echo $?)
neplus=$(ask "  ...l'overflow di NE  "; echo $?)
echo

if [ $emplus -eq 1 ]; then
    emfill=",0000000"
else
    emfill=""
fi

if [ $scplus -eq 1 ]; then
    scfill=",0000000"
else
    scfill=""
fi

if [ $nbplus -eq 1 ]; then
    nbfill=",0000000"
else
    nbfill=""
fi

if [ $neplus -eq 1 ]; then
    nefill=",0000000"
else
    nefill=""
fi

#echo $mifill $nbfill $nefill
#exit

allZero="000000 0000 0000 0000 0000 0000"

errMilling="001"
 errScarto="010"
     errNB="101"
     errNE="110"

 accendi="0000000,1110000=1 000 100000 0001 0000 0000 0000 0000=Accensione centralina"
    in63="1111111"
    in15="1001111"
     in2="1000010"
     inE="0111111"

    out1="1000001${scfill}"
   out62="1111110${scfill}"
    outE="0000001${emfill}=0 $errMilling $allZero"

  workok="1000000"
   workE="0000000"

waitgate="0000000"


testEM="$accendi,$in63,$outE=Lavorazione non riuscita"

cicloScarto62="$in63,$out1,$workok,$waitgate"
cicloScarto14="$in15,$out1,$workok,$waitgate"
testScarto="$accendi,$cicloScarto62,$cicloScarto62,$cicloScarto62,$cicloScarto14,$in2,$out1=0 $errScarto $allZero=Scarto > 200"

cicloNB="$inE"
testNB="$accendi,$(yes "$cicloNB,$waitgate," | head -n 15 | tr -d '\n')$cicloNB${nbfill}=0 $errNB $allZero=Overflow NB"

cicloNE="$in2,$out1,$workE"
testNE="$accendi,$cicloScarto62=*=SCARTO: 62,$(yes "$cicloNE,$waitgate," | head -n 15 | tr -d '\n')$cicloNE${nefill}=0 $errNE $allZero=Overflow NE"

full="$testEM,$testScarto,$testNB,$testNE,$testScarto"
#echo "[$full]" | tr ',' '\n'
#echo "[$full]"
#exit

./bliftest.sh -b test2019.simtest "$full"
