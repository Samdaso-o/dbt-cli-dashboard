#!/bin/bash
### dbt CLI Dashboard
### Made by Eric Han / hoon2510327@gmail.com
### Adapted by [Your Name] [Your Email] [Date]

## Make sure build DIR
BUildDirConf="${HOME}/build_dir.conf"
	if [ ! -f ${BUildDirConf} ]; then
		touch  ${BUildDirConf}
	fi
extra_input=$1
BuildDir=$(cat ${BUildDirConf})
exefile=$(command -v dbt)

## OS Check
if [[ $(uname) == Linux ]]; then
	osv="linux"
elif [[ $(uname) == Darwin ]]; then
	osv="osx"
fi

## Temporary file create for work memory
Tmp_modelsfile="${HOME}/dbt_modtmp.txt"
Tmp_runsfile="${HOME}/dbt_runtmp.txt"

exit_abnormal() {
	stty echo
	rm -f ${Tmp_modelsfile} ${Tmp_runsfile} 2> /dev/null
	exit 1
}

### Break sign catch for line break fix
trap exit_abnormal SIGINT SIGTERM

BAR="========================================================================================================================================================="
{
echo ${BAR}
echo "   [:: dbt Models ::]"
echo ${BAR}
dbt ls --models | awk '{printf "%.2d | "$0"\n",NR-1}' | sed -e 's/^00/  /g'
} >| ${Tmp_modelsfile}

{
echo ""
echo ""
echo ${BAR}
echo "   [:: Recent Runs ::]"
echo ${BAR}
dbt debug | awk '{printf "%.2d | "$0"\n",NR-1}' | sed -e 's/^00/  /g'
} >| ${Tmp_runsfile}

if [[ $osv = "osx" ]]; then
	for tmpfiles in ${Tmp_modelsfile} ${Tmp_runsfile}; do
		sed -i "" 's/^0 /  /g' ${tmpfiles}
	done
else
	for tmpfiles in ${Tmp_modelsfile} ${Tmp_runsfile}; do
		sed -i 's/^0 /  /g' ${tmpfiles}
	done
fi

Print_screen() {
## Print screen
clear -x
cat ${Tmp_modelsfile} ${Tmp_runsfile}

echo ""
echo ""
echo "======================================"
echo " Please Insert a command as below  :) "
echo " Run the models -------- [ run ] | Build models ------------ [ build ] | Test models ----------- [ test ]"
echo " Debug project --------- [ debug ] | Clean project --------- [ clean ] | Exit ------------------- Ctrl+c"
echo "======================================"
printf "CMD>> "
}

if [[ ${extra_input} = "" ]]; then
	Print_screen
	read -r CommandX
else
	CommandX=${extra_input}
fi

## Make a number & array
ModelNum=$(tail -1 ${Tmp_modelsfile} | awk '{print $1}')
RunNum=$(tail -1 ${Tmp_runsfile} | awk '{print $1}')
ModelArray=($(cat ${Tmp_modelsfile} | awk '{print $3}' | tail -n +4))

## Function for dbt commands
run_models() {
	dbt run --models ${ModelArray[$1]}
}

build_models() {
	if [[ ! -d ${BuildDir} ]]; then
		echo "${BAR}"
		echo " Please insert a Directory for models build [ex) /data/git/dbt_models_dir]"
		read -r ReadDir
		echo "${ReadDir}" > ${BUildDirConf}
		cd ${ReadDir} || return
	else
		cd ${BuildDir} || return
	fi

	if [[ ! -f ./dbt_build_auto.sh ]]; then
		echo "${BAR}"
		echo "Do you need to install dbt_build_auto.sh here? [ y/n ]"
		read -r Answ
		if [[ ${Answ} = "y" ]] || [[ ${Answ} = "Y" ]]; then
			wget example.com/dbt_build_auto.sh
			chmod 755 dbt_build_auto.sh
		else
			echo "${BAR}"
			echo "You need to install the dbt_build_auto.sh script for this work"
			echo "${BAR}"
			exit 0
		fi
	fi
	./dbt_build_auto.sh
}

debug_project() {
	dbt debug
}

clean_project() {
	dbt clean
}

test_models() {
	dbt test --models ${ModelArray[$1]}
}

case "${CommandX}" in
	build)
		build_models
		;;
	run)
		echo " == Please insert a model number [01 - ${ModelNum} ]"
		read -r ModelNum
		if [[ ${ModelNum} != "" ]]; then
			run_models ${ModelNum}
		else
			echo " == No Model ID == "
		fi
		;;
	debug)
		debug_project
		;;
	clean)
		clean_project
		;;
	test)
		echo " == Please insert a model number to test [01 - ${ModelNum} ]"
		read -r ModelNum
		if [[ ${ModelNum} != "" ]]; then
			test_models ${ModelNum}
		else
			echo " == No Model ID == "
		fi
		;;
	*)
		dbt ${CommandX}
		;;
esac

if [[ ${extra_input} = "" ]]; then
	${exefile}
fi
