type file;

app 
(file _usr, file _rea, file _map, file _config, file _size)
app_genrun_new
(file _json, file _tusr, string _name, string _tdir, string _pname, float _pval, string _qname, float _qval)
{
  genrun "-d" @_json "-u" @_tusr "--tdir" _tdir _name "--no-make" strcat("--override={\"",_pname,"\": ", _pval, ", \"", _qname, "\": ", _qval, "}");
}

app 
(file _usr, file _rea, file _map, file _config, file _size)
app_genrun_old
(file _json, file _tusr, string _name, string _tdir, string _pname, float _pval, string _qname, float _qval)
{
    genrun "-d" @_json "-u" @_tusr "--tdir" _tdir _name "--legacy" "--no-make" strcat("--override={\"",_pname,"\": ", _pval, ", \"", _qname, "\": ", _qval, "}");
}

app
(file _usr, file _rea, file _map, file _config, file _size)
genrun
(file _json, file _tusr, string _name, string _tdir, string _pname, float _pval, string _qname, float _qval, file _foo, boolean _legacy = false)
{
//  if (_legacy) {
//    genrun "-d" @_json "-u" @_tusr "--tdir" _tdir _name "--legacy" "--no-make" strcat("--override={\"",_pname,"\": ", _pval, ", \"", _qname, "\": ", _qval, "}");
//  }else{
    genrun "-d" @_json "-u" @_tusr "--tdir" _tdir _name "--no-make" strcat("--override={\"",_pname,"\": ", _pval, ", \"", _qname, "\": ", _qval, "}");
//  }
}

app
(file _usr, file _rea, file _map, file _config, file _size)
genrun_str
(file _json, file _tusr, string _name, string _tdir, string _override, file _foo, boolean _legacy = false)
{
//  if (_legacy) {
//    genrun "-d" @_json "-u" @_tusr "--tdir" _tdir _name "--legacy" "--no-make" strcat("--override=", _override);
//  }else{
    genrun "-d" @_json "-u" @_tusr "--tdir" _tdir _name "--no-make" strcat("--override=", _override);
//  }
}


app 
(file _config)
app_gensub
(file _json, file _tusr, string _name, string _tdir, string _pname, float _pval)
{
  genrun "-d" @_json "-u" @_tusr "--tdir" _tdir _name "--no-make" strcat("--override={\"",_pname,"\": ", _pval, "}");
}

app 
(file _rea, file _map, file _config)
app_regen
(file _json, file _tusr, string _name, string _tdir, string _pname, float _pval, string _pname2, float _pval2)
{
  genrun "-d" @_json "-u" @_tusr "--tdir" _tdir _name "--no-make" strcat("--override={\"",_pname,"\": ", _pval, ", \"", _pname2, "\": ", _pval2, "}");
}

app 
(file _rea, file _map, file _config)
app_regen_str
(file _json, file _tusr, string _name, string _tdir, string _override)
{
  genrun "-d" @_json "-u" @_tusr "--tdir" _tdir _name "--no-make" strcat("--override=", _override);
}


app
(file _nek5000)
app_makenek_new
(string _tdir, string _path, string _name, file _usr, file _size)
{
  makenek strcat(_path, "/makenek") _name _path _tdir;
}

app
(file _nek5000)
app_makenek_old
(string _tdir, string _path, string _name, file _usr, file _size)
{
  makenek strcat(_path, "/makenek") _name _path _tdir;
}

(file _nek5000)
makenek
(string _tdir, string _path, string _name, file _usr, file _size, boolean _legacy = false)
{
  if (_legacy) {
    _nek5000 = app_makenek_old(_tdir, _path, _name, _usr, _size);
  }else{
    _nek5000 = app_makenek_new(_tdir, _path, _name, _usr, _size);
  }
}


app
(file _out, file _err, file[] _RTIfiles, file[] _checkpoint)
app_donek
(file _rea, file _map, string _tdir, string _name, string _series, file _nek5000, int _nodes, int _mode, int _time, string _opts="")
{
 //nekmpi _name 4 _tdir stdout=@_out stderr=@_err;
 nekmpi _name _series toString(_nodes) toString(_mode) _time _tdir _opts;
}

app
(file _out, file _err, file[] _RTIfiles, file[] _checkpoint)
app_donek_restart
(file _rea, file _map, string _tdir, string _name, string _series, file _nek5000, file[] _inpoint, int _nodes, int _mode, int _time, file _dep, string _opts="")
{
 //nekmpi _name 4 _tdir stdout=@_out stderr=@_err;
 nekmpi _name _series toString(_nodes) toString(_mode) _time _tdir _opts;
}


app
(file _out, file _err, file[] _pngs) //, file _chest)
app_nek_analyze
(file _RTIjson, file[] _RTIfiles, file[] _checkpoints, string _name, string _analysis, int _start, int _end, int _post_nodes)
{
  nek_analyze  _name "-f" _start "-e" _end "--no-archive" "--process" "--no-sync" "--no-upload" strcat("--nodes=", toString(_post_nodes)) "--home_end=alcf#dtn_mira/" strcat("--analysis=", _analysis) stdout=@_out stderr=@_err;
}

app
(file _out, file _err, file[] _pngs) //, file _chest)
app_nek_analyze
(file _RTIjson, file[] _RTIfiles, file[] _checkpoints, string _name, string _analysis, int _start, int _end, int _post_nodes, file dep)
{
  nek_analyze  _name "-f" _start "-e" _end "--no-archive" "--process" "--no-sync" "--no-upload" strcat("--nodes=", toString(_post_nodes)) "--home_end=alcf#dtn_mira/" strcat("--analysis=", _analysis) stdout=@_out stderr=@_err;
}


(string[] _checkpoint, string[] _ofs) nek_out_names(string _tdir, string _name, int _nstart, int _nend, int _nwrite)
{
  int npad;
  if (_nwrite < 11){
     npad = 1;
  } else if (_nwrite < 101) {
     npad = 2;
  } else if (_nwrite < 1001) {
     npad = 3;
  } else if (_nwrite < 10001) {
    npad = 4;
  }

  foreach i in [_nstart:_nend-1]{
    foreach j in [0:_nwrite-1]{
      _ofs[(i-_nstart)*_nwrite + j] = sprintf("%s/A%s/%s%s.f%s", _tdir, pad(npad, j), _name, pad(npad,j), pad(5, i));
    }
  }
  foreach j in [0:_nwrite-1]{
    _checkpoint[j] = sprintf("%s/A%s/%s%s.f%s", _tdir, pad(npad, j), _name, pad(npad,j), pad(5, _nend));
  }
}

(string[] _names) nek_png_names(string _tdir, string _name, int _nstart, int _nend)
{
  foreach i in [_nstart:_nend]{
    _names[i-_nstart] = sprintf("%s/img/%s-t_xy-%s.png", _tdir, _name, pad(4, i));
  }
}


(string[] _outs) prepend_vec(string[] _ins, string head){
  foreach cname,k in _ins {
    _outs[k] = strcat(head, "/", cname);
  }
}

/*
(string[][] _checkpoints, string[][] _ofs) nek_out_names_all(string _tdir, string _name, int _njob, int _ninc, int _nwrite)
{
    foreach i in [1:_ninc]{
      foreach j in [0:_nwrite-1]{
        _ofs[0][(i-1)*_nwrite + j] = sprintf("%s/A%s/%s%s.f%s", _tdir, pad(3, j), _name, pad(3,j), pad(5, i));
      }
    }

    foreach j in [0:_nwrite-1]{
      _checkpoints[0][j] = sprintf("%s/A%s/%s%s.f%s", _tdir, pad(3, j), _name, pad(3,j), pad(5, _ninc+1));
    }
 

  foreach k in [1:_njob-1]{
    foreach i in [k*_ninc+2:(k+1)*_ninc]{
      foreach j in [0:_nwrite-1]{
        _ofs[k][(i-k*_ninc-2)*_nwrite + j] = sprintf("%s/A%s/%s%s.f%s", _tdir, pad(3, j), _name, pad(3,j), pad(5, i));
      }
    }

    foreach j in [0:_nwrite-1]{
      _checkpoints[k][j] = sprintf("%s/A%s/%s%s.f%s", _tdir, pad(3, j), _name, pad(3,j), pad(5, (k+1)*_ninc+1));
    }

  }
}
*/


/*
app
(file _err)
app_remove
(string _s)
{
  rm "-f"  _s stderr=@_err;
}
*/

app
(file _err)
clean
(file[] _to_clean, file _dep1, file _dep2)
{
  rm "-f" filenames(_to_clean) stderr=@_err;
}

app
(file _err)
clean_str
(string[] _to_clean, file _dep1, file _dep2, file _dep3)
{
  rm "-f" _to_clean stderr=@_err;
}


app
(file _out, file _err)
app_archive
(string _name, file[] _raw, file[] _checkpoint, int _start, int _end)
{
  post_proc _name "-f" _start "-e" _end "--archive" "--no-process" "--no-sync" "--no-upload" stdout=@_out stderr=@_err;
}

app
(file _out, file _err)
app_upload
(string _name, file[] _raw, file[] _checkpoint, file _config, file[] _img, int _start, int _end)
{
  post_proc _name "-f" _start "-e" _end "--no-archive" "--no-process" "--no-sync" "--upload" stdout=@_out stderr=@_err;
}

app
(file _foo)
mkdir
(string _dirname)
{
  mkdir "-p" _dirname stdout=@_foo;
}

app
(file _out)
get_j
(string _tdir, string _name)
{
  get_j_py _tdir _name stdout=@_out;
}

