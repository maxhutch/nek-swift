type file;

/* Inputs: standard dictionary, user file, and list of viscosities */
file json <"Hill.json">;
file tusr <"Hill_f90.tusr">;
//file tusr <"Hill_f77.tusr">;
string pname="order";
//float[] pvals=[4.0, 8.0, 12.0, 16.0];
float[] pvals=[8.0, 16.0];
//float[] pvals=[0.001, 0.002, 0.003, 0.004, 0.005, 0.006];
int nout = 5;
int nwrite = 32;
boolean legacy = false;


