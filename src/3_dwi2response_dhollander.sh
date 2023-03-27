# Response Function Estimation using dhollander method 
# run in prep for multi-shell multi-tissue CSD
# by Meaghan Perdue
# 27 March 2023

#set directory names based on directories in HPC
#bids directory
export bids_dir=/Volumes/catherine_team/Trainee_Folders/mvperdue/preschool/bids_test
#output directory
export mrtrix_out=/Volumes/catherine_team/Trainee_Folders/mvperdue/preschool/bids_test/derivatives/mrtrix

cd $mrtrix_out/${1}/${2}

#run response function estimation
dwi2response dhollander ${1}_${2}_dwi_preprocessed.mif wm_response.txt gm_response.txt csf_response.txt -voxels voxels.mif  -debug

#upsample DWI data for improvement of later template building, registration, tractography & stats (per mrtrix documentation)
mrgrid ${1}_${2}_dwi_preprocessed.mif regrid -vox 1.25 dwi_preproc_upsampled.mif -debug 

#create mask of upsampled dwi, check for holes or too-liberal masking, use FSL-bet instead if needed
dwi2mask dwi_preproc_upsampled.mif dwi_mask_upsampled.mif -debug
