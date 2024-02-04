---
title: "Start With the Go Standard Library"
date: 2024-02-07T00:01:23-05:00
draft: false
series: []
tags: []
---

When starting a project, new Gophers often ask the following questions.

- What logger should I use?
- What web framework should I use?
- What object–relational mapping (ORM) should I use?

These questions are well-intentioned but they all miss a key aspect about Go.

**Go has a great standard library.**

Let's understand why.

<!--more-->

## What is a Standard Library?

A [standard libary](https://en.wikipedia.org/wiki/Standard_library) is library
of packages that are included with a programming language. These packages can be
used without downloading additional source code.

For example, the following hello world program uses the `fmt` package from the
Go standard library.

```go
package main

import (
	"fmt" // Imported from the Go standard library.
)

func main() {
	fmt.Println("Hello, world!")
}
```

You can run this program like so.

```sh
> go run .
Hello, world!
```

Contrast this with the following hello world program that uses the third-party
`github.com/fatih/color` package.

```go
package main

import (
	"github.com/fatih/color" // Imported from the downloaded source code.
)

func main() {
	// Prints `Hello, world!` in bold red.
	c := color.New(color.FgRed).Add(color.Bold)
	c.Println("Hello, world!")
}
```

Since the `github.com/fatih/color` package is not in the Go standard library,
you must download its source code and all its dependencies before it can be
used.

```sh
> go run .
go: downloading github.com/fatih/color v1.16.0
go: downloading github.com/mattn/go-colorable v0.1.13
go: downloading github.com/mattn/go-isatty v0.0.20
go: downloading golang.org/x/sys v0.14.0
Hello, world!
```

Documentation for both the Go standard library and third-party packages can be
found at [pkg.go.dev](https://pkg.go.dev).

- Standard library: [pkg.go.dev/std](https://pkg.go.dev/std)
- Third-party packages: [pkg.go.dev](https://pkg.go.dev)

## Why Start With the Go Standard Library?

When deciding whether to use the Go standard library or a third-party package,
one might think the decision comes down to the quality of the package. While
quality is a factor, generally speaking, there isn't much of a quality
difference between the Go standard library and well-written, well-maintained
third-party packages.

Determining the quality of a package can be both objective and subjective
depending on the metric being measured. Luckily there are many resources out
there to help you, including the popular [OpenSSF Scorecard](https://github.com/ossf/scorecard).

Quality aside, I recommend new Gophers start with the Go standard library for
the following reasons.

- **Stability** - The stability of the Go standard library is in its name—
  standard. The Go standard library exposes a standard set of APIs that rarely
  change, making them a great candidate for building higher level abstractions.
  Combine that with Go's [Backward Compatibility](https://go.dev/blog/compat)
  and the stability of the Go standard library really shines.
- **Extensibility** - The Go standard library is quite extensive. There are
  packages for logging, interacting with the OS, communicating over the network,
  and much more. The Go standard library also exposes interfaces such as
  `io.Reader` that programs can implement to provide custom behavior that's
  compatible with standard library APIs.
- **Maintainability** - The best code is the code that you can use but don't
  have to maintain. The Go standard library is maintained by engineers that are
  paid to work on Go. This means you don't have to worry about a package in the
  standard library being out of date or incompatible with your version of Go.
- **No Dependencies** - You don't have to download additional source code to use
  the Go standard library, it's already there with your installation of Go. This
  means fewer dependencies in your code which can lead to quicker CI/CD build
  times and fewer security vulnerabilities.
- **Reduced Lock-In** - Many third-party packages maintain API compatibility
  with the Go standard library. Others don't. Using the Go standard library can
  make it easier to migrate from the standard library to compatible third-party
  packages and vice versa.

## The Go Standard Library vs. Third-Party Packages

Now that we have a better understanding of the Go standard library let's answer
some of those questions that new Gophers tend to ask.

We'll use a question-driven approach, comparing the Go standard library to
third-party packages.

### What Logger Should I Use?

Standard library:
- [log](https://pkg.go.dev/log)
- [log/slog](https://pkg.go.dev/log/slog)

Third-party packages:
- [github.com/hashicorp/go-hclog](https://pkg.go.dev/github.com/hashicorp/go-hclog)
- [github.com/sirupsen/logrus](https://pkg.go.dev/github.com/sirupsen/logrus)
- [go.uber.org/zap](https://pkg.go.dev/go.uber.org/zap)

Prior to Go 1.21 the standard library only had the `log` package, which did not
support log levels or structured logging. For those unfamiliar, structured
logging is the ability to log information in a machine-readable format that can
be parsed by your favorite log aggregation tool. Usually structured logs are
emitted using JSON syntax and contain key-value pairs of information.

Since the `log` package doesn't support log levels or structured logging,
third-party packages became the primary way to log in Go. In
[Go 1.21](https://go.dev/blog/go1.21), the `log/slog` package was introduced
with support for log levels and structured logging. I recommend new Gophers
start with `log/slog` for their logging needs.

This code example shows the API differences between `log`, `log/slog`, and
`go.uber.org/zap`.

```go
package main

import (
	"log"
	"log/slog"
	"os"

	"go.uber.org/zap"
)

const (
	// Simulate information from an HTTP request.
	method = "GET"
	path   = "/api/v1/users"
)

func main() {
	// log
	stdLog := log.New(os.Stdout, "", log.LstdFlags)
	stdLog.Printf("request received: method=%s path=%s", method, path)

	// log/slog
	stdSLog := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{}))
	stdSLog.Info("request received:",
		"method", method,
		"path", path,
	)

	// go.uber.org/zap
	zapLogger, _ := zap.NewProduction()
	defer zapLogger.Sync()
	zapLogger.Info("request received:",
		zap.String("method", method),
		zap.String("path", path),
	)
}
```

This code example highlights the `log` package's lack of support for key-value
pairs when compared to `log/slog` and `go.uber.org/zap`.

Running the code shows how different the `log` output is from the `log/slog` and
`go.uber.org/zap` output.

```sh
> go run .
2024/02/04 22:20:03 request received: method=GET path=/api/v1/users
{"time":"2024-02-04T22:20:03.140393797-05:00","level":"INFO","msg":"request received:","method":"GET","path":"/api/v1/users"}
{"level":"info","ts":1707103203.1404333,"caller":"helloworld/main.go:32","msg":"request received:","method":"GET","path":"/api/v1/users"}
```

### What Web Framework Should I Use?

Standard library:
- [net/http](https://pkg.go.dev/net/http)

Third-party packages:
- [github.com/dimfeld/httptreemux](https://pkg.go.dev/github.com/dimfeld/httptreemux)
- [github.com/gin-gonic/gin](https://pkg.go.dev/github.com/gin-gonic/gin)
- [github.com/go-chi/chi](https://pkg.go.dev/github.com/go-chi/chi)
- [github.com/gobuffalo/buffalo](https://pkg.go.dev/github.com/gobuffalo/buffalo)
- [github.com/gofiber/fiber](https://pkg.go.dev/github.com/gofiber/fiber)
- [github.com/gorilla/mux](https://pkg.go.dev/github.com/gorilla/mux)
- [github.com/labstack/echo](https://pkg.go.dev/github.com/labstack/echo)

This question can be difficult to answer, especially for engineers coming from
web frameworks like Next.js, Laravel, Django, Ruby on Rails, etc. Go doesn't
have a web framework as extensive as those from other languages. The closest
you'll find is `github.com/gobuffalo/buffalo`, but even that isn't as featureful
as something like Ruby on Rails.

Instead of a web framework, Go encourages you to choose an HTTP multiplexer and
extend it as needed. That's why the list of third-party packages above is
primarily filled with HTTP multiplexers instead of web frameworks. Want to use
`net/http` with React? Sure thing! How about `github.com/go-chi/chi` with Go
templates? Go for it! The truth is it doesn't matter much what HTTP multiplexer
you use, so choose the one that you're most familiar with and can get help with
when needed.

I recommend new Gophers running [Go 1.22](https://go.dev/blog/go1.22) or later
start with `net/http` for their HTTP multiplexing needs. In Go 1.22, the
`net/http` package received major quality of life updates such as the ability to
register an HTTP handler with an HTTP method and the ability to use and retrieve
URL path variables. These updates make the `net/http` package an attractive
choice compared third-party packages.

Prior to Go 1.22, the `net/http` package didn't support these features, making
third-party packages the popular route (pun intended) for Gophers. If you're
working on a project that isn't on Go 1.22 or later then I recommend choosing a
third-party package for your HTTP multiplexing needs. I personally like
`github.com/go-chi/chi`, but `github.com/labstack/echo` and
`github.com/gofiber/fiber` are also popular choices, especially for those
familiar with Express.

This code example shows the API differences between Go 1.22's `net/http`,
`github.com/go-chi/chi`, and `github.com/labstack/echo`.

```go
package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/go-chi/chi"
	"github.com/labstack/echo"
)

type Response struct {
	ID      string `json:"id"`
	HTTPMux string `json:"http_mux"`
}

func main() {
	// net/http
	stdMux := http.NewServeMux()
	stdMux.HandleFunc("GET /api/v1/{id}", func(w http.ResponseWriter, r *http.Request) {
		id := r.PathValue("id")
		resp := Response{ID: id, HTTPMux: "net/http"}
		if err := json.NewEncoder(w).Encode(resp); err != nil {
			// Handle error.
		}
	})

	// github.com/go-chi/chi
	chiMux := chi.NewMux()
	chiMux.Get("/api/v1/{id}", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")
		resp := Response{ID: id, HTTPMux: "github.com/go-chi/chi"}
		if err := json.NewEncoder(w).Encode(resp); err != nil {
			// Handle error.
		}
	})

	// github.com/labstack/echo
	echoMux := echo.New()
	echoMux.GET("/api/v1/:id", func(ctx echo.Context) error {
		id := ctx.Param("id")
		resp := Response{ID: id, HTTPMux: "github.com/labstack/echo"}
		return ctx.JSON(http.StatusOK, resp)
	})

	// Start all three HTTP multiplexers asynchronously.
	for i, mux := range []http.Handler{stdMux, chiMux, echoMux} {
		go func(portOffset int, mux http.Handler) {
			server := http.Server{
				Addr:    fmt.Sprintf(":%d", 3000+portOffset),
				Handler: mux,
			}
			fmt.Printf("Listening on %s...\n", server.Addr)
			_ = server.ListenAndServe()
		}(i, mux)
	}

	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, syscall.SIGTERM, syscall.SIGINT)

	fmt.Println("Press Ctrl+C to stop.")
	<-shutdown
}
```

I know that's a lot of code, but I wanted you to see that there are minimal API
differences across packages. They all support URL path variables and follow the
same basic structure to create HTTP handlers. The noteworthy differences are:
- `net/http` registers an HTTP handler with an HTTP method by specifying the
  HTTP method within `HandleFunc` (e.g., `HandleFunc("GET /foo", ...)`). The other
  packages expose specific `.GET`, `.POST`, etc. methods for this.
- `github.com/labstack/echo` does not use the
  [http.HandlerFunc](https://pkg.go.dev/net/http#HandlerFunc) function signature
  from the Go standard library. Instead it uses a custom function signature that
  returns an `error`, which can make error handling easier at the cost of API
  compatibility with the Go standard library.

If you're running Go 1.22, you can run this code like so.

```sh
> go run .
Listening on :3001...
Listening on :3000...
Listening on :3002...
Press Ctrl+C to stop.
```

> **Note**: Ensure your `go.mod` file contains `go 1.22` or later otherwise Go
> will use the older Go 1.21 and earlier `net/http` behavior.

From another terminal you can connect to each endpoint to see its response.

```sh
> curl http://localhost:3000/api/v1/1337
{"id":"1337","http_mux":"net/http"}

> curl http://localhost:3001/api/v1/1337
{"id":"1337","http_mux":"github.com/go-chi/chi"}

> curl http://localhost:3002/api/v1/1337
{"id":"1337","http_mux":"github.com/labstack/echo"}
```

### What Object–Relational Mapping (ORM) Should I Use?

Standard library:
- [database/sql](https://pkg.go.dev/database/sql)

Third-party packages:
- [github.com/gobuffalo/pop](https://pkg.go.dev/github.com/gobuffalo/pop/v6)
- [github.com/jmoiron/sqlx](https://pkg.go.dev/github.com/jmoiron/sqlx)
- [github.com/sqlc-dev/sqlc](https://pkg.go.dev/github.com/sqlc-dev/sqlc)
- [gorm.io/gorm](https://pkg.go.dev/gorm.io/gorm)

This question can also be difficult to answer, especially if engineers have
strong opinions about writing SQL. I've witnessed many engineers spend more
debating this question than building their application.

Before I answer this question let's define what an object-relational mapping is.
An
[object-relational mapping](https://en.wikipedia.org/wiki/Object%E2%80%93relational_mapping)
is a way to map objects in a programming language (i.e., Go structs) into
database relations (i.e., tables) and vice versa.

For example, an object-relational mapping takes the following Go struct.

```go
type Avenger struct {
  ID   int 
  Name string
  Age  int
}
```

And maps its fields to the columns in the following database table.

```sql
CREATE TABLE avengers (
    id SERIAL,
    name TEXT NOT NULL,
    age INT NOT NULL,

    PRIMARY KEY (id)
);
```

This allows you to interact with your database from your code without needing to
understand how to serialize and deserialize the raw bytes to and from the
database.

Like most terms in the technology industry, object-relational mapping is
overloaded. Most programming languages have functionality in their standard
library to interact with a database using a database driver and raw SQL queries.
Isn't that an object-relational mapping? Not quite. An object-relational mapping
extends and abstracts the standard library APIs, providing a new API using the
programming language itself without the engineer needing to write any SQL. In
practice it looks something like this.

Database interaction using the standard library.

```go
type Avenger struct {
	ID   int
	Name string
	Age  int
}

row := db.QueryRow("SELECT * FROM avengers WHERE id = 1")
if err := row.Err(); err != nil {
	// Handle error.
}

var a Avenger
if err := row.Scan(&a.ID, &a.Name, &a.Age); err != nil {
	// Handle error.
}
```

Database interaction using an object-relational mapping.

```go
type Avenger struct {
	gorm.Model

	ID   int
	Name string
	Age  int
}

var a Avenger
result := db.First(&a, 1)
if err := Result.Error; err != nil {
	// Handle error.
}
```

The standard library interaction:
- Requires you to write the raw SQL query
- Scans individual database columns into Go variables
- Does not modify your Go struct type

In contrast, the object-relational mapping interaction:
- Abstracts away the raw SQL query
- Scans database columns as a group into a Go struct
- Modifies your Go struct type with an embedded type

As an engineer you'll have to weigh these considerations and decide which
approach is best for you. I recommend new Gophers start with either
`database/sql` or `github.com/jmoiron/sqlx` for their database needs. They both
have a simple API and allow you to write SQL queries, which is a great skill to
have as an engineer. Even though `database/sql` requires you to scan database
columns individually, it's more explicit and can help prevent cases where some
columns weren't scanned successfully. As your project grows you can decide if
migrating to an object-relational mapping such as `gorm.io/gorm` is worth it.

Alternatively, you can check out `github.com/sqlc-dev/sqlc` which is somewhat in
between the standard library and an object-relational mapping. While some people
call this an object-relational mapping, it's really more of a code generation
tool that takes raw SQL queries and builds the necessary Go structs and
functions. It's quite a useful tool that I've used in production at a few
companies.

I know that was a lot of content. A code example might help you compare
`database/sql`, `github.com/jmoiron/sqlx`, and `gorm.io/gorm` for yourself.

First, you'll need a database. Let's create a Marvel themed PostgreSQL database
using a container.

```sh
podman run --rm --detach \
    --name shield_db \
    --env POSTGRES_USER=fury \
    --env POSTGRES_PASSWORD=fury \
    --env POSTGRES_DB=shield \
    --publish 5432:5432 \
    postgres:16
```

> **Note**: Substitute `podman` with `docker` if you're using Docker.

Create a `seed.sql` file with the following content. We'll use this to create
our database table and insert some data into it.

```sql
CREATE TABLE avengers (
    id SERIAL,
    name TEXT NOT NULL,
    age INT NOT NULL,

    PRIMARY KEY (id)
);

INSERT INTO avengers (
    name, age
) VALUES
    ('Steve Rogers', 105),
    ('Tony Stark', 53);
```

Run the `seel.sql` file to create the database table and insert some data into
it.

```sh
> podman exec -i shield_db psql -U fury -d shield < seed.sql
CREATE TABLE
INSERT 0 2
```

This code example shows the API differences between `database/sql`,
`github.com/jmoiron/sqlx`, and `gorm.io/gorm`.

```go
package main

import (
	"database/sql"
	"fmt"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"     // PostgreSQL database driver for sql and sqlx.
	"gorm.io/driver/postgres" // PostgreSQL database driver for gorm.
	"gorm.io/gorm"
)

const (
	dbDriver = "postgres"
	dbURL    = "postgres://fury:fury@localhost:5432/shield?sslmode=disable"
)

type Avenger struct {
	ID   int    `db:"id"`
	Name string `db:"name"`
	Age  int    `db:"age"`
}

func main() {
	// database/sql
	a1, err := runStdDB()
	if err != nil {
		// Handle error.
	}

	// github.com/jmoiron/sqlx
	a2, err := runSqlxDB()
	if err != nil {
		// Handle error.
	}

	// gorm.io/gorm
	a3, err := runGormDB()
	if err != nil {
		// Handle error.
	}

	fmt.Printf("database/sql:\n\t%v\n", a1)
	fmt.Printf("github.com/jmoiron/sqlx:\n\t%v\n", a2)
	fmt.Printf("gorm.io/gorm:\n\t%v\n", a3)
}

// database/sql
func runStdDB() (*Avenger, error) {
	stdDB, err := sql.Open(dbDriver, dbURL)
	if err != nil {
		return nil, err
	}
	defer stdDB.Close()

	row := stdDB.QueryRow("SELECT * FROM avengers WHERE id = 1")
	if err := row.Err(); err != nil {
		return nil, err
	}

	var a Avenger
	if err := row.Scan(&a.ID, &a.Name, &a.Age); err != nil {
		return nil, err
	}

	return &a, nil
}

// github.com/jmoiron/sqlx
func runSqlxDB() (*Avenger, error) {
	sqlxDB, err := sqlx.Open(dbDriver, dbURL)
	if err != nil {
		return nil, err
	}
	defer sqlxDB.Close()

	var a Avenger
	if err := sqlxDB.Get(&a, "SELECT * FROM avengers WHERE id = 1"); err != nil {
		return nil, err
	}

	return &a, nil
}

// gorm.io/gorm
func runGormDB() (*Avenger, error) {
	gormDB, err := gorm.Open(postgres.Open(dbURL), &gorm.Config{})
	if err != nil {
		return nil, err
	}
	defer func() {
		db, _ := gormDB.DB()
		db.Close()
	}()

	var a Avenger
	result := gormDB.First(&a, 1)
	if err := result.Error; err != nil {
		return nil, err
	}

	return &a, nil
}
```

I've already detailed some of the differences between these packages earlier,
but you can see how the SQL query and scanning gets more abstracted as you move
away from `database/sql` and towards `gorm.io/gorm`.

Go ahead and run this code to see the output.

```sh
> go run .
database/sql:
        &{1 Steve Rogers 105}
github.com/jmoiron/sqlx:
        &{1 Steve Rogers 105}
gorm.io/gorm:
        &{1 Steve Rogers 105}
```

When you're finished, stop and remove the running PostgreSQL container.

```sh
> podman rm -f shield_db
shield_db
```

## Final Thoughts

Thank you for reading the entire post to completion. I know that was a lot of
content, but I hope you enjoyed it and learned more about Go.

We covered what a standard library is, why you should start with the Go standard
library, and compared the Go standard library with third-party packages. I hope
you were able to see just how great the Go standard library is, especially with
the changes in [Go 1.22](https://go.dev/blog/go1.22).

Next time you have questions about which package to use for your Go project,
take the time to research whether the Go standard library has a package that
meets your needs. I suspect you'll find a package that does meet your needs and
you'll agree when I say:

**Go has a great standard library.**

Actually, I'll take that one step further and end this post with:

**Go has a great standard library, and you should start with it.**
