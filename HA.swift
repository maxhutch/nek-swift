type file;

/* Inputs: standard dictionary, user file, and list of viscosities */
string prefix="HA2";
file json <"HA_sym.json">;
file tusr <"single_mode.tusr">;
//file tusr <"Hill_f77.tusr">;
string pname="npres";
//float[] pvals=[4.0, 8.0, 12.0, 16.0];
float[] pvals=[2.0];
//float[] pvals=[0.001, 0.002, 0.003, 0.004, 0.005, 0.006];
int nwrite = 256;
boolean legacy = false;

int nstep = 256;
int io_step = 128;
int step_block = 256;
int foo = 2;


