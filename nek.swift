import "apps";
import "Hill";

int nstep = 100;
int io_step = 25;
float step_block = 50.0;

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
  file size_mod <single_file_mapper; file=sprintf("%s/size_mod.F90",  tdir, name)>;

  (usr, rea, map, base, size_mod) = genrun (json, tusr, name, tdir, pname, pval, _legacy=legacy);
  
  file nek5000 <single_file_mapper; file=sprintf("%s/nek5000", tdir, name)>;
  (nek5000) = makenek(tdir, name, usr, size_mod, _legacy=legacy);

  float[int] iout;
  iout[0] = 0.0;
  int[int] istep;
  istep[0] = 0;
  iterate j {
    string name_j = sprintf("./%s_%s_%f-%d", prefix, pname, pval, j);
    string name_tj = sprintf("./%s_%s_%f-t%d", prefix, pname, pval, j);
    file config     <single_file_mapper; file=sprintf("%s/%s-%d.json", tdir, name, j)>;
    file tconf      <single_file_mapper; file=sprintf("%s/%s-t%d.json", tdir, name, j)>;
    file rea_j      <single_file_mapper; file=sprintf("%s/%s-%d.rea",  tdir, name, j)>;
    file map_j      <single_file_mapper; file=sprintf("%s/%s-%d.map",  tdir, name, j)>;
    file usr_j      <single_file_mapper; file=sprintf("%s/%s-%d.usr",  tdir, name, j)>;
    //file size_mod <single_file_mapper; file=sprintf("%s/SIZE",  tdir, name)>;
    file size_mod_j <single_file_mapper; file=sprintf("%s/size_mod-%d.F90",  tdir, name, j)>;

    (tconf) = app_gensub (base, tusr, name_tj, tdir, "num_steps", step_block);
    float iout_l;
    if (iout[j] < 1.1) {
      iout_l = 0.0;
    } else { 
      iout_l = iout[j];
    }

    (usr_j, rea_j, map_j, config, size_mod_j) = genrun (tconf,  tusr, name_j, tdir, "restart",   iout_l, _legacy=legacy);

    /* Run Nek! */
    file donek_o <single_file_mapper; file=sprintf("%s/%s-%d.output", tdir, name, j)>;
    file donek_e <single_file_mapper; file=sprintf("%s/%s-%d.error", tdir, name, j)>;
    string[auto] outfile_names_j;
    string[auto] checkpoint_names_j;
    (checkpoint_names_j, outfile_names_j) = nek_out_names(tdir, name_j, toInt(toString(iout[j])), toInt(toString(iout[j] + step_block / io_step)), nwrite);
    file[] outfiles_j <array_mapper; files=outfile_names_j>;
    file[] checkpoints_j <array_mapper; files=checkpoint_names_j>;
    if (j == 0){
      (donek_o, donek_e, outfiles_j, checkpoints_j) = app_donek(rea_j, map_j, tdir, name_j, nek5000);
    } else {
      string[auto] old_checkpoints;
      string[auto] old_outputs;
      (old_checkpoints, old_outputs) = nek_out_names(tdir, sprintf("./%s_%s_%f-%d", prefix, pname, pval, j), toInt(toString(iout[j-1])), toInt(toString(iout[j] - 1)), nwrite);
      file[] checks_old <array_mapper; files=old_checkpoints>;
      file[] checks <structured_regexp_mapper; source=checks_old, 
        match=sprintf("%s_%s_%f/%s_%s_f-%d(.*)", prefix, pname, pval, prefix, pname, pval, j-1), 
        transform=sprintf("%s_%s_%f/%s_%s_f-%d\\1", prefix, pname, pval, prefix, pname, pval, j)>;
      (donek_o, donek_e, outfiles_j, checkpoints_j) = app_donek_restart(rea_j, map_j, tdir, name_j, nek5000, checks);
    }
 

    /* Analyze the outputs, making a bunch of pngs */
    file analyze_o <single_file_mapper; file=sprintf("%s/analyze-%d_out.txt", tdir, j)>;
    file analyze_e <single_file_mapper; file=sprintf("%s/analyze-%d_err.txt", tdir, j)>;
    file[] pngs <filesys_mapper; pattern=sprintf("%s/%s*.png", tdir, name_j)>;
    //file[] chest<filesys_mapper; pattern=sprintf("%s/%s-results/*", tdir, name)>;
    (analyze_o, analyze_e, pngs) = app_nek_analyze(config, outfiles_j, checkpoints_j, sprintf("%s/%s",tdir,name), toInt(toString(iout)), toInt(toString(iout[j] + step_block / io_step)) );

    /* Archive the outputs to HPSS */
    file arch_o <single_file_mapper; file=sprintf("%s/arch-%d.output", tdir, j)>;
    file arch_e <single_file_mapper; file=sprintf("%s/arch-%d.error", tdir, j)>;
    (arch_o, arch_e) = app_archive(sprintf("%s/%s", tdir, name_j), outfiles_j, checkpoints_j, toInt(toString(iout[j])), toInt(toString(iout[j] + step_block / io_step)));

   istep[j+1] = istep[j] + toInt(toString(step_block));
   iout[j+1] = iout[j] + step_block / io_step;
  } until (istep[j+1] >= nstep);

  /* Publish the outputs to Petrel 
  file uplo_o <single_file_mapper; file=sprintf("%s/uplo.output", tdir, name)>;
  file uplo_e <single_file_mapper; file=sprintf("%s/uplo.error", tdir, name)>;
  (uplo_o, uplo_e) = app_upload(sprintf("%s/%s", tdir, name), config, chest, pngs);
  */
  
}
