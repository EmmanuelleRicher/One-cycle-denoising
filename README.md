## One cycle denoising ##

This repository contains the code for the article _Denoising OCT videos based on temporal redundancy_, by authors Emmanuelle Richer, Marissé Masís Solano, Farida Cheriet, Mark R. Lesk, Santiago Costantino, currently under review at Scientific Reports. 

![Alt text](./imgs/workflow.jpg?raw=true "Workflow of the one-cycle image, as presented in the article")

The main script to call is the registrationWRTPhase.m script. Note that the pulse signal and OCT timestamps must be synchronized (this script assumes that they are). 

The necessary inputs arguments are : 
   list_ordered_bscans : structure containing the paths towards the OCT
                         frames in a ordered fashion (synchronized with 
                         the OCT timestamps and the pulse signal). This 
                         structure needs to be organized as with the dir 
                         function of matlab, with a .folder attribute and 
                         .name attribute mandatory
   oct_timestamps : array containing the oct timestamps
   pulse : array containing the pulse amplitude information
   timeSec : array containing the timestamps of the pulse signal in
             seconds (must be same size as pulse variable)
   timeMilliSec : array containing the timestamps of the pulse signal in
                  milli seconds (must be same size as pulse variable)
