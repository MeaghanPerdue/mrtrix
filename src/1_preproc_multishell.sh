# dMRI preprocessing for Preschool data with 2 b-vals for CSD in MRtrix
# by Meaghan Perdue
# 24 March 2023

#set directory names based on directories in HPC
#bids directory
export bids_dir=/Volumes/catherine_team/Trainee_Folders/mvperdue/preschool/bids_test
#output directory
export mrtrix_out=/Volumes/catherine_team/Trainee_Folders/mvperdue/preschool/bids_test/derivatives/mrtrix

cd $bids_dir

#create a subject folder in the mrtrix directory, sub-folder for session, and sub-folder for preprocessing outputs
mkdir $mrtrix_out/${1}
mkdir $mrtrix_out/${1}/${2}
mkdir $mrtrix_out/${1}/${2}/preproc_multishell

#convert both DWI runs to .mif format 
mrconvert ${1}/${2}/dwi/${1}_${2}_acq-b750_dwi.nii.gz $mrtrix_out/${1}/${2}/preproc_multishell/dwi_b750.mif -fslgrad $bids_dir/Preschool_b750.bvec $bids_dir/Preschool_b750.bval -json_import $bids_dir/${1}/${2}/dwi/${1}_${2}_acq-b750_dwi.json -json_export $mrtrix_out/${1}/${2}/preproc_multishell/dwi_b750.json 
mrconvert ${1}/${2}/dwi/${1}_${2}_acq-b2000_dwi.nii.gz $mrtrix_out/${1}/${2}/preproc_multishell/dwi_b2000.mif -fslgrad $bids_dir/Preschool_b2000.bvec $bids_dir/Preschool_b2000.bval -json_import $bids_dir/${1}/${2}/dwi/${1}_${2}_acq-b2000_dwi.json -json_export $mrtrix_out/${1}/${2}/preproc_multishell/dwi_b2000.json 

#b750 has 54 slices, b2000 has 42 slices, need to match in order to concatenate, so crop b750 down to 42, taking 6 slices off the top and 6 of the bottom
mrgrid $mrtrix_out/${1}/${2}/preproc_multishell/dwi_b750.mif crop -axis 2 6,6 $mrtrix_out/${1}/${2}/preproc_multishell/dwi_b750_crop.mif 

#concatenate converted dwi runs into a single file (topup/eddy handle registration/alignment automatically)
mrcat $mrtrix_out/${1}/${2}/preproc_multishell/dwi_b750_crop.mif $mrtrix_out/${1}/${2}/preproc_multishell/dwi_b2000.mif $mrtrix_out/${1}/${2}/preproc_multishell/dwi_concat.mif 

# extract first b0 volume to use for registration
mrconvert $mrtrix_out/${1}/${2}/preproc_multishell/dwi_b750.mif  -coord 3 0 -axes 0,1,2 $mrtrix_out/${1}/${2}/preproc_multishell/dwi_b0.mif -force
#register T1w image to DWI (moving template)
mrregister -type rigid $bids_dir/${1}/${2}/anat/${1}_${2}_T1w.nii.gz $mrtrix_out/${1}/${2}/preproc_multishell/dwi_b0.mif -transformed $mrtrix_out/${1}/${2}/T1w_reg2dwi.mif -force

#perform mrtrix denoising, first step in DWI preproc
# dwidenoise $mrtrix_out/${1}/${2}/preproc_multishell/dwi_concat.mif -extent 9 $mrtrix_out/${1}/${2}/preproc_multishell/dwi_denoise.mif -noise $mrtrix_out/${1}/${2}/preproc_multishell/noise.mif -info -force
# mrcalc $mrtrix_out/${1}/${2}/preproc_multishell/dwi_concat.mif $mrtrix_out/${1}/${2}/preproc_multishell/dwi_denoise.mif -subtract $mrtrix_out/${1}/${2}/preproc_multishell/res.mif -force
#there was anatomy visible in the residuals for the subject I tested (I tried both default extent (5) and manual extent (7 & 9)), so we might just skip denoising; probably we don't have enough DW volumes/redundancy for the algorithm (n=60)

#perform Gibbs Ringing correction via MRTrix3
mrdegibbs $mrtrix_out/${1}/${2}/preproc_multishell/dwi_concat.mif $mrtrix_out/${1}/${2}/preproc_multishell/dwi_degibbs.mif -info
#not sure if this really accomplishes much, but it doesn't take much time

#DWI preprocessing via FSL's eddy correct for eddy current correction and motion correction
#eddy options slm=linear set due to small number of directions (<60), must include space inside quotes for eddy options to work
#use openmp for faster processing, change nthreads as appropriate
dwifslpreproc $mrtrix_out/${1}/${2}/preproc_multishell/dwi_degibbs.mif $mrtrix_out/${1}/${2}/${1}_${2}_dwi_preprocessed.mif \
	-eddy_options " --slm=linear" \
	-rpe_none -pe_dir AP \
	-eddyqc_all ${1}/${2}/${1}_${2}.qc \
	-nthreads 8 

#Create a brain mask based on preprocessed DWI for use in speeding up subsequent analysis
#preprocessed DWI and mask saved to subject's derivatives/mrtrix folder
dwi2mask $mrtrix_out/${1}/${2}/dwi_preprocessed.mif $mrtrix_out/${1}/${2}/${1}_${2}_mask.mif 

#Convert preprocessed output and mask to .nii for QC via eddy_quad
mrconvert $mrtrix_out/${1}/${2}/${1}_${2}_dwi_preprocessed.mif $mrtrix_out/${1}/${2}/${1}_${2}_dwi_preprocessed.nii.gz -export_grad_fsl $mrtrix_out/${1}/${2}/${1}_${2}_dwi_preprocessed.bvec $mrtrix_out/${1}/${2}/${1}_${2}_dwi_preprocessed.bval -json_export $mrtrix_out/${1}/${2}/${1}_${2}_dwi_preprocessed.json -force
mrconvert $mrtrix_out/${1}/${2}/${1}_${2}_mask.mif $mrtrix_out/${1}/${2}/${1}_${2}_mask.nii.gz


