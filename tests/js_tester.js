/*

nim c -d:dev -r "test/testreadme.nim"

# Copy paste below into developer console

*/

// /project/@projectID/info
fetch("/project/112/info?invoiceID=99", {
  method: "GET"
})
// This is a redirect 303
.then(response => {
  if (response.status === 200) {
    return response.json();
  } else {
    throw new Error("Unexpected response");
  }
})
.then(data => {
  if (data.projectID === "112" && data.invoiceID === "99") {
    console.log("Success");
  } else {
    throw new Error("Unexpected response");
  }
});



fetch("/redirect", {
  method: "GET"
})
// This is a redirect 303
.then(response => {
  if (response.status === 200) {
    console.log("Success");
  } else {
    throw new Error("Unexpected response");
  }
});



document.cookie = "pass=nonono;";
fetch("/headers", {
  method: "GET"
})
.then(response => {
  if (response.status === 401) {
    console.log("Success");
  } else {
    throw new Error("Unexpected response");
  }
})
.catch(error => {
});

document.cookie = "pass=1234567890;";
fetch("/headers", {
  method: "GET",
})
.then(response => {
  if (response.status === 200 && response.headers.get("xauth") == "secret") {
    console.log("Success");
  } else {
    throw new Error("Unexpected response");
  }
});
document.cookie = "";


fetch("/headers", {
  method: "HEAD"
})
.then(response => {
  if (response.status === 200) {
    console.log("Success");
  } else {
    throw new Error("Unexpected response");
  }
});


fetch("/headers?projectID=112", {
  method: "POST",
  body: JSON.stringify({"msg": "Hello"})
})
.then(response => {
  if (response.status === 200) {
    return response.text();
  } else {
    throw new Error("Unexpected response");
  }
})
.then(data => {
  if (data === "Hello") {
    console.log("Success");
  } else {
    throw new Error("Unexpected response");
  }
});


fetch("/file/pic.jpeg", {
  method: "GET"
})
.then(response => {
  if (response.status === 200) {
    console.log("Success");
  } else {
    throw new Error("Unexpected response");
  }
});


fetch("/inline", {
  method: "GET"
})
.then(response => {
  if (response.status === 200) {
    return response.text();
  } else {
    throw new Error("Unexpected response");
  }
})
.then(data => {
  if (data === "Hello") {
    console.log("Success");
  } else {
    throw new Error("Unexpected response");
  }
});