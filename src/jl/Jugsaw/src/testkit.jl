function launch_and_fetch(r::Server.AppRuntime, fcall::JugsawIR.Call)
    # create a job
    job_id = string(uuid4())
    jobspec = (job_id, round(Int, time()), "jugsaw", 10.0, fcall.fname, fcall.args, fcall.kwargs)
    ir, = JugsawIR.julia2ir(jobspec)
    # create a cloud event
    event_id = string(uuid4())
    req = HTTP.Request("POST", "/events/jobs/", ["Content-Type" => "application/json",
        "ce-id"=>"$event_id", "ce-type"=>"any", "ce-source"=>"any",
        "ce-specversion"=>"1.0"
        ],
        JSON3.write(ir))
    resp1 = Server.job_handler(r, req)

    # fetch interface
    req = HTTP.Request("POST", "/events/jobs/fetch", ["Content-Type" => "application/json"], JSON3.write((; job_id=job_id)))
    resp2 = Server.fetch_handler(r, req)
    if resp2.status == 200
        return resp1, resp2, JugsawIR.ir2adt(JSON3.read(resp2.body).data), job_id
    else
        return resp1, resp2, nothing, job_id
    end
end
