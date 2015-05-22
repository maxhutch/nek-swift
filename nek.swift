import "apps";
type file;

/* Inputs: standard dictionary, user file, and list of viscosities */
file json <"LST.json">;
file tusr <"LST_f90.tusr">;
float[] viscosities=[0.001, 0.002];


foreach viscosity,i in viscosities {

  /* Pick a directory to run in */
  string tdir = sprintf("./visc-%f", viscosity);

  /* Substitute viscosity into a config dictionary */
  file runconfig <single_file_mapper; file=sprintf("%s/LST_sub.json", tdir)>;
  (runconfig) = app_make_config(json, viscosity );

  /* Construct input files and build the nek5000 executable */
  string name=sprintf("RTI_LST-%f", viscosity);
  file RTIjson <single_file_mapper; file=sprintf("%s/%s.json", tdir, name)>;
  file rea     <single_file_mapper; file=sprintf("%s/%s.rea",  tdir, name)>;
  file map     <single_file_mapper; file=sprintf("%s/%s.map",  tdir, name)>;
  file nek5000 <single_file_mapper; file=sprintf("%s/nek5000", tdir, name)>;
  (nek5000, rea, map, RTIjson) = app_genrun (runconfig, tusr, "@pwd/nek/makenek", name, tdir);

  /* Run Nek! */
  file donek_o <single_file_mapper; file=sprintf("%s/donek_out.txt", tdir)>;
  file donek_e <single_file_mapper; file=sprintf("%s/donek_err.txt", tdir)>;
  string[auto] RTI_outfile_names;
  foreach j in [1:6] {
    RTI_outfile_names << sprintf("%s/%s0.f0000%i", tdir, name, j);
  }
  file[] RTIfiles <array_mapper; files=RTI_outfile_names>;
  (donek_o, donek_e, RTIfiles) = app_donek(rea, map, tdir, name, nek5000);

  /* Analyze the outputs, making a bunch of pngs */
  file analyze_o <single_file_mapper; file=sprintf("%s/analyze_out.txt", tdir)>;
  file analyze_e <single_file_mapper; file=sprintf("%s/analyze_err.txt", tdir)>;
  file[] pngs <filesys_mapper; pattern=sprintf("%s/%s*.png", tdir, name)>;
  (analyze_o, analyze_e, pngs) = app_nek_analyze(RTIjson, RTIfiles, sprintf("%s/%s",tdir,name));
}
