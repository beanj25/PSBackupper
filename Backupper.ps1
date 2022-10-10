<############################################################################*
#                         The ITMGR manual Backuper                          #
#                                                                            #
# There is an object that stores the file paths we want                      #
# A loop will then back them all up to the users documents folder            #
#                                                                            #
*############################################################################>
<#
# 8-28-22 
# Basically all works now, but I am missing permissions
# 
#>

<#########################################################################################################*
# notes for when im home 8-20
# basically u just need to put all the paths in
# then keep my folder system
# check phone pic on personal Discord
#ok let me think about my order of operations
#what do I want my script to do
#first I send the script to the PC via syncro
#the script first needs to get the PC name
#then check for a folder with that PC name
#    If that folder exists, thats our location. If it doesnt, create it then set to our location
#after we have a folder with the PC name, we then need to run the robocopy on a list of all the paths
#    Inside robocopy we need to loop the copying process for each user.
#backup-user(a looping function to backup each user)
#    Send that user to robocopy function
#        Robocopy will then copy every path given in the $BACKUP_PATHS array.
#Then once it has looped through all users, exit smoothly.
#### NOTES 8-21-22
# after check directory I need to then run robo copy INSIDE each folder for each items
#CD TO THE PROPER FOLDER OR GET PROPER DESINATION FOLDER
# first we need a list of all the user folders in the PC
# We will do so by getting all the local users
# then we will filter out the ones that are not enabled 

# getting back into this 8-19-22
# basically I need to find a way to copy an item from the local machine to a server machine
# my robot copy tests

*#########################################################################################################>
<#########################################################################################################*
# What I need to do 8-27-22
# Basically neeed to get this folder system made
# Need to store
#    MACHINE_NAME    = EM-9020-XXX									Get from script line one, a global variable
#	USERNAME 		= jdoe											Get get by scraping the users folder
#	BACKUP_PATHS	= Bookmarks, sticky notes, documents, desktop	Get by referencing our global array. Probably create an
#																		array of objects named 'Directory'
#																		with propertoes 'DName' and 'DPath'
# 
#	MACHINE_NAME
# 			USERNAME
#				BACKUP_PATHS
#			USERNAME
#				BACKUP_PATHS
#				BACKUP_PATHS
#				BACKUP_PATHS
#	MACHINE_NAME
# 			USERNAME
#				BACKUP_PATHS
#				BACKUP_PATHS
#			USERNAME
#				BACKUP_PATHS
#				BACKUP_PATHS
#				BACKUP_PATHS
#			USERNAME
#				BACKUP_PATHS
#				
*#########################################################################################################>

#################################
#                               #
# BEGIN user confugrables       #
#                               #
################################*
# $BACKUP_PATHS         #
# spath = source local  #
# dpath = empty         #
# name = name of folder #
# replace any usernames #
# with USERNAME         #
# All caps              #
########################*
$BACKUP_PATHS = @(
[pscustomobject]@{
    spath = "C:\Users\USERNAME\AppData\Local\Google\Chrome\User Data";
    dpath = "";
    name = "Chrome_Bookmarks";
} # chrome bookmarks}
[pscustomobject]@{
    spath = "C:\Users\USERNAME\AppData\Roaming\Microsoft\Sticky Notes";
    dpath = "";
    name = "Sticky_Notes";
} # sticky note data
[pscustomobject]@{
    spath = "C:\Users\USERNAME\Desktop";
    dpath = "";
    name = "Desktop";
} # Desktop
[pscustomobject]@{
    spath = "C:\Users\USERNAME\Documents";
    dpath = "";
    name = "Documents";
} # Documents
[pscustomobject]@{
    spath = "C:\Users\USERNAME\AppData\Roaming\Microsoft\Signatures";
    dpath = "";
    name = "Microsoft_Signatures";
    } # microsoft signatures
)
#########################################
# $IP_TO_LOCATION                       #
# just place any new NAS IPs in here    #
#########################################
$IP_TO_LOCATION = @(
    "192.168.1.235", # Loop
    "192.168.2.230", # Plaza
    "192.168.4.230", # Downtown
    "192.168.7.235", # Albany
    "192.168.12.235" # Midtown
)
#################################
# END  user confugrables        #
#################################
# BEGIN no-touchy               #
#################################
$VerbosePreference = "Continue"
$Usern = "itadmin"
$PWord = ConvertTo-SecureString -String 'Focus4$$$$' -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential $Usern, $PWord
$MACHINE_NAME = hostname
$MACHINE_NAME -replace " ",""
        
<####################################################################*
# Function: Robocopy                                                 #
#                                                                    #
# Description:                                                       #
# Runs Robocopy for each user on given Path(s).                      #
# This will Also get Sub-Directories using a Mirror command          #
*####################################################################>
function Robocopy($MACHINE_USERS) {
    Write-Verbose "Changing directories to the new drive`n"
    cd -Path PSDrive:
    Write-Verbose "Location changed, printing working directory...: `n"
    Get-Location
    Write-Verbose "`n"
    Write-Verbose "`n"
    foreach ($i in $MACHINE_USERS){
        #start our loop for users on the machine
        Write-Verbose "Starting robo copy on"
        Write-Verbose "$i"
        foreach($j in $BACKUP_PATHS){
            #run robo copy on each backup_path for the user
            $tempstr = $j.name
            $j.dpath = "PSDrive:\$MACHINE_NAME\$i\$tempstr"
            $srctemp = $j.spath
            $src = $srctemp.Replace("USERNAME","$i")
            $dst = $j.dpath
            
            Write-Verbose "now copying..."
            Write-Verbose "     src = $src"
            Write-Verbose "     dst = $dst"
            $flg1 = $false
            $flg2 = $false
            if(Test-Path -path $src){Write-Verbose "        Source Found!"; $flg1 = $true} else{Write-Verbose "        Source NOT Found...Skipping";}
            if(Test-Path -path $dst){Write-Verbose "        Destination Found!"; $flg2 = $true} else{Write-Verbose "        Destination NOT Found...exiting now"; exit}
            if(($flg1 -eq $true)-AND ($flg2 -eq $true)){$exitCode = (Start-Process -verb runas -FilePath 'robocopy' -ArgumentList "$src $dst /copy:DAT /ZB /MIR /V /1" -PassThru -Wait -Credential $Credential).ExitCode;Write-Verbose "     ExitCode = $exitCode"}
        }
        Write-Verbose "Robocopy finished! on User: $i`n" 
    }
}
    <###########################################################################################################################
    #   These are the Error code outputs, possible recieve it and then make a ticket based on the errors
    #   Error    Meaning if set
    #    0       No errors occurred, and no copying was done.
    #            The source and destination directory trees are completely synchronized. 
    #    1       One or more files were copied successfully (that is, new files have arrived).
    #    2       Some Extra files or directories were detected. No files were copied
    #            Examine the output log for details. 
    #    4       Some Mismatched files or directories were detected.
    #            Examine the output log. Housekeeping might be required.
    #    8       Some files or directories could not be copied
    #            (copy errors occurred and the retry limit was exceeded).
    #            Check these errors further.
    #    16      Serious error. Robocopy did not copy any files.
    #            Either a usage error or an error due to insufficient access privileges
    #            on the source or destination directories.
    #  These can be combined, giving a few extra exit codes:
    #    3 (2+1) Some files were copied. Additional files were present. No failure was encountered.
    #    5 (4+1) Some files were copied. Some files were mismatched. No failure was encountered.
    #    6 (4+2) Additional files and mismatched files exist. No files were copied and no failures were encountered.
    #            This means that the files already exist in the destination directory
    #    7 (4+1+2) Files were copied, a file mismatch was present, and additional files were present.
    <############################################################################################################################>
    <############################################################################################################################
    # Robo-Copy options
    # /SEC          # Copy files with SECurity (equivalent to /COPY:DATS).
    # /B            #  Copies files in backup mode. Backup mode allows Robocopy to override file and folder permission settings (ACLs).
    #               # This allows you to copy files you might otherwise not have access to, assuming it's being run under an account with sufficient privileges.
    # /COPY:DATSO   # Specifies which file properties to copy. The valid values for this option are:
    #               # D - Data
    #               # A - Attributes
    #               # T - Time stamps
    #               # S - NTFS access control list (ACL)
    #               # O - Owner information
    # /DCOPY:DAT#   # Specifies what to copy in directories. The valid values for this option are:
    #               # D - Data
    #               # A - Attributes
    #               # T - Time stamps
    # /MIR          # Mirrors a directory tree (equivalent to /e plus /purge). Using this option with the /e option and a destination directory, overwrites the destination directory security settings.
    # /FFT          # 
    # /256          # Turns off support for paths longer than 256 characters.
    # /MT           # Creates multi-threaded copies with n threads. n must be an integer between 1 and 128. The default value for n is 8. For better performance, redirect your output using /log option.
    #               # The /mt parameter can't be used with the /ipg and /efsraw parameters.
    # /ZB           # Use restartable mode; if access denied use Backup mode. This option significantly
    #                 reduces copy performance because of checkpointing.
    ############################################################################################################################>


<#############################################################*
# Function: Where-TF-I-Am                                     #
#                                                             #
# Description:                                                #
# gets the current IP adress and then returns the proper root #
*#############################################################>
function Where-TF-I-Am{
    #need to add a step where I cross my return with the correct full ip and return the full ip
    $ipAddress = Get-NetIPAddress -AddressFamily IPv4 | Select-Object -first 1
    $ipRef = $ipAddress.IPAddress.Split('.') | Select-Object -index 2
    $IP_TO_LOCATION | ForEach-Object -Process { if($ipRef -eq ($_.ToString().Split(('.')) | Select-Object -index 2)){return $_}}
}

<###############################################################*
# Function: Get-Users                                           #
#                                                               #
# Description:                                                  #
# creates an array of all the users on the PC                   #
#                                                               #
# Returns: $newUsers                                            #
# Contains: list of local user accounts, if they're on -> store #
*###############################################################>
function Get-Users{
    $temp = Get-ChildItem -Path C:\Users
    $newUsers = @()
    $temp | ForEach-Object -Process {
        #If the name is public or itadmin or itadmin.ACES skip
        if(($_.Name -eq "public" -OR $_.Name -eq "itadmin" -OR $_.Name -eq "itadmin.ACES")){ Write-Verbose "Skipping User:$_`n"}
        else{$newUsers += ,$_;}
    }
    return $newUsers
}

<#######################################################*
# Function: Create-Directories                          #
#                                                       #
# Description:                                          #
# Checks for if all proper Directories exist...         #
# Machine Names, Users, Path names                      #
*#######################################################>
function Create-Directories($MACHINE_USERS){
    #first we check for if our machine name exists as a folder
    Write-Verbose "First Checking for Machine name folder in root`n"
    if (!(Test-Path -path "PSDrive:\$MACHINE_NAME")){
        Write-Verbose "Path does not exist creating directory`n"
        New-Item -Path "PSDrive:" -Name "$MACHINE_NAME" -ItemType "directory"
    }
    #next check for if the user folders already exist
    Write-Verbose "Next Checking our user folders...`n"
    foreach ($i in $MACHINE_USERS){
        if(!(Test-Path -Path "PSDrive:\$MACHINE_NAME\$i")){
            Write-Verbose "Path does not exist creating directory `n    $i`n"
            New-Item -Path "PSDrive:\$MACHINE_NAME" -Name "$i" -ItemType "directory"
        }
        #now I will check if there exists a folder with backup names inside the user folder
        foreach($j in $BACKUP_PATHS){
            $tempstr = $j.name
            if(!(Test-Path -Path "PSDrive:\$MACHINE_NAME\$i\$tempstr")){
                Write-Verbose "Path does not exist creating directory `n    $j`n"
                New-Item -Path "PSDrive:\$MACHINE_NAME\$i" -Name "$tempstr" -ItemType "directory"
            }
        }
    }
}

<###############################################################################*
# Function: Create-PSDrive
#
# Description:
# Creates a temporary drive at network location
*###############################################################################>
function Create-PSDrive{
    #create a PSDrive from the location
    Write-Verbose "Creating PSDrive....`n"
    New-PSDrive -Name "PSDrive" -PSProvider "FileSystem"  -Root "\\192.168.4.230\Sync" -Credential $Credential -Scope Global
    Write-Verbose "Created!`n"
}
<###############################################################################*
# Function: Delete-PSDrive
#
# Description: 
# Deletes or temp drive
*###############################################################################>
function Delete-PSDrive{
    cd -Path C:
    Write-Verbose "removing PSDrive....`n"
    Remove-PSDrive -Name "PSDrive"
    Write-Verbose "Drive 'PSDrive' remove succesfully!`n"
}
#get the IPAddress
$IP = Where-TF-I-Am
#get the machine users
$MACHINE_USERS= Get-Users
#Create the temp drive
Create-PSDrive
#check/create the directories
Create-Directories($MACHINE_USERS)
#run robocopy
Robocopy($MACHINE_USERS)
#delete the temp drive
Delete-PSDrive

