import mummy, mummy/routers
import src/mummy_utils
import std/json, std/times, std/unittest

proc index(request: Request) =
  echo "Http Method:  " & $request.reqMethod
  check(request.reqMethod == HttpGet)
  echo "Path:         " & $request.path
  check($request.path == "/")
  echo "Query:        " & $request.query
  check($request.query == "")
  echo "Body:         " & $request.body
  check($request.body == "")
  echo "Host:         " & $request.host
  check($request.host == "127.0.0.1:8080" or $request.host == "localhost:8080")
  echo "Path:         " & $request.path
  check($request.path == "/")
  echo "IP:           " & $request.ip
  check($request.ip == "127.0.0.1")
  echo "Secure:       " & $request.secure
  check(request.secure == false)
  echo "Header:       " & $request.headers["User-Agent"]
  check($request.headers["User-Agent"] != "")
  echo "Header:       " & $request.headers["User-Agentxxx"]
  check($request.headers["User-Agentxxx"] == "")
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
  setCookie("test0", "content")
  setCookie("test1", "expire1", (getTime() + 5.hours), domain = "localhost")
  setCookie("test2", "expire2", expires = $(getTime().utc + initTimeInterval(hours = 1)))

  resp(Http200, "OK")

proc indexJson(request: Request) =
  resp(%* {"message": "Hello, World!"})


var router: Router
router.get("/", index)
router.get("/json", indexJson)



#
# Start server
#
let server = newServer(router)

echo "Serving on http://localhost:8080"
server.serve(Port(8080))