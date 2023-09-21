//  Jugsaw Extension
//===============================
// extract data from inputs
function raw2json(obj, demo_obj){
    if (demo_obj instanceof Array){
        return obj.map((v, i) => raw2json(v, i < demo_obj.length ? demo_obj[i] : demo_obj[0]));
    } else if (demo_obj instanceof Object){
        return {'fields':obj.map((v, i)=>raw2json(v, demo_obj.fields[i]))}
    } else {
        return obj;
    }
}

function uuid4() {
  return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
    (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
  );
}

// Request an application and return an object as Promise.
// Please use `render_app` for further processing.
function request_app_obj(endpoint, project, appname, version="latest") {
    const url = new URL(`v1/proj/${project}/app/${appname}/ver/${version}/func`, endpoint).href
    return fetch(url, {
        method: 'GET',
    })
}

// Launch a function call and return a job_id as string.
function call(endpoint, project, appname, fname, args, kwargs, maxtime=60, created_by="unspecified", version="lastest"){
    const context = this.context;
    const url = new URL(`v1/proj/${project}/app/${appname}/ver/${version}/func/${fname}`, endpoint).href
    const job_id = uuid4();
    const jobspec = {
        "id" : job_id,
        "created_at" : Date.now(),
        "created_by" : created_by,
        "maxtime" : maxtime,
        "fcall" : {
            "fname" : fname,
            "args" : args,
            "kwargs" : kwargs
        }
    };
    return fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            "ce-id":uuid4(), "ce-type":"any", "ce-source":"any",
            "ce-specversion":"1.0"
        },
        body: JSON.stringify(jobspec)
    })
}

// fetch and return the result (as a Promise)
function fetch_result(endpoint, job_id) {
    const url = new URL(`v1/job/${job_id}/result`, endpoint).href
    return fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body : JSON.stringify({"job_id" : job_id})
    })
}

function error_message(txt){
    const obj = create_textblock('p', JSON.parse(txt).error);
    obj.style.color = "red";
    return obj
}

function aslist(adt){
  return adt
}

// TODO: render like Pluto
// render a demo as an object
function render_demo(demo, typemap){
    const [fcall, result, meta] = demo.fields;
    const metamap = render_dict(meta);
    // positional arguments
    const newargs = fcall.args.fields.map((arg, i)=>(
        {"arg_name":`${i+1}`, "data": render_value(arg, typemap), "type":get_type(arg)}
    ))
    // keyword arguments
    const kws = aslist(typemap[fcall.kwargs.type].fields[1]);
    const newkwargs = fcall.kwargs.fields.map((arg, i)=>(
        {"arg_name":kws[i], "data": render_value(arg, typemap), "type":get_type(arg)}
    ))
    return {"args":newargs, "kwargs":newkwargs,
        "result":render_value(result, typemap),
        "docstring":metamap.docstring,
        "api_julia":"", "api_javascript":"",
        "api_python":"",
    };
}
// get type of an argument safely
function get_type(value){
    if (value === null){
        return "null"
    } else if (value instanceof Object){
        return value.type
    } else {
        return typeof(value)
    }
}
// render the value as a normal JSON object
function render_value(value, typemap){
    if (value instanceof Array){
        return value.map(v=>render_value(v, typemap))
    } else if (value instanceof Object){
        // add fieldnames
        const [typename, fieldnames, fieldtypes] = typemap[value.type].fields;
        return render_object(value.type, aslist(fieldnames), value.fields.map(v=>render_value(v, typemap)));
    } else {
        return value
    }
}
// render an object
function render_object(typename, fieldnames, fields){
    return {"type":typename, "fieldnames":fieldnames, "fields": fields}
}
// create type dictionary from two arrays
function render_dict(adt){
    const _pairs = aslist(adt.fields[0]);
    const result = {};
    _pairs.forEach(pair => result[pair.fields[0]] = pair.fields[1]);
    return result;
}

// source: https://stackoverflow.com/questions/8493195/how-can-i-parse-a-csv-string-with-javascript-which-contains-comma-in-data
function csvToArray(text) {
    let p = '', row = [''], ret = [row], i = 0, r = 0, s = !0, l;
    for (l of text) {
        if ('"' === l) {
            if (s && l === p) row[i] += l;
            s = !s;
        } else if (',' === l && s) l = row[++i] = '';
        else if ('\n' === l && s) {
            if ('\r' === p) row[i] = row[i].slice(0, -1);
            row = ret[++r] = [l = '']; i = 0;
        } else row[i] += l;
        p = l;
    }
    return ret;
};

function listfromstring(s){
    return s.match(/[^,\s?]+/g)
}

// check types
function isarraytype(typename){
    const [primary, params] = decompose_type(typename);
    return primary == 'JugsawIR.JArray'
}
function issimplearraytype(typename){
    const [primary, params] = decompose_type(typename);
    const T = params[0];
    return primary == 'JugsawIR.JArray' && (isstringtype(T) || isbooltype(T) || isfloattype(T) || isintegertype(T) || iscomplextype(T))
}
function decompose_type(typename){
    const re = /(^[a-zA-Z_][a-zA-Z_0-9\.]*!?)\{(.*)\}$/
    const res = typename.match(re)
    if (res !== null){
        return [res[1], listfromstring(res[2])]
    } else {
        return [typename, '']
    }
}

function isintegertype(typename){
    return typename == "Core.Int128" ||
        typename == "Core.Int64" ||
        typename == "Core.Int32" ||
        typename == "Core.Int16" ||
        typename == "Core.Int8" ||
        typename == "Core.UInt128" ||
        typename == "Core.UInt64" ||
        typename == "Core.UInt32" ||
        typename == "Core.UInt16" ||
        typename == "Core.UInt8"
}
function isfloattype(typename){
    return typename == "Core.Float64" ||
        typename == "Core.Float32" ||
        typename == "Core.Float16"
}
function iscomplextype(typename){
    return typename == "Base.Complex{Core.Float64}" ||
        typename == "Base.Complex{Core.Float32}" ||
        typename == "Base.Complex{Core.Float16}"
}
function isbooltype(typename){
    return typename == "Core.Bool"
}
function isstringtype(typename){
    return typename == "Core.String"
}

class ClientContext {
  constructor({endpoint = window.location.href,
      project = "unspecified",
      version = "1.0"}) {
    this.endpoint = endpoint;
    this.project = project;
    this.version = version;
    this.appname = "unspecified";
  }
}

class App {
  constructor(
    appname,
    function_list,
    context){
      this.appname = appname;
      this.function_list = function_list;
      this.context = context;
    }

  call(fname, args, kwargs, ferror=console.log) {
    for (var i=0; i< this.function_list.length; i++){
      const fi = this.function_list[i]
      if (fi.function_name == fname){
        const demo = fi.demo
        const newargs = demo.args.map((darg, i)=>raw2json(args[i], darg.data));
        const newkwargs = demo.kwargs.map((darg,i)=>raw2json(kwargs[i], darg.data));
        return call(context.endpoint, context.project, context.appname, fname,
            {"fields":newargs},
            {"fields":newkwargs}
          ).then(resp=>{
          if (resp.status != 200){
            // call error
            resp.json().then(x=>ferror(x.error));
          } else {
            // an object id is returned
            return resp.json().then(data=>{
              const job_id = data.job_id
              console.log("job id = ", job_id)
              return fetch_result(context.endpoint, job_id).then(resp => {
                if (resp.status == 200){
                    // fetch result with the object id
                    return resp.text().then(ir=>{
                        // the result is returned as a Jugsaw object.
                        const result = ir2adt(ir);
                        return result
                    })
                } else {
                    resp.json().then(x=>ferror(x.error));
                }
              })
            })
          }
        })
      }
    }
  }
}