# dMRI preprocessing for Preschool data with 1 b-val (b750) for CSD in MRtrix
# by Meaghan Perdue
# 10 April 2023

#set directory names based on directories in HPC
#bids directory
export bids_dir=/Volumes/catherine_team/Project_Folders/Preschool/preschool_bids
#output directory
export mrtrix_out=/Volumes/catherine_team/Project_Folders/Preschool/preschool_bids/derivatives/mrtrix

cd $bids_dir

#create a subject folder in the mrtrix directory, sub-folder for session, and sub-folder for preprocessing outputs
mkdir $mrtrix_out/${1}
mkdir $mrtrix_out/${1}/${2}
mkdir $mrtrix_out/${1}/${2}/preproc

#convert both DWI runs to .mif format 
mrconvert ${1}/${2}/dwi/${1}_${2}_acq-b750_dwi.nii.gz $mrtrix_out/${1}/${2}/preproc/dwi_b750.mif -fslgrad $bids_dir/Preschool_b750.bvec $bids_dir/Preschool_b750.bval -json_import $bids_dir/${1}/${2}/dwi/${1}_${2}_acq-b750_dwi.json -json_export $mrtrix_out/${1}/${2}/preproc/dwi_b750.json 

# try denoising with extent=7
dwidenoise $mrtrix_out/${1}/${2}/preproc/dwi_b750.mif $mrtrix_out/${1}/${2}/preproc/dwi_denoise.mif -extent 7 -noise $mrtrix_out/${1}/${2}/preproc/noise.mif -info -force
mrcalc $mrtrix_out/${1}/${2}/preproc/dwi_b750.mif $mrtrix_out/${1}/${2}/preproc/dwi_denoise.mif -subtract $mrtrix_out/${1}/${2}/preproc/res.mif -force


#perform Gibbs Ringing correction via MRTrix3
mrdegibbs $mrtrix_out/${1}/${2}/preproc/dwi_denoise.mif $mrtrix_out/${1}/${2}/preproc/dwi_degibbs.mif -info
# # #not sure if this really accomplishes much, but it doesn't take much time

#DWI preprocessing via FSL's eddy correct for eddy current correction and motion correction
#eddy options slm=linear set due to small number of directions (<60), must include space inside quotes for eddy options to work
#use openmp for faster processing, change nthreads as appropriate
dwifslpreproc $mrtrix_out/${1}/${2}/preproc/dwi_degibbs.mif $mrtrix_out/${1}/${2}/${1}_${2}_dwi_ss_preprocessed.mif \
	-eddy_options " --slm=linear" \
	-rpe_none -pe_dir AP \
	-eddyqc_all $mrtrix_out/${1}/${2}/${1}_${2}.qc \
	-nthreads 8 \
	-force

# #Create a brain mask based on preprocessed DWI for use in speeding up subsequent analysis
#preprocessed DWI and mask saved to subject's derivatives/mrtrix folder
dwi2mask $mrtrix_out/${1}/${2}/dwi_ss_preprocessed.mif $mrtrix_out/${1}/${2}/${1}_${2}_mask.mif -force

# # #Convert preprocessed output and mask to .nii for QC via eddy_quad
mrconvert $mrtrix_out/${1}/${2}/${1}_${2}_dwi_ss_preprocessed.mif $mrtrix_out/${1}/${2}/${1}_${2}_dwi_ss_preprocessed.nii.gz -export_grad_fsl $mrtrix_out/${1}/${2}/${1}_${2}_dwi_ss_preprocessed.bvec $mrtrix_out/${1}/${2}/${1}_${2}_dwi_ss_preprocessed.bval -json_export $mrtrix_out/${1}/${2}/${1}_${2}_dwi_ss_preprocessed.json -force
mrconvert $mrtrix_out/${1}/${2}/${1}_${2}_mask.mif $mrtrix_out/${1}/${2}/${1}_${2}_mask.nii.gz -force

echo ${1} ${2} singleshell >> $mrtrix_out/dwi_preprocessed.txt
