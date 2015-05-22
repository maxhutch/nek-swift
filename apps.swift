type file;

app 
(file _nek5000, file _rea, file _map, file _config)
app_genrun
(file _json, file _tusr, string _makenek, string _name, string _tdir)
/*
~/maxhutch/nek-tools/genrun/genrun.py -d LST.json -u LST_f90.tusr --makenek ~/maxhutch/nek/makenek RTI_LST 
*/
{
  genrun "-d" @_json "-u" @_tusr "--makenek" _makenek "--tdir" _tdir _name ;
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
(file _runconfig)
app_make_config
(file _tmplconfig, float _visc)
{
  sed "-e" strcat("s/@visc/",_visc,"/") stdout=@_runconfig stdin=@_tmplconfig;
}

