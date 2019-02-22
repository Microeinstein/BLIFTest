#!/bin/bash

escR="\e[1;31m"
escG="\e[1;32m"
escY="\e[1;33m"
escW="\e[1;39m"
esc0="\e[0m"
helpText="${escW}BLIFTest 1.1   by Microeinstein
Build and execute simulation tests for SIS projects.${esc0}
  
  ${escY}Usage:${esc0}
    Fast test:  ./bliftest.sh fsmd.blif <tests>
    Build:      ./bliftest.sh -b full.simtest <tests>
        Useful in case of high number of <tests>
    Execute:    ./bliftest.sh fsmd.blif full.simtest[,tests]
    Help:       ./bliftest.sh -h

  ${escY}Test parameters: (spaces are allowed everywhere)${esc0}
    in        Input bits
    [=out]    Expected output bits
              (if '*' prints the output without test)
    [=name]   Name of the test
    [,in...]  Append another simulation 
  
  ${escY}Examples:${esc0}
    ./bliftest.sh  or4.blif   0101
    ./bliftest.sh  or4.blif   0101=1
    ./bliftest.sh  or4.blif   0101 = 1
    ./bliftest.sh  or4.blif   0 1 0 1 = 1
    ./bliftest.sh  mux4.blif  1 1010 1111 = 1111
    ./bliftest.sh  -b full.simtest  1100, 0110=1 000, 0001=*=Result
    ./bliftest.sh  fsm.blif  full.simtest
    ./bliftest.sh  fsm.blif  full.simtest,0011=0010=such cool very wow

"

function printErr {
	printf "${escR}$*${esc0}\n"
}
function printOk {
	printf "${escG}$*${esc0}\n"
}
function printInfo {
	printf "${escW}$*${esc0}\n"
}
function prevLine {
	printf "\e[1F\e[2K"
}
function printHelp {
	printf "$helpText"
}
function setStatus {
	#prevLine
	#echo "$*"
	printf "\e[1F\e[2K%s\n" "$*"
}
function getProgress {
	min="$1"
	max="$2"
	val="$3"
	width=40
	perc=$(( ($val + 1 - $min) * $width / ($max - $min) ))
	#echo $perc
	prog=""
	for ((i=0; i<$width; i++)); do
		if [ $i -ge $perc ]; then
		    prog="$prog▒"
		else
		    prog="$prog█"
		fi
	done
	hund=$(( $perc * 100 / $width ))
	echo "$prog ($val/$max, $hund%)"
}
function textToArray { #Compatibility with older versions of bash
	local f="$(cat $1)"
	local a="$2"
	local i=0
	while IFS= read -r line; do
		eval "${a}[$i]"=\$line
		let i++
	done <<< "$f"
	#eval "less <<< \"\${$a[@]}\""
}


# Modalità
arg1="$1"
buildMode=
if [[ "$arg1" == "-h" ]]; then
	printHelp
	exit
elif [[ "$arg1" == "-b" ]]; then
	buildMode=1
	file="$2"
	if [ "${#file}" -eq 0 ]; then
		printErr "Missing result filename..."
		printHelp
		exit 4
	elif [[ "$(basename $file)" == *[=,]* ]]; then
		printErr "Bad filename format:\n  <equal> and <comma> are used to parse tests..."
		printHelp
		exit 4
	fi
	shift 2
else
	file="$1"
	if [ "${#file}" -eq 0 ]; then
		printErr "Unspecified file..."
		printHelp
		exit 1
	fi
	if ! [ -f "$file" ]; then
		printErr "File not found..."
		printHelp
		exit 2
	fi
	if ! [[ "$file" =~ \.blif$ ]]; then
		printErr "Not a blif..."
		printHelp
		exit 3
	fi
	shift 1
fi


# Argomenti restanti
args="$*"
workdir="$(mktemp -d 'bliftest.XXXXXXXXXX' -p /tmp)"
stdin="${workdir}/in.txt"
expectedf="${workdir}/exp.txt"
messagesf="${workdir}/msg.txt"
echo
setStatus "Parsing arguments..."


# Parsing
if ! [ $buildMode ]; then
	echo "read_blif $file" > "$stdin"
fi

# Se non c'è alcuna virgola ed alcun uguale, significa che non si vogliono aggiungere altri test
if ! [ $buildMode ] && [ -f "$args" ] && ! [[ "$args" == *[=,]* ]]; then
	l=0
	while IFS='' read -r line
	do
		case $l in
			"0") base64 -d -w 0 <<< "$line" >> "$stdin" ;;
			"1") textToArray - expected <<< "$(base64 -d -w 0 <<< $line)" ;;
			"2") textToArray - messages <<< "$(base64 -d -w 0 <<< $line)" ;;
		esac
		let l++
	done < "$args"
	#less "$stdin"
	#less <<< "${expected[@]}"
	#rm -rf "$workdir"
	#exit
else
	amount=0
	tn=0
	len=-1
	IFS=','
	read -ra tests <<< "$args"
	for test in "${tests[@]}"; do
		let amount++
	done
	IFS='='

	function parseSim {
		local tn=$1
		cd "$workdir"
		local fin="${tn}.in"
		local fexp="${tn}.exp"
		local fmsg="${tn}.msg"
		local test="${tests[$tn]}"
		if [ -f "$test" ]; then
			local l=0
			while IFS= read -r line; do
				case $l in
					"0")
						in=$(base64 -d <<< "$line")
						read -r line1 <<< "$in"
						line1=$(sed -r 's/[^01]+//g' <<< "$line1" | sed 's/./& /g' | xargs)
						local llen="${#line1}"
						if [ "$len" -eq "-1" ]; then
							len="$llen"
						elif [ "$len" -ne "$llen" ]; then
							printErr "Inconsistent input length..."
							exit 7
						fi
						echo "$in" >> "$fin"
						;;
					"1") base64 -d <<< "$line" >> "$fexp" ;;
					"2") base64 -d <<< "$line" >> "$fmsg" ;;
				esac
				let l++
			done < "$test"
		else
			read -ra bits <<< "$test"
			in=$(sed -r s/[^01]+//g <<< "${bits[0]}" | sed 's/./& /g' | xargs)
			exp=$(sed -r s/[^01\*]*//g <<< "${bits[1]}")
			msg="${bits[2]}"
			let tn++
			if [ "${#in}" -eq "0" ]; then
				printErr "Input is required... (test #$tn)"
				exit 5
			fi
			local llen="${#in}"
			if [ "$len" -eq "-1" ]; then
				len="$llen"
			elif [ "$len" -ne "$llen" ]; then
				printErr "Inconsistent input length..."
				exit 6
			fi
			echo "simulate $in" >> "$fin"
			echo "$exp" >> "$fexp"
			echo "$msg" >> "$fmsg"
		fi
	}

	for ((i=0; i<$amount; i++)); do
		setStatus "Parsing arguments...      $(getProgress 0 $amount $i)"
		parseSim $i &
	done
	setStatus "Parsing arguments... (waiting jobs to finish)"
	wait
	
	setStatus "Concatenating commands..."
	cd "$workdir"
	for ((i=0; i<$amount; i++)); do
		cat "${i}.in" >> "$stdin"
	done &
	for ((i=0; i<$amount; i++)); do
		cat "${i}.exp" >> "$expectedf"
	done &
	for ((i=0; i<$amount; i++)); do
		setStatus "Concatenating commands... $(getProgress 0 $amount $i)"
		cat "${i}.msg" >> "$messagesf"
	done &
	wait
	#cd - > /dev/null
	#less "$expectedf"
	#rm -rf "$workdir"
	#exit
	
	if [ $buildMode ]; then
		base64 -w 0 < "$stdin" > "$file"
		echo >> "$file"
		base64 -w 0 < "$expectedf" >> "$file"
		echo >> "$file"
		base64 -w 0 < "$messagesf" >> "$file"
		echo >> "$file"
		rm -rf "$workdir"
		prevLine
		printOk "Build successful."
		exit 0
	fi
	textToArray "$expectedf" expected
	textToArray "$messagesf" messages
	rm "$expectedf" "$messagesf"
fi

if ! [ $buildMode ]; then
	echo "quit" >> "$stdin"
fi


setStatus Executing SIS...
stdout=$(sis -f "$stdin" -s -x 2>&1)
siserr=$?
rm -rf "$workdir"
if [ $siserr -eq 139 ]; then # Segmentation fault...
	printErr "SIS has gone in Segmentation Fault, sorry but nothing can be done... (I tried) :("
	exit -1
fi

setStatus Searching for errors...
err=$(egrep -o -a -m 1 'network has [0-9]+ inputs; [0-9]+ values were supplied.' <<< $stdout)
err=$(sed -r 's/[a-z ]+?([0-9]+)[a-z ;]+?([0-9]+).+/in=\2, expected=\1/g' <<< $err)
#' gedit syntax color bug

if [ "${#err}" -gt "0" ]; then
	printErr "Input mismatch: $err"
	exit 8
fi

setStatus Parsing output...
stdout=$(egrep -o -a 'Outputs:.+' <<< "$stdout" | sed -r s/[^01]*//g | tr '\n' ',')
stdout=${stdout%,*}

prevLine
ok=0
inout=0
tn=0
IFS=','
read -ra results <<< "$stdout"
for res in "${results[@]}"; do
	exp="${expected[$inout]}"
	msg="${messages[$inout]}"
	
	if [ "${#exp}" -eq "0" ]; then
		:
	elif [[ "$exp" == "*" ]]; then
		pri="Simulation:"
		if [ "${#msg}" -gt "0" ]; then
			pri="$pri\t($msg)"
		fi
		printInfo "$pri"
		printf "  O>${res}\n\n"
	elif [[ "$res" == "$exp" ]]; then
		let ok++
		let tn++
		pri="Test #$tn: OK"
		if [ "${#msg}" -gt "0" ]; then
			pri="$pri\t($msg)"
		fi
		printOk "$pri"
		printf "  O>${res}\n  E>${exp}\n\n"
	else
		let tn++
		pri="Test #$tn: ERROR"
		if [ "${#msg}" -gt "0" ]; then
			pri="$pri\t($msg)"
		fi
		printErr "$pri"
		printf "  O>${res}\n  E>${exp}\n\n"
	fi
	let inout++
done

if [ "$ok" -eq "$tn" ]; then
	printOk "Test passed: $ok/$tn (ALL)"
	if [ "$tn" -gt 1 ]; then
		printOk "Good job!"
	fi
else
	printErr "Test passed: $ok/$tn"
fi
