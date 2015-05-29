import "apps";
import "Hill";

foreach pval,i in pvals {

  /* Pick a directory to run in */
  string tdir = sprintf("./%s-%f", pname, pval);
  string name = sprintf("./%s-%f", pname, pval);

  /* Construct input files and build the nek5000 executable */
  file config   <single_file_mapper; file=sprintf("%s/%s.json", tdir, name)>;
  //file RTIjson  <simple_mapper; location=tdir, prefix=name, suffix=".json">;
  file rea      <single_file_mapper; file=sprintf("%s/%s.rea",  tdir, name)>;
  file map      <single_file_mapper; file=sprintf("%s/%s.map",  tdir, name)>;
  file usr      <single_file_mapper; file=sprintf("%s/%s.usr",  tdir, name)>;
  file size_mod <single_file_mapper; file=sprintf("%s/size_mod.F90",  tdir, name)>;
  //file size_mod <single_file_mapper; file=sprintf("%s/SIZE",  tdir, name)>;

  (usr, rea, map, config, size_mod) = genrun (json, tusr, name, tdir, pname, pval);
  
  file nek5000 <single_file_mapper; file=sprintf("%s/nek5000", tdir, name)>;
  (nek5000) = makenek(tdir, name, usr, size_mod);

  /* Run Nek! */
  file donek_o <single_file_mapper; file=sprintf("%s/%s.output", tdir, name)>;
  file donek_e <single_file_mapper; file=sprintf("%s/%s.error", tdir, name)>;
  string[auto] outfile_names;
  foreach j in [1:nout]{
    outfile_names << sprintf("%s/%s0.f0000%i", tdir, name, j);
  }
  file[] outfiles <array_mapper; files=outfile_names>;

  (donek_o, donek_e, outfiles) = app_donek(rea, map, tdir, name, nek5000);

  /* Analyze the outputs, making a bunch of pngs */
  file analyze_o <single_file_mapper; file=sprintf("%s/analyze_out.txt", tdir)>;
  file analyze_e <single_file_mapper; file=sprintf("%s/analyze_err.txt", tdir)>;
  file[] pngs <filesys_mapper; pattern=sprintf("%s/%s*.png", tdir, name)>;
  (analyze_o, analyze_e, pngs) = app_nek_analyze(config, outfiles, sprintf("%s/%s",tdir,name));

}
