
import std/[json, options]

import mummy, mummy/routers
import src/mummy_utils


proc indexParams(request: Request) =
  # Named parameter from route URL
  echo "projectID:  " & @"projectID"

  # URI query param passed with ?invoiceID=123
  echo "invoiceID:  " & @"invoiceID"

  resp(Http200, %* {"message": "Hello, World!", "projectID": @"projectID", "invoiceID": @"invoiceID"})


proc indexRedirect(request: Request) =
  redirect("/project/123/info")
  # redirect(Http301, "/project/123/info")


proc indexHeaders(request: Request) =
  var headers: HttpHeaders
  if request.cookies("pass") == "1234567890":
    setHeader("xauth", "secret")
  else:
    resp(Http401, "Not authorized")

  setHeader("Content-Type", "text/html")
  resp(Http200, headers, "<h1>Hello, World!</h1>")


proc indexHead(request: Request) =
  resp Http200


proc indexPost(request: Request) =
  let urlParam = @"projectID"
  if urlParam == "":
    resp(Http400, "Missing projectID")

  let body = parseJson(request.body)

  resp(Http200, ContentType.Text, body["msg"].getStr())


proc indexFile(request: Request) =
  # sendFile("filepath/" & @"filename")
  sendFile("test/file/" & @"filename")


proc indexMultipart(request: Request) =
  var file: string
  for entry in request.multipart:
    if entry.data.isSome and entry.name == "croppedImage":
      let (start, last) = entry.data.get
      file = request.body[start .. last]
      break

  # Do something with file
  resp Http204


var router: Router
router.get("/project/@projectID/info", indexParams)
router.get("/redirect", indexRedirect)
router.get("/headers", indexHeaders)
router.head("/headers", indexHead)
router.post("/headers", indexPost)
router.get("/file/@filename", indexFile)
router.post("/multipart", indexMultipart)
router.get("/inline", proc(request: Request) =
  resp(Http200, ContentType.Text, "Hello")
)

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
