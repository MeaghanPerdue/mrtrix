# transfer data from Rundle to ARC using rsync
# transfers dwi data only (excludes func, anat, and perf)
# sublist.txt should contain a list of subjects sub-NNNNN no session numbers, script will copy all sessions

export PS_BIDS=/Volumes/catherine_team/MRI_Data/2_BIDS_Datasets/preschool

for i in $(cat sublist.txt); do
    rsync -av $PS_BIDS/${i} --exclude */func --exclude */anat --exclude */perf meaghan.perdue@arc.ucalgary.ca:/home/meaghan.perdue/preschool_bids
    done
