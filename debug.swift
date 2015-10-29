import "nek";

type file;

/* Inputs: standard dictionary, user file, and list of viscosities */
string prefix="debug";
file json <"debug.json">;
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
int nodes = 1024;
int mode = 64;
int nstep = 512;
int io_step = 32;
int step_block = 512;
int jtime = 10;
int test;
int j0 = 0;

float io_time = 0.0;
float time_block = 0.0;

test = sweep(prefix, json, tusr, 
             pname, pvals, nwrite, 
             legacy, nstep, 
             io_step, step_block, 
             io_time, time_block,
             nodes, mode, jtime, j0 = j0);
