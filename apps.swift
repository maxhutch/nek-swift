type file;

app 
(file _usr, file _rea, file _map, file _config, file _size)
app_genrun_new
(file _json, file _tusr, string _name, string _tdir, string _pname, float _pval)
{
  genrun "-d" @_json "-u" @_tusr "--tdir" _tdir _name "--no-make" strcat("--override={\"",_pname,"\": ", _pval, "}");
}

app 
(file _usr, file _rea, file _map, file _config, file _size)
app_genrun_old
(file _json, file _tusr, string _name, string _tdir, string _pname, float _pval)
{
  genrun "-d" @_json "-u" @_tusr "--tdir" _tdir _name "--legacy" "--no-make" strcat("--override={\"",_pname,"\": ", _pval, "}");
}

(file _usr, file _rea, file _map, file _config, file _size)
genrun
(file _json, file _tusr, string _name, string _tdir, string _pname, float _pval, boolean _legacy = false)
{
  if (_legacy) {
    (_usr, _rea, _map, _config, _size) = app_genrun_old(_json, _tusr, _name, _tdir, _pname, _pval);
  }else{
    (_usr, _rea, _map, _config, _size) = app_genrun_new(_json, _tusr, _name, _tdir, _pname, _pval);
  }
}

app
(file _nek5000)
app_makenek_new
(string _tdir, string _name, file _usr, file _size)
{
  makenek "/home/maxhutch/simple/nek/makenek" _name "/home/maxhutch/simple/nek/" _tdir;
}

app
(file _nek5000)
app_makenek_old
(string _tdir, string _name, file _usr, file _size)
{
  makenek "/home/maxhutch/nek/makenek" _name "/home/maxhutch/nek/" _tdir;
}

(file _nek5000)
makenek
(string _tdir, string _name, file _usr, file _size, boolean _legacy = false)
{
  if (_legacy) {
    _nek5000 = app_makenek_old(_tdir, _name, _usr, _size);
  }else{
    _nek5000 = app_makenek_new(_tdir, _name, _usr, _size);
  }
}


app
(file _out, file _err, file[] _RTIfiles)
app_donek
(file _rea, file _map, string _tdir, string _name, file _nek5000)
{
 nekmpi _name "128" "64" _tdir;
}


app
(file _out, file _err, file[] _pngs)
app_nek_analyze
(file _RTIjson, file[] _RTIfiles, string _name)
{
 nek_analyze _name "-f" "1" "-e" "5" "-nt" "16" "-nb" "256" stdout=@_out stderr=@_err;
}

