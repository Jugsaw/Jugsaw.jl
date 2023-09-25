//  Jugsaw Extension
//===============================
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
        body: JSON.stringify(jobspec, null, 4)
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