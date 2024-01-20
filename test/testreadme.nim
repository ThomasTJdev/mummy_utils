
import std/[json, options]

import mummy, mummy/routers
import src/mummy_utils


proc indexParams(request: Request, details: Details) =
  # Named parameter from route URL
  echo "projectID:  " & @"projectID"

  # URI query param passed with ?invoiceID=123
  echo "invoiceID:  " & @"invoiceID"

  resp(Http200, %* {"message": "Hello, World!"})


proc indexRedirect(request: Request, details: Details) =
  redirect("/project/123/info")
  # redirect(Http301, "/project/123/info")


proc indexHeaders(request: Request, details: Details) =
  var headers: HttpHeaders
  if request.cookies("pass") == "1234567890":
    setHeader("xauth", "secret")
  else:
    resp(Http401, "Not authorized")

  setHeader("Content-Type", "text/html")
  resp(Http200, headers, "<h1>Hello, World!</h1>")


proc indexHead(request: Request, details: Details) =
  resp Http200


proc indexPost(request: Request, details: Details) =
  let urlParam = @"projectID"
  if urlParam == "":
    resp(Http400, "Missing projectID")

  let body = parseJson(request.body)

  resp(Http200, ContentType.Text, body["msg"].getStr())


proc indexFile(request: Request, details: Details) =
  sendFile("filepath/" & @"filename")


proc indexMultipart(request: Request, details: Details) =
  var file: string
  for entry in request.multipart:
    if entry.data.isSome and entry.name == "croppedImage":
      let (start, last) = entry.data.get
      file = request.body[start .. last]
      break

  # Do something with file
  resp Http204


var router: Router
router.routeSet(HttpGet, "/project/@projectID/info", indexParams)
router.routeSet(HttpGet, "/redirect", indexRedirect)
router.routeSet(HttpGet, "/headers", indexHeaders)
router.routeSet(HttpHead, "/headers", indexHead)
router.routeSet(HttpPost, "/headers", indexPost)
router.routeSet(HttpGet, "/file/@filename", indexFile)
router.routeSet(HttpPost, "/multipart", indexMultipart)

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))