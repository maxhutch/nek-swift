type file;

app 
(file _out, file _err, file _nek5000, file _rea, file _map)
app_genrun
(file _json, file _tusr, string _makenek)
/*
~/maxhutch/nek-tools/genrun/genrun.py -d LST.json -u LST_f90.tusr --makenek ~/maxhutch/nek/makenek RTI_LST 
*/
{
  genrun "-d" @_json "-u" @_tusr "--makenek" _makenek "RTI_LST" stdout=@_out stderr=@_err;
}

app
(file _out, file _err, file[] _RTIfiles)
app_donek
(file _rea, file _map, file _nek5000)
/*
requires two input files and an exe file (acts as input here) that are prefixed as RTI_LST
 RTI_LST.rea
 RTI_LST.map
 nek5000 (the executable)
 ~/maxhutch/nek/nekmpi RTI_LST 1
*/
{
 nekmpi "RTI_LST" "1" stdout=@_out stderr=@_err;
}

/*
./post_proc.py nek-tests/RTI-LST/RTI_LST -f 1 -e 10 --process --archive --upload --no-sync --nodes=1
The preferred commandline is : ~/maxhutch/nek-analyze/load.py ./RTI_LST -f 1 -e 6 
*/

app
(file _out, file _err, file[] _pngs)
app_nek_analyze
(file _RTIjson, file[] _RTIfiles)
{
 nek_analyze "./RTI_LST" "-f" "1" "-e" "6" stdout=@_out stderr=@_err;
}


/* files */
file genrun_o <"genrun_out.txt">;
file genrun_e <"genrun_err.txt">;

file donek_o <"donek_out.txt">;
file donek_e <"donek_err.txt">;

file analyze_o <"analyze_out.txt">;
file analyze_e <"analyze_err.txt">;

file RTIjson <"RTI_LST.json">;
file json <"LST.json">;
file tusr <"LST_f90.tusr">;

file[] RTIfiles <filesys_mapper; pattern="RTI_LST0.f*">;
file[] pngs <filesys_mapper; pattern="*.png">;

file rea <"RTI_LST.rea">;
file map <"RTI_LST.map">;
file nek5000 <"nek5000">;

/* app invocation */

(genrun_o, genrun_e, nek5000, rea, map) = app_genrun (json, tusr, "/home/ketan/maxhutch/nek/makenek");
(donek_o, donek_e, RTIfiles) = app_donek(rea, map, nek5000);
(analyze_o, analyze_e, pngs) = app_nek_analyze(RTIjson, RTIfiles);

