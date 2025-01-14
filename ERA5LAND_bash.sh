##---------------------------------------------------------------
## HEADER
##---------------------------------------------------------------
#!/bin/bash
# $Revision: 0.0 $  $Date: 2017/04/03 00:00:00 $Author: Guillaume HAZEMANN
#           Original function
# $Revision: 0.1 $  $Date: 2017/09/12 00:00:00 $Author: Carine PONCELET
#            Merge launcher (user parameter settings) and bash_script (python_script call)
#            Define the user parameters in a unique file and export to python
#            Correct while loop (check file names, define zero activity)
#            Delete tmux external package (standalone tool)
#            Comment script
# $Revision: 0.2 $  $Date: 2021/03/04 00:00:00 $Author: Emixi Valdez
#            Added lines 65-85. Continue to the next extract when no data is available.
#            Relaunch the request when server problems occur.
##---------------------------------------------------------------
## USER PARAMETERS SETTINGS
##---------------------------------------------------------------
## Define ECMWF request
export StaYear="1950" ## Start date (year)
export StaMonth="01" ## Start date (month)
export StaDay="01" ## Start date (day)
export EndYear="2022" ## End date (year)
export EndMonth="12" ## End date (month)
export EndDay="31" ## End date (day)
export GridRes="0.1/0.1" ## Grid spatial resolution: "Xres/Yres", lat/long degrees
export MeteoVar="39" #Code of the desired meteorological variable: "MeteoVar1/MeteoVar2/.../MeteoVarN"
export NameVar="V1_sol" #Name of meteorological variable
export Area="52/-80/45/-57" ## Geographical extent: "N/W/S/E" coordinates in latlong projection (wgs84 projection system)
export Format="netcdf"
## Define directories
export DirOut="/.../.../.../../" ##Directory where ECMWF data are to be stored
export DirPy="/.../.../" # Python script directory
DirSh="/.../.../" # Bash script directory
##---------------------------------------------------------------
## ECMWF DATA RETRIEVAL - No need to modify
##---------------------------------------------------------------
## Declarations
PyName="ERA5LAND_python.py"
ShName="ERA5LAND_bash.sh"
FilePy=$DirPy$PyName
FileSh=$DirSh$ShName
FailCount=0

MaxAttempt=2
NumAttempt=0
LogFile=$DirPy/ERA5_$(date +%Y-%m-%d_%Hh%Mm%Ss).log

{
	## Launch data retrieval and get download ExitCode
echo -e $(date) " -- Launching $FilePy.
	Parameters used:
		Start date=${StaYear}-${StaMonth}-${StaDay}
		End date  =${EndYear}-${EndMonth}-${EndDay}
		Grid Res  =${GridRes}
		MeteoVar  =${MeteoVar}
		Area      =${Area}
		Output dir=${DirOut}
	"

	## Launch data retrieval and get download ExitCode
	echo -e $(date) " -- Launching $FilePy."
	python3 -u $FilePy &
	PID=$!
	wait $PID
	ExitCode=$?

	while [ $ExitCode != 0 -a $(expr $MaxAttempt - $NumAttempt) -gt 0 ]; do
		NumAttempt=$(expr $NumAttempt + 1)
		echo -e $(date) " -- $FilePy terminated with exit code $ExitCode."

		echo -e $(date) " -- Relaunching $FilePy, attempt $NumAttempt of $MaxAttempt.\n"
		python3 -u $FilePy &
		PID=$!
		wait $PID
		ExitCode=$?
	done

	if [ $ExitCode == 0 ]; then
		echo -e $(date) " -- $FilePy finished succesfully"
	else            
		echo -e $(date) " -- $FilePy terminated with exit code $ExitCode."
		echo -e "Max number of relaunch attempt ($MaxAttempt) reached."
		echo -e "No more automatic relaunch will be performed: check for problems and relaunch manually."  
               
	fi
        
} 2>&1 | tee -a $LogFile
