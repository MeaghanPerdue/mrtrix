#multi-shell multi tissue CSD in mrtrix, using group average response estimates
# by Meaghan Perdue
# 27 March 2023


export mrtrix_out=/Volumes/catherine_team/Trainee_Folders/mvperdue/preschool/bids_test/derivatives/mrtrix
cd $mrtrix_out/${1}/${2}

#HCP
#cd /mrtrix_out/${1}/${2}
#dwi2fod msmt_csd dwi_preproc_upsampled.mif ../group_average_response_wm.txt wmfod.mif ../group_average_response_gm.txt gm.mif ../group_average_response_csf.txt csf.mif -mask dwi_mask_upsampled.mif -info -nthreads 6

#test run using subject-specific response function
dwi2fod msmt_csd dwi_preproc_upsampled.mif wm_response.txt wmfod.mif gm_response.txt gm.mif csf_response.txt csf.mif -mask dwi_mask_upsampled.mif -info -nthreads 6

mrconvert -coord 3 0 wmfod.mif - | mrcat csf.mif gm.mif - vf.mif  
#outputs the rgb visualization of csd ellipsoids
 
 #display WM FODs with tissue signal contribution map
 #mrview vf.mif -odf.load_sh wm.mif
