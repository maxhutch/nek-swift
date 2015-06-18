type file;

/* Inputs: standard dictionary, user file, and list of viscosities */
string prefix="HA";
file json <"HA_sym.json">;
file tusr <"single_mode.tusr">;
//file tusr <"Hill_f77.tusr">;
//string pname="tolrel";
string pname="visc";
float[] pvals = [0.0001];
//float[] pvals=[0.001, 0.002, 0.003, 0.004, 0.005, 0.006];
int nwrite=256;
boolean legacy = false;

/*
int nstep = 16384;
int io_step = 128;
int step_block = 1024;
int foo = 8;
*/
int nstep = 16384;
int io_step = 128;
int step_block = 512;
int foo = 4;

