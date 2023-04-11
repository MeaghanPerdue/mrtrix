# to run a single subject, pass subject id and session to processing script

if [ -f "/Volumes/catherine_team/Project_Folders/Preschool/preschool_bids/${1}/${2}/dwi/${1}_${2}_acq-b2000_dwi.nii.gz" ]
then
    echo "run multishell"
    sh 1_preproc_multishell.sh ${1} ${2}
fi

if [ -f "/Volumes/catherine_team/Project_Folders/Preschool/preschool_bids/${1}/${2}/dwi/${1}_${2}_acq-b750_dwi.nii.gz" ] && [ ! -f "/Volumes/catherine_team/Project_Folders/Preschool/preschool_bids/${1}/${2}/dwi/${1}_${2}_acq-b2000_dwi.nii.gz" ]
then 
    echo "run single shell"
    sh 1_preproc_singleshell.sh ${1} ${2}
fi