# Calculate group average response for each tissue component 
# run on a set of 30-40 subjects (more will take a long time)
# because fixel-based analysis requires a single set of repsonse function estimates 
# by Meaghan Perdue
# 27 March 2023

export mrtrix_out=/Volumes/catherine_team/Trainee_Folders/mvperdue/preschool/bids_test/derivatives/mrtrix

cd $mrtrix_out

#this will run on all processed subjects, do after first batch of subjects run (randomly selected)
responsemean /mrtrix_out/*/*/wm_response.txt /mrtrix_out/group_average_response_wm.txt  
responsemean /mrtrix_out/*/*/gm_response.txt /mrtrix_out/group_average_response_gm.txt  
responsemean /mrtrix_out/*/*/csf_response.txt	/mrtrix_out/group_average_response_csf.txt
