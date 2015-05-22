type file;

app 
(file _out, file _err, file _nek5000, file _rea, file _map, file _config)
app_genrun
(file _json, file _tusr, string _makenek, string _name, string _tdir)
/*
~/maxhutch/nek-tools/genrun/genrun.py -d LST.json -u LST_f90.tusr --makenek ~/maxhutch/nek/makenek RTI_LST 
*/
{
  genrun "-d" @_json "-u" @_tusr "--makenek" _makenek "--tdir" _tdir _name stdout=@_out stderr=@_err;
}

app
(file _out, file _err, file[] _RTIfiles)
app_donek
(file _rea, file _map, string _tdir, string _name, file _nek5000)
/*
requires two input files and an exe file (acts as input here) that are prefixed as RTI_LST
 RTI_LST.rea
 RTI_LST.map
 nek5000 (the executable)
 ~/maxhutch/nek/nekmpi RTI_LST 1
*/
{
 nekmpi _name "1" _tdir stdout=@_out stderr=@_err;
}

/*
./post_proc.py nek-tests/RTI-LST/RTI_LST -f 1 -e 10 --process --archive --upload --no-sync --nodes=1
The preferred commandline is : ~/maxhutch/nek-analyze/load.py ./RTI_LST -f 1 -e 6 
*/

app
(file _out, file _err, file[] _pngs)
app_nek_analyze
(file _RTIjson, file[] _RTIfiles, string _name)
{
 nek_analyze _name "-f" "1" "-e" "6" stdout=@_out stderr=@_err;
}

app
(file _err, file _runconfig)
app_make_config
(file _tmplconfig, float _visc)
{
  sed "-e" strcat("s/@visc/",_visc,"/") stdout=@_runconfig stderr=@_err stdin=@_tmplconfig;
}

/* Inputs! */
file json <"LST.json">;
file tusr <"LST_f90.tusr">;
float[] viscosities=[0.001, 0.002];


foreach viscosity,i in viscosities {

string tdir = sprintf("./tmp%d", i);

/* app invocation */

file sed_e     <single_file_mapper; file=sprintf("%s/sed_err.txt", tdir)>;
file runconfig <single_file_mapper; file=sprintf("%s/LST_sub.json", tdir)>;
(sed_e, runconfig) = app_make_config(json, viscosity );

file genrun_o <single_file_mapper; file=sprintf("%s/genrun_out.txt", tdir)>;
file genrun_e <single_file_mapper; file=sprintf("%s/genrun_err.txt", tdir)>;
string name=sprintf("RTI_LST-%f", viscosity);
file RTIjson <single_file_mapper; file=sprintf("%s/%s.json", tdir, name)>;
file rea     <single_file_mapper; file=sprintf("%s/%s.rea",  tdir, name)>;
file map     <single_file_mapper; file=sprintf("%s/%s.map",  tdir, name)>;
file nek5000 <single_file_mapper; file=sprintf("%s/nek5000", tdir, name)>;

(genrun_o, genrun_e, nek5000, rea, map, RTIjson) = app_genrun (runconfig, tusr, "@pwd/nek/makenek", name, tdir);

file donek_o <single_file_mapper; file=sprintf("%s/donek_out.txt", tdir)>;
file donek_e <single_file_mapper; file=sprintf("%s/donek_err.txt", tdir)>;

string[auto] RTI_outfile_names;
foreach j in [1:6] {
  RTI_outfile_names << sprintf("%s/%s0.f0000%i", tdir, name, j);
}

file[] RTIfiles <array_mapper; files=RTI_outfile_names>;
(donek_o, donek_e, RTIfiles) = app_donek(rea, map, tdir, name, nek5000);

file analyze_o <single_file_mapper; file=sprintf("%s/analyze_out.txt", tdir)>;
file analyze_e <single_file_mapper; file=sprintf("%s/analyze_err.txt", tdir)>;
file[] pngs <filesys_mapper; pattern=sprintf("%s/%s*.png", tdir, name)>;
(analyze_o, analyze_e, pngs) = app_nek_analyze(RTIjson, RTIfiles, sprintf("%s/%s",tdir,name));

}
