module Jugsaw

export serve

using HTTP
using JSON3

#####
# Routers
#####

const ROUTER = HTTP.Router()

HTTP.register!(ROUTER, "GET", "/healthz", _ -> "{\"status\": \"OK\"}")

function serve()
    HTTP.serve(ROUTER)
end

end # module
