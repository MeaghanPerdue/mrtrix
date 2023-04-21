#!/bin/bash
#SBATCH --partition=cpu2021 
#SBATCH --ntasks=1				      # Request 8 CPU cores
#SBATCH --nodes=1                     # OpenMP requires all tasks running on one node
#SBATCH --cpus-per-task=16               
#SBATCH --time=04:00:00			      # Job should run up to 2 hours
#SBATCH --mail-type=END			      # Trigger email notification
#SBATCH --mail-user=meaghan.perdue@ucalgary.ca  #destination email address

# dMRI preprocessing for Preschool data with 2 b-vals (b750 & b2000) for CSD in MRtrix
# run on HPC
# by Meaghan Perdue
# 20 April 2023
module load openmpi/4.1.1-gnu
module load mrtrix/3.0.4
module load ants/2.3.1
module load fsl/6.0.0-bin
 

#set directory names based on directories in HPC
#bids directory
export bids_dir=/home/meaghan.perdue/preschool_bids
#output directory
export mrtrix_out=/home/meaghan.perdue/mrtrix

#create a subject folder in the mrtrix directory, sub-folder for session, and sub-folder for preprocessing outputs
mkdir $mrtrix_out/${1}
mkdir $mrtrix_out/${1}/${2}
mkdir $mrtrix_out/${1}/${2}/preproc

#convert both DWI runs to .mif format 
mrconvert $bids_dir/${1}/${2}/dwi/${1}_${2}_acq-b750_dwi.nii.gz $mrtrix_out/${1}/${2}/preproc/dwi_b750.mif -fslgrad $bids_dir/Preschool_b750.bvec $bids_dir/Preschool_b750.bval -json_import $bids_dir/${1}/${2}/dwi/${1}_${2}_acq-b750_dwi.json -json_export $mrtrix_out/${1}/${2}/preproc/dwi_b750.json 
mrconvert $bids_dir/${1}/${2}/dwi/${1}_${2}_acq-b2000_dwi.nii.gz $mrtrix_out/${1}/${2}/preproc/dwi_b2000.mif -fslgrad $bids_dir/Preschool_b2000.bvec $bids_dir/Preschool_b2000.bval -json_import $bids_dir/${1}/${2}/dwi/${1}_${2}_acq-b2000_dwi.json -json_export $mrtrix_out/${1}/${2}/preproc/dwi_b2000.json 

#b750 has 54 slices, b2000 has 42 slices, need to match in order to concatenate, so pad b2000 to match b750
mrgrid $mrtrix_out/${1}/${2}/preproc/dwi_b2000.mif pad -as $mrtrix_out/${1}/${2}/preproc/dwi_b750.mif -fill nan $mrtrix_out/${1}/${2}/preproc/dwi_b2000_pad.mif 

#co-register the DWI runs for concatenation (b2000 to b750)
mrregister -type rigid $mrtrix_out/${1}/${2}/preproc/dwi_b2000_pad.mif $mrtrix_out/${1}/${2}/preproc/dwi_b750.mif -transformed $mrtrix_out/${1}/${2}/preproc/dwi_b2000_pad_reg2b750.mif 

#concatenate converted dwi runs into a single file (topup/eddy handle registration/alignment automatically)
mrcat $mrtrix_out/${1}/${2}/preproc/dwi_b750.mif $mrtrix_out/${1}/${2}/preproc/dwi_b2000_pad_reg2b750.mif $mrtrix_out/${1}/${2}/preproc/dwi_concat.mif 

#perform Gibbs Ringing correction via MRTrix3
mrdegibbs $mrtrix_out/${1}/${2}/preproc/dwi_concat.mif $mrtrix_out/${1}/${2}/preproc/dwi_degibbs.mif -info 

#DWI preprocessing via FSL's eddy correct for eddy current correction and motion correction
#eddy options slm=linear set due to small number of directions (<60), must include space inside quotes for eddy options to work
#use openmp for faster processing, change nthreads as appropriate
dwifslpreproc $mrtrix_out/${1}/${2}/preproc/dwi_degibbs.mif $mrtrix_out/${1}/${2}/preproc/${1}_${2}_dwi_ms_eddy.mif \
	-eddy_options " --slm=linear --repol" \
	-rpe_none -pe_dir AP \
	-eddyqc_all $mrtrix_out/${1}/${2}/${1}_${2}.qc \
	-nthreads 16 
	

# Run bias correction (testing this to see how the masks look)
dwibiascorrect ants $mrtrix_out/${1}/${2}/preproc/${1}_${2}_dwi_ms_eddy.mif $mrtrix_out/${1}/${2}/${1}_${2}_dwi_ms_preprocessed.mif

#Create a brain mask based on preprocessed DWI for use in speeding up subsequent analysis
#preprocessed DWI and mask saved to subject's derivatives/mrtrix folder
dwi2mask $mrtrix_out/${1}/${2}/${1}_${2}_dwi_ms_preprocessed.mif $mrtrix_out/${1}/${2}/${1}_${2}_mask.mif 


#Convert preprocessed output and mask to .nii for QC via eddy_quad
mrconvert $mrtrix_out/${1}/${2}/${1}_${2}_dwi_ms_preprocessed.mif $mrtrix_out/${1}/${2}/${1}_${2}_dwi_ms_preprocessed.nii.gz -export_grad_fsl $mrtrix_out/${1}/${2}/${1}_${2}_dwi_ms_preprocessed.bvec $mrtrix_out/${1}/${2}/${1}_${2}_dwi_ms_preprocessed.bval -json_export $mrtrix_out/${1}/${2}/${1}_${2}_dwi_ms_preprocessed.json 
mrconvert $mrtrix_out/${1}/${2}/${1}_${2}_mask.mif $mrtrix_out/${1}/${2}/${1}_${2}_mask.nii.gz 

echo ${1} ${2} multishell >> $mrtrix_out/dwi_preprocessed.txt

