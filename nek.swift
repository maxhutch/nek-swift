//import "stdlib.v2";
import "apps";

(int retcode) 
series
(
  file nek5000,
  int nodes,
  int mode,
  string cwd,
  string tdir,
  file tdir_f,
  string name,
  int nwrite,
  file base,
  file tusr,
  float job_time,
  int nstep,
  int job_step,
  int outputs_per_job,
  int job_wall = 60,
  int post_nodes = 0,
  string analysis = "RTI",
  int j0 = 0
)
{

  string[] cwds = strsplit(cwd, "/");
  string exp_name = cwds[length(cwds)-1];


  int[] iout; iout[j0] = j0 * outputs_per_job + 1;
  int[] istep; istep[j0] = j0*job_step;
  float[] times; times[j0] = job_time * j0;
 
  string[][] checkpoint_names_j;
  //string[][] outfile_names_all;
  //(checkpoint_names_all, outfile_names_all) = nek_out_names_all(tdir, name, 4, outputs_per_job, nwrite);

  //file[][] checkpoints_j <ext; exec="map.sh", tdir=tdir, name=name, jobs=128, inc=outputs_per_job, nwrite=nwrite>;
  file[][] checkpoints_j;
  file[] stdout_j;
  file[] arch_j;
  file[] analyze_j;



  if (j0 > 0){
    string[] checkpoint_names, outfile_names;
    (checkpoint_names, outfile_names) = nek_out_names(tdir, name, iout[j0]-1, iout[j0], nwrite);
    checkpoint_names_j[j0-1] = checkpoint_names;
    file[] checkpoints <array_mapper; files=checkpoint_names>;
    checkpoints_j[j0-1] = checkpoints;
    file donek_o <single_file_mapper; file=sprintf("%s/%s-%d.output", tdir, name, j0-1)>;
    stdout_j[j0-1] = donek_o;
    file arch_o <single_file_mapper; file=sprintf("%s/arch-%d.output", tdir, j0-1)>;
    arch_j[j0-1] = arch_o;
    file analyze_o <single_file_mapper; file=sprintf("%s/analyze-%d_out.txt", tdir, j0-1)>;
    analyze_j[j0-1] = analyze_o;
  }


  /* Time or Iteration loop */
  foreach eh,j in istep{
    /* Configure the next iteration */
    string name_j = sprintf("./%s-%d", name, j);
    file config     <single_file_mapper; file=sprintf("%s/%s-%d.json", tdir, name, j)>;
    file rea_j      <single_file_mapper; file=sprintf("%s/%s-%d.rea",  tdir, name, j)>;
    file map_j      <single_file_mapper; file=sprintf("%s/%s-%d.map",  tdir, name, j)>;

    float iout_l; int istart;
    /* Check if this is the first output, which includes t=0 */
    if (iout[j] < 2) {
      iout_l = 0.0; // "restart" from 0 (which tells nek to call useric)
      istart = 1;   // first new output is index 1
    } else { 
      iout_l = toFloat(sprintf("%i",iout[j])); // restart from most recent output
      istart = iout[j] + 1;                    // first new output is that + 1
    }
    iout[j+1] = iout[j] + outputs_per_job;
    tracef("j: %i, istep: %i, iout: %i, iout_l: %f\n", j, istep[j], iout[j], iout_l);

    /* If post_nodes specified, use that many; otherwise 1 per output */
    int post_nodes_l;
    if (post_nodes > 0){
      post_nodes_l = post_nodes;
    } else {
      post_nodes_l = iout[j] + outputs_per_job - istart + 1; // this re-uses the iout[j]<2 logic 
    }

    /* Set the termination condition by time or iteration count */
    if (job_time > 0.0) {
      (rea_j, map_j, config) = app_regen (base, tusr, name_j, tdir_f, "end_time", times[j] + job_time, "restart",   iout_l);
    }else{
      (rea_j, map_j, config) = app_regen (base, tusr, name_j, tdir_f, "num_steps", toFloat(sprintf("%i",job_step)), "restart",   iout_l);
    }

    /* Make nek's output files */
    file donek_o <single_file_mapper; file=sprintf("%s/%s-%d.output", tdir, name, j)>;
    file donek_e <single_file_mapper; file=sprintf("%s/%s-%d.error", tdir, name, j)>;
    string[] checkpoint_names, outfile_names;

    /* Run Nek! */
    if (j == 0){
      (checkpoint_names, outfile_names) = nek_out_names(tdir, name, 2, iout[j+1], nwrite);
    } else {      
      (checkpoint_names, outfile_names) = nek_out_names(tdir, name, istart, iout[j+1], nwrite);
    }
    file[] outfiles <array_mapper; files=outfile_names>;
    file[] checkpoints <array_mapper; files=checkpoint_names>;
    if (j == 0){
      (donek_o, donek_e, outfiles, checkpoints) = app_donek(rea_j, map_j, tdir_f, name_j, name, nek5000, nodes, mode, job_wall);
    } else {      
      (donek_o, donek_e, outfiles, checkpoints) = app_donek_restart(rea_j, map_j, tdir_f, name_j, name, nek5000, checkpoints_j[j-1], nodes, mode, job_wall, stdout_j[j-1]);
    }
    stdout_j[j] = donek_o;
    checkpoint_names_j[j] = prepend_vec(checkpoint_names, cwd);
    checkpoints_j[j] = checkpoints;
/*
    foreach cname,k in checkpoint_names {
      checkpoint_names_j[j][k] = strcat(cwd, "/", cname);
    }
*/

    /* Log the checkpoints so we can checkpoint from them */ 

    /* Analyze the outputs, making a bunch of pngs */
    file analyze_o <single_file_mapper; file=sprintf("%s/analyze-%d_out.txt", tdir, j)>;
    file analyze_e <single_file_mapper; file=sprintf("%s/analyze-%d_err.txt", tdir, j)>;
    file[] pngs <filesys_mapper; pattern=sprintf("%s/img/%s*.png", tdir, name_j)>;
    //file chest <single_file_mapper; file=sprintf("%s/%s-results", tdir, name_j)>;
    (analyze_o, analyze_e, pngs) = app_nek_analyze(config, outfiles, checkpoints, sprintf("%s/%s/%s",cwd, tdir,name), analysis, istart, iout[j+1], post_nodes_l);
    analyze_j[j] = analyze_o;
    
    /* Archive the outputs to HPSS  */
    file arch_o <single_file_mapper; file=sprintf("%s/arch-%d.output", tdir, j)>;
    file arch_e <single_file_mapper; file=sprintf("%s/arch-%d.error", tdir, j)>;
    (arch_o, arch_e) = app_archive(sprintf("%s/%s/%s", exp_name, tdir, name), outfiles, checkpoints, istart, iout[j+1]);
    arch_j[j] = arch_o;

    /* If this isn't the first iteration, clean up the extra files
       we save the first iteration because it contains the positions */
    file clean_o <single_file_mapper; file=sprintf("%s/clean-%d.output", tdir, j)>;
    (clean_o) = clean_str(outfile_names, arch_o, analyze_o, donek_o);
    file clean2_o <single_file_mapper; file=sprintf("%s/clean2-%d.output", tdir, j)>;
    (clean2_o) = clean(checkpoints_j[j], arch_o, analyze_o);
    if (j > 0) {
      /* These really depend on arch_o[j-1] and analyze_o[j-1], but those aren't stored */
      file clean3_o <single_file_mapper; file=sprintf("%s/clean3-%d.output", tdir, j)>;
      (clean3_o) = clean_str(checkpoint_names_j[j-1], arch_j[j-1], analyze_j[j-1], donek_o);
    }
 
    /* Publish the outputs to Petrel */
    file uplo_o <single_file_mapper; file=sprintf("%s/uplo-%d.output", tdir, j)>;
    file uplo_e <single_file_mapper; file=sprintf("%s/uplo-%d.error", tdir, j)>;
    (uplo_o, uplo_e) = app_upload(sprintf("%s/%s/%s", exp_name, tdir, name), outfiles, checkpoints, config, pngs, istart, iout[j+1]);

    /* If we aren't done, then setup the next iteration */
    if (istep[j]+job_step < nstep){
     istep[j+1] = istep[j] + job_step;
     times[j+1] = times[j] + job_time;
    }
  }  
}


(int retcode) sweep (
                     string  prefix,         // prefix for directories, files
                     file    json,           // baseline configuration 
                     file    tusr,           // templated user file
                     string  pname,          // first parameter name
                     float[] pvals,          // array of values for first parameter
                     string  qname,          // first parameter name
                     float[] qvals,          // array of values for first parameter
                     int     nwrite,         // number of output files
                     int     nstep,          // total number of steps
                     int     io_step,        // output interval (iterations)
                     int     job_step,       // job interval (iterations)
                     float   io_time,        // output interval (time) (0 if unused)
                     float   job_time,       // job interval (time) (0 if unused)
                     int     nodes,          // nodes for simulation
                     int     mode,           // mode for simulation
                     int     job_wall,       // time for simulation
                     int     j0=0,           // starting job index
                     string  analysis="RTI", // analysis package name
                     boolean legacy=false,   // legacy mode
                     int     post_nodes=0    // nodes for post-processing
                    ){
retcode = 1;
int outputs_per_job;
if (job_time > 0.0 && io_time > 0.0){
  trace("Foo");
  //outputs_per_job = toInt(job_time / io_time);
  outputs_per_job = 2; //toInt(sprintf("%f", job_time / io_time));
  //tracef("Foo!");
  //outputs_per_job = 2;
} else {
  outputs_per_job = job_step %/ io_step;
}
string cwd = arg("cwd", ".");

  foreach pval,i in pvals {
    foreach qval,ii in qvals {
      if (qval <= pval) {
 
        /* Pick a directory to run in */
        string tdir = sprintf("./%s_v_%f_c_%f", prefix, pval, qval);
        string name = sprintf("./%s_v_%f_c_%f", prefix, pval, qval);
        file tdir_f  <single_file_mapper; file=strcat(cwd,"/",tdir)>;
        file foo     <single_file_mapper; file=strcat(cwd,"/",tdir, "/foo")>;
        (foo) = mkdir(tdir_f);
    
        /* Construct input files and build the nek5000 executable */
        file base     <single_file_mapper; file=sprintf("%s/%s.json", tdir, name)>;
        file rea      <single_file_mapper; file=sprintf("%s/%s.rea",  tdir, name)>;
        file map      <single_file_mapper; file=sprintf("%s/%s.map",  tdir, name)>;
        file usr      <single_file_mapper; file=sprintf("%s/%s.usr",  tdir, name)>;
        //file size_mod <single_file_mapper; file=sprintf("%s/SIZE",  tdir, name)>;
        file size_mod <single_file_mapper; file=sprintf("%s/size_mod.F90",  tdir)>;
    
        (usr, rea, map, base, size_mod) = genrun (json, tusr, name, tdir_f, pname, pval, qname, qval, foo, _legacy=legacy);
        file nek5000 <single_file_mapper; file=sprintf("%s/nek5000", tdir, name)>;
        (nek5000) = makenek(tdir_f, "/projects/HighAspectRTI/nek/", name, usr, size_mod, _legacy=legacy);
  
        int ret_l;
        (ret_l) =  series(nek5000, nodes, mode,
                          cwd, tdir, tdir_f, 
                          name, nwrite, base, usr, job_time, nstep, job_step, outputs_per_job, 
                          analysis=analysis, job_wall=job_wall, post_nodes=post_nodes, j0=j0);
      }
    }
  }

}
