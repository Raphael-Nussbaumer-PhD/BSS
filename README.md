Bayasian Sequential Simulator (SSB) - Version 2.0
original code : Paolo Ruggeri
Author : Raphael Nussbaumer rafnuss@gmail.com


1.0 :
This version is a modification of Paolo's one. It retake the almost the same structure. Modification of the variable name has been done. 
- The Nonparametric.m function compute the density.
- script_prepare_data.m is the script to be run to make the code work. It read the data and lauch the main function BSGS.m. Here the data can be choose.
- BSGS.m is the main function.

1.1:
- check some error in all the other file than BSGS and the script. Mainly removing the old :
	-v=find(A==b); A(v)   by A(A==b)
	- [a,b] by [a,~] if b is unused
	- ...
- there is still a hude need for cokri_cam and cokri2 to be update, allocation is not done correctly

2.0 (changed to 1.5 because of minor change):
- finishing the conversion to the new notation: X (primary), Z (secondary), Y (resulting)
- Test of several krigging algorithm to compare time.
	- cokri_cam: Marecotte code (initial one and fastest !!!)
	- kriging_Ravalec: from Ravalec Book (pdf+matlab code)
	- kriging_Ravalec_simplied : personnal modification to compute essential part of the krigging but still very slow (roughly x3)
	- kriging_FEX : code from File EXchange on matlab website. (depend on construction of an variogram, and fitting the variogram)
	- krig: mGstat code of krigging
	- cokri_cam_modify: Marecotte code has been modify to be used ONLY in 2D (d=2) with 1 variable (p=1), with only simple krigging (itype=??) and no block and several point at the same time. This improve the speed from 17sec to 13sec on my computer for a grid of 50x100. This is the version which will be kept from now on.

3.0: HUGE CHANGE !
- folder, file structure
	- folders of each part of the script are created : generation, data, ERT, BSBGS, flow
	- Each part has a function in the main directory and then call function in their respective folder
	- Description have been added to functions
- data_creation:
	- generation of K-field, g-field or rho-fields with FFTMA
	- Physical pedo-relationship between the field were implemented to allow different generation procedure
	- possibility to choose between different method was implemented
	- see publishing in the HTML folder
- BSGS:
	- Rewrite of cokricam, cokri... etc have been tested and put in the function
	- cleaning of BSGS with lots of comment and structure for publishing (.html)
- FLOW:
	- a new flow function to compute velocity and tracer simulation of an inputed K-field was created

3.5: 
- Normal Score: We re-design the normal score tool:
	- nscore_perso() is computing the Normal zscore transform of the input vector. There are 6 method to compute the normal and back normal score. We selected from them the one discribe here: http://ch.mathworks.com/help/stats/examples/nonparametric-estimates-of-cumulative-distribution-functions-and-their-inverses.html#zmw57dd0e1147. It's the easier to understand and write as well as the most precise. Indead the previous implemented version is using interpolation function from std distribution which might not be write. The function return two fonction handle : one for the normal transform and the other one for the back-transform. The function use the inputed vector to create the normal transform. Then using interpolation, the function handle are created.
	- In BSGS, the N-SCORE tool is call up to 5000 pts in the grid. At this point, we assume the transformation to have enough point for interpolation. We choose put a bette test than 5000....
	- Likelihood check: we cheack that the kernel density created encompase 99% of the prior distribution. The kernel density boundary has also been updated

4.0: Major restructuration
- Restructuration of folder system according their use. Using addpath(genpath('./.')) , we don't need a specific place for the function.........
- Separation of BSGS and BSGS_one_simulation : One is for the main script of the sequential simulation the other one allow several simulations and send toward gradual deformation also
- Gradual Deformation is implemented, tested and work fine for simple deformation
- interp1 is replace with griddedinterpolant which doesn't require to recompute the interpolation each step.

4.1 : test of different kriging technique
- Implementation of a (very) simple kriging method with a spiral research.
- possible to comparaison of the previous version (marecott) and mine!
- an also ordinary kriging

4.3 :
- searching windows

5.0:
- cleaning of krigreage folder and in BSGS
- correction of kriging error
- ERT simulation forward and inverse (ERT2D)
- 
