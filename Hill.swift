import "nek";
type file;

/* Inputs: standard dictionary, user file, and list of viscosities */
string prefix="Hill";
file json <"Hill.json">;
file tusr <"Hill_f90.tusr">;
//file tusr <"Hill_f77.tusr">;
string pname="order";
//float[] pvals=[4.0, 8.0, 12.0, 16.0];
float[] pvals=[8.0, 12.0];
//float[] pvals=[0.001, 0.002, 0.003, 0.004, 0.005, 0.006];
int nwrite = 64;
boolean legacy = false;

int nstep = 200;
int io_step = 25;
int step_block = 50;
int foo = 2;


int test;
test = sweep(prefix, json, tusr, pname, pvals, nwrite, legacy, nstep, io_step, step_block, foo);
