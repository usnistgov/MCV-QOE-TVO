# Additional Tools
The scripts in **Evaluation_Tools** are used for users interested in further evaluating data. There are a variety of post-processing tools to view details of data, the TVO elements, and perform simulations.

Additional scripts not mentioned in the README that live in the repository are helper functions utilized in the main scripts listed.

## evalTest
Post-processing tool used to run an evaluation function on test data, such as eval_FSF. This is useful for reviewing the FSF scores individually, not just the averages, and evaluating behavior. 
### Example input specifications:
To evaluate data and view/plot individual FSF scores: \
evalTest('\\directory\data\capture_M4-Analog-Direct_01-Dec-2020_07-09-01.mat',eval_FSF(),'OneAtATime',true)


## eval_MRT.m 
Used to perform ABC-MRT16 calculations across evaluated volume levels. This is used in either **volume_adjust** or **evalTest**. 

### Example use case:
evalTest('\\directory\data\capture_M4-Analog-Direct_01-Dec-2020_07-09-01.mat',eval_MRT(),'OneAtATime',false)

## model_gen 
Used to generate an interpolant from the volume points in a .csv data file. Mod is an interpolant that gives FSF scores as a function of tranmit volume levels. Standard deviation is given at each volume level used to make mod.
### Example input specifications:
[mod,std_dat]=model_gen(\\directory\data\capture_M4-Analog-Direct_01-Dec-2020_07-09-01.csv')

## maxTest 
Runs the method, subclass of method_max, on the func func over the range, given by range. Returns the optimum transmit volume level. 

### Example input specifications:
Define the method: \
mm=max_OptGrid; \
Build the model: \
[mod,std_dat]=model_gen('\directory\data\capture_M4-Analog-Direct_01-Dec-2020_07-09-01.csv'); \
Run maxTest on the model: \
[opt,x,y,dat_idx, test_dat]=maxTest(mm,@(q)mod(q),[-40,0],'maxIttr',200,'noise', std_dat,'Trials',40,'tol',2);


## maxmethod_check 
Take in a CSV of project data. Create a model from data. Run it through max_OptGrid, and get information about behavior. Output options include information on mean and standard deviation values of the data; plots of decisions across eval points; plots of the final optimal values with intervals; plots of the groups across eval points.

### Example input specifications:
MaxMethod_Check('Dat_Path', '\directory\data\capture_M4-extra_31-Dec-2020_10-44-42.csv', 'Tol',2, 'Noise', 0.3)

## GroupPlotCheck 
Read in CSV data files. Use model_gen to create models based on data. Run maxTest to get interval data. Plot the intervals found by the grouping method to see more details about the decision making process that leads to the final selected optimal interval. 

### Example input specifications:
GroupPlotCheck('CSV_dat', '\directory\data\Analog Direct\capture_M4-extra_31-Dec-2020_10-44-42.csv')

## distortSim 
Simulate volume optimization with noise and clipping. Run a distortion simulation with the audio files given by the cell array audioFiles. Noise is added to the audio file using noiseFunc and the audio is clipped with clipFunc. The optimization method optMethod which is a method_max. The audio is evaluated by a metric which must be a method_eval.

### Example input specifications:
distortSim(eval_FSF(),max_OptGrid(10),@noise_func1,@clip_mx0p04_s15,fullfile('\directory\Loud_20_Words',{'F1_Loud_Norm_DiffNeigh_VaryFill.wav','F3_Loud_Norm_DiffNeigh_VaryFill.wav','M3_Loud_Norm_DiffNeigh_VaryFill.wav','M4_Loud_Norm_DiffNeigh_VaryFill.wav'}),'tol',1)

## export_data2csv_M4
Reads Volume Adjust .mat data files and creates a CSV. CSV files can be used for quick analysis in multiple software packages.

### Example input specifications:
export_data2csv_M4('Dat_Dir','\directory\Analog Direct','Dat_Name','capture_M4-Analog-Direct_01-Dec-2020_07-09-01')
