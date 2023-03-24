# dMRI preprocessing for Preschool data with 2 b-vals for CSD in MRtrix
# by Meaghan Perdue
# 24 March 2023

#set directory names based on directories in HPC
#bids directory
export bids_dir=/Volumes/catherine_team/mvperdue/preschool/bids_test
#output directory
export mrtrix_out=/Volumes/catherine_team/mvperdue/preschool/bids_test/derivatives/mrtrix

cd $bids_dir

#create a subject folder in the mrtrix directory
mkdir $mrtrix_out/${1}/${2}
mkdir $mrtrix_out/${1}/${2}/preproc_multishell

#convert both DWI runs to .mif format 
mrconvert ${1}/${2}/dwi/${1}_${2}_acq-b750_dwi.nii.gz $mrtrix_out/${1}/${2}/preproc_multishell/dwi_b750.mif -fslgrad .bvec .bval -json_import $bids_dir/${1}/${2}/dwi/${1}_${2}_acq-b750_dwi.json -json_export $mrtrix_out/${1}/${2}/preproc_multishell/dwi_b750.json
mrconvert ${1}/${2}/dwi/${1}_${2}_acq-b2000_dwi.nii.gz $mrtrix_out/${1}/${2}/preproc_multishell/dwi_b2000.mif -fslgrad .bvec .bval -json_import $bids_dir/${1}/${2}/dwi/${1}_${2}_acq-b2000_dwi.json -json_export $mrtrix_out/${1}/${2}/preproc_multishell/dwi_b2000.json

#concatenate converted dwi runs into a single file (topup/eddy handle registration/alignment automatically)
mrcat $mrtrix_out/${1}/${2}/preproc_multishell/dwi_b750.mif $mrtrix_out/${1}/${2}/preproc_multishell/dwi_b2000.mif $mrtrix_out/${1}/${2}/preproc_multishell/dwi_raw.mif

#perform mrtrix denoising, first step in DWI preproc
dwidenoise $mrtrix_out/${1}/${2}/preproc_multishell/dwi_raw.mif $mrtrix_out/${1}/${2}/preproc_multishell/dwi_denoise.mif -noise $mrtrix_out/${1}/${2}/preproc_multishell/noise.mif -info 
mrcalc $mrtrix_out/${1}/${2}/preproc_multishell/dwi_raw.mif $mrtrix_out/${1}/${2}/preproc_multishell/dwi_multishell_denoise.mif -subtract $mrtrix_out/${1}/${2}/preproc_multishell/res.mif

#perform Gibbs Ringing correction via MRTrix3
mrdegibbs $mrtrix_out/${1}/${2}/preproc_multishell/dwi_denoise.mif $mrtrix_out/${1}/${2}/preproc_multishell/dwi_degibbs.mif -info

#DWI preprocessing via FSL's eddy correct for eddy current correction and motion correction
#run this on a GPU/CUDA node for slice-to-volume correction using eddy_cuda
#change nthreads
dwifslpreproc $mrtrix_out/${1}/${2}/preproc_multishell/dwi_degibbs.mif $mrtrix_out/${1}/${2}/dwi_preprocessed.mif \
	-rpe_none -pe_dir AP \
	-eddyqc_all ${1}/${2}/${1}_${2}.qc -nthreads 8 

#Create a brain mask based on preprocessed DWI for use in speeding up subsequent analysis
#preprocessed DWI and mask saved to subject's derivatives/mrtrix folder
dwi2mask $mrtrix_out/${1}/${2}/dwi_preprocessed.mif $mrtrix_out/${1}/${2}/mask.mif -force


#QC by visually inspecting residuals for lack of anatomy:
#mrview res.mif
#QC: visually compare input and output images for removal of Gibbs Ringing
#mrview dwi_denoise.mif dwi_degibbs.mif



