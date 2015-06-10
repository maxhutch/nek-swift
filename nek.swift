import "apps";
import "Hill";

foreach pval,i in pvals {

  /* Pick a directory to run in */
  string tdir = sprintf("./%s_%s_%f", prefix, pname, pval);
  string name = sprintf("./%s_%s_%f", prefix, pname, pval);

  /* Construct input files and build the nek5000 executable */
  file base     <single_file_mapper; file=sprintf("%s/%s.json", tdir, name)>;
  file rea      <single_file_mapper; file=sprintf("%s/%s.rea",  tdir, name)>;
  file map      <single_file_mapper; file=sprintf("%s/%s.map",  tdir, name)>;
  file usr      <single_file_mapper; file=sprintf("%s/%s.usr",  tdir, name)>;
  //file size_mod <single_file_mapper; file=sprintf("%s/SIZE",  tdir, name)>;
  file size_mod <single_file_mapper; file=sprintf("%s/size_mod.F90",  tdir)>;

  (usr, rea, map, base, size_mod) = genrun (json, tusr, name, tdir, pname, pval, _legacy=legacy);
  
  file nek5000 <single_file_mapper; file=sprintf("%s/nek5000", tdir, name)>;
  (nek5000) = makenek(tdir, "@pwd/nek/", name, usr, size_mod, _legacy=legacy);

  int[int] iout; iout[0] = 1;
  int[int] istep; istep[0] = 0;

  string[][] outfile_names_j;
  string[][] checkpoint_names_j;
  file[][] outfiles_j;
  file[][] checkpoints_j;


  iterate j {
    /* Configure the next iteration */
    string name_j = sprintf("./%s_%s_%f-%d", prefix, pname, pval, j);
    string name_tj = sprintf("./%s_%s_%f-t%d", prefix, pname, pval, j);
    file config     <single_file_mapper; file=sprintf("%s/%s-%d.json", tdir, name, j)>;
    file tconf      <single_file_mapper; file=sprintf("%s/%s-t%d.json", tdir, name, j)>;
    file rea_j      <single_file_mapper; file=sprintf("%s/%s-%d.rea",  tdir, name, j)>;
    file map_j      <single_file_mapper; file=sprintf("%s/%s-%d.map",  tdir, name, j)>;

    (tconf) = app_gensub (base, tusr, name_tj, tdir, "num_steps", toFloat(step_block));

    float iout_l;
    int istart;
    if (iout[j] < 2) {
      iout_l = 0.0;
      istart = 1;
    } else { 
      iout_l = toFloat(iout[j]);
      istart = iout[j] + 1;
    }

    (rea_j, map_j, config) = app_regen (tconf,  tusr, name_j, tdir, "restart",   iout_l);

    /* Run Nek! */
    file donek_o <single_file_mapper; file=sprintf("%s/%s-%d.output", tdir, name, j)>;
    file donek_e <single_file_mapper; file=sprintf("%s/%s-%d.error", tdir, name, j)>;
    string[] checkpoint_names;
    string[] outfile_names;
    (checkpoint_names, outfile_names) = nek_out_names(tdir, name_j, istart, iout[j] + foo, nwrite);
    outfile_names_j[j] = outfile_names;
    checkpoint_names_j[j] = checkpoint_names;
    file[] outfiles <array_mapper; files=outfile_names>;
    file[] checkpoints <array_mapper; files=checkpoint_names>;
    outfiles_j[j] = outfiles;
    checkpoints_j[j] = checkpoints;


    if (j == 0){
      (donek_o, donek_e, outfiles, checkpoints) = app_donek(rea_j, map_j, tdir, name_j, nek5000);
    } else {
      string[] new_checkpoints;
      string[] new_outputs;
      (new_checkpoints, new_outputs) = nek_out_names(tdir, sprintf("./%s_%s_%f-%d", prefix, pname, pval, j), istart-2, istart-1, nwrite);
      
      file[] checks_new <array_mapper; files=new_checkpoints>;
      /* 
      file[] checks <structured_regexp_mapper; source=checkpoints_j[j-1], 
        match=sprintf("%s_%s_%f/(.*)/%s_%s_%f-%d(.*)", prefix, pname, pval, prefix, pname, pval, j-1), 
        transform=strcat(sprintf("%s_%s_%f/", prefix, pname, pval), "\\1", sprintf("/%s_%s_%f-%d", prefix, pname, pval, j), "\\2")>;
      */
      foreach f,ii in checkpoints_j[j-1]{
        checks_new[ii] = app_cp(f);
      }
      
      (donek_o, donek_e, outfiles, checkpoints) = app_donek_restart(rea_j, map_j, tdir, name_j, nek5000, checks_new);
    }
 
    /* Analyze the outputs, making a bunch of pngs */
    file analyze_o <single_file_mapper; file=sprintf("%s/analyze-%d_out.txt", tdir, j)>;
    file analyze_e <single_file_mapper; file=sprintf("%s/analyze-%d_err.txt", tdir, j)>;
    file[] pngs <filesys_mapper; pattern=sprintf("%s/%s*.png", tdir, name_j)>;
    //file[] chest<filesys_mapper; pattern=sprintf("%s/%s-results/*", tdir, name)>;
    (analyze_o, analyze_e, pngs) = app_nek_analyze(config, outfiles, checkpoints, sprintf("%s/%s",tdir,name_j), istart, iout[j] + foo);

    /* Archive the outputs to HPSS 
    file arch_o <single_file_mapper; file=sprintf("%s/arch-%d.output", tdir, j)>;
    file arch_e <single_file_mapper; file=sprintf("%s/arch-%d.error", tdir, j)>;
    (arch_o, arch_e) = app_archive(sprintf("%s/%s", tdir, name_j), outfiles_j, checkpoints_j, iout[j], iout[j] + foo);
    */ 

   istep[j+1] = istep[j] + step_block;
   iout[j+1] = iout[j] + foo;
  } until (istep[j] >= nstep);

  /* Publish the outputs to Petrel 
  file uplo_o <single_file_mapper; file=sprintf("%s/uplo.output", tdir, name)>;
  file uplo_e <single_file_mapper; file=sprintf("%s/uplo.error", tdir, name)>;
  (uplo_o, uplo_e) = app_upload(sprintf("%s/%s", tdir, name), config, chest, pngs);
  */
  
}
