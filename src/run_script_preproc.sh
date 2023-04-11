# to run a single subject, pass subject id and session to processing script

if [ -f "/Volumes/catherine_team/Trainee_Folders/mvperdue/preschool/bids_test/${1}/${2}/dwi/${1}_${2}_acq-b2000_dwi.nii.gz" ]
then
    echo "run multishell"
    sh 1_preproc_multishell.sh ${1} ${2}
else
    echo "run single shell"
    sh 1_preproc_singleshell.sh ${1} ${2}
fi