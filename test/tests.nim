import mummy, mummy/routers
import src/mummy_utils
import std/json

proc index(request: Request, details: Details) =
  echo "Http Method:  " & $request.reqMethod
  echo "Path:         " & $request.path
  echo "Query:        " & $request.query
  echo "Body:         " & $request.body
  echo "Host:         " & $request.host
  echo "Path:         " & $request.path
  echo "IP:           " & $request.ip
  echo "Secure:       " & $request.secure
  echo "Header:       " & $request.headers["User-Agent"]
  echo "Header:       " & $request.headers["User-Agentxxx"]
  echo ""

  echo "Params all:"
  for k, v in request.params():
    echo $k & " = " & v
  echo ""

  echo "Params specific: projectID"
  echo " - " & request.params("projectID")
  echo " - " & @"projectID"
  echo ""

  echo "Cookies:"
  for k, v in request.cookies():
    echo " - " & $k & " => " & v
  echo ""

  echo "Cookie specific: _pk_id.ec72"
  echo request.cookies("_pk_id.ec72")
  echo ""

  var headers: httpheaders.HttpHeaders
  setCookie("test", "content")

  resp(Http200, "OK")

proc indexJson(request: Request, details: Details) =
  resp(%* {"message": "Hello, World!"})


var router: Router
router.routerSet(HttpGet, "/", index)
router.routerSet(HttpGet, "/json", indexJson)


#
# Start server
#
let server = newServer(router)

echo "Serving on http://localhost:8080"
server.serve(Port(8080))