import app/layout/layout.{generate_layout}
import app/web.{type Context}
import gleam/dict
import gleam/http.{Get, Post}
import gleam/list
import gleam/result
import utilities/tiny_database
import wisp.{type Request, type Response}

/// El modelo de los datos
/// 
pub type Book {
  Book(title: String, author: String)
}

pub fn home_page(req: Request) -> Response {
  // Solo se puede acceder a la página de inicio mediante solicitudes GET,
  // por lo que este middleware se utiliza para devolver una respuesta 405: 
  // `Método no permitido` para todos los demás métodos.
  use <- wisp.require_method(req, Get)

  let html =
    generate_layout(
      "<h1 class='text-2xl font-bold'>¡Guarda la lista de tus Libros 😀!</h1>
    
       <ul class='flex flex-col items-start w-fit mt-8 ml-36 list-disc'>
          <li class='hover:text-sky-500 ease-in duration-300'><a href='/books'>Lista tus libros guardados</a></li>
          <li class='hover:text-sky-500 ease-in duration-300'><a href='/show_form'>Guarda un libro en la lista</a></li>
       </ul>",
    )

  wisp.html_response(html, 200)
}

pub fn show_form(req: Request) -> Response {
  use <- wisp.require_method(req, Get)

  // En una aplicación más grande, se podría usar
  // aquí una biblioteca de plantillas o una biblioteca
  // de formularios HTML en lugar de un literal de cadena.
  let html =
    generate_layout(
      "<form action='/books' method='post' class='rounded-xl drop-shadow-xl flex flex-col mx-auto gap-4 w-96 p-8'>
        <label class='flex flex-col text-start justify-start gap-2 cursor-pointer'>Title:
            <input class='input input-bordered input-primary bg-slate-800' type='text' name='title' autofocus required>
        </label>
        <label class='flex flex-col text-start justify-start gap-2 cursor-pointer'>Autor:
            <input class='input input-bordered input-primary bg-slate-800' type='text' name='author' required>
        </label>
        <button class='badge badge-primary px-6 py-3 hover:scale-[1.1]' type='submit'>Guardar</button>
      </form>
      <div class='mt-8'>
        <a class='btn btn-secondary btn-outline' href='/'>Página de Inicio ←</a>
      </div>",
    )

  wisp.ok() |> wisp.html_body(html)
}

// Este controlador de solicitudes se utiliza para solicitudes a `/books`.
//
pub fn all(req: Request, ctx: Context) -> Response {
  // Envia al controlador apropiado según el método HTTP.
  // Este controlador para `/books` puede responder tanto a solicitudes
  // `GET` como `POST`, por lo que hacemos una coincidencia
  // de patrones en el método aquí.
  case req.method {
    Get -> list_books(ctx)
    Post -> create_book(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

pub fn one(req: Request, id: String, ctx: Context) -> Response {
  // Enviar al controlador apropiado según el método HTTP.
  case req.method {
    Get -> read_book(ctx, id)
    _ -> wisp.method_not_allowed([Get])
  }
}

fn list_books(ctx: Context) -> Response {
  // En un ejemplo posterior mostraremos cómo leer desde una base de datos.
  let result = {
    // Obtiene todos los Ids de la base de datos.
    use ids <- result.try(tiny_database.list(ctx.db))

    let html =
      list.map(ids, fn(id) {
        "<li class='pl-2 lowercase hover:text-sky-500 ease-in duration-300'><a href='/books/"
        <> id
        <> "'>"
        <> id
        <> "</a></li>"
      })
      |> list.fold("", fn(a, b) { a <> b })

    // Alternativa: convierte los Ids en un array JSON de objetos.
    // Ok(
    //   json.to_string_tree(
    //     json.object([
    //       #(
    //         "books",
    //         json.array(ids, fn(id) { json.object([#("id", json.string(id))]) }),
    //       ),
    //     ]),
    //   ),
    // )

    // Convierte los Ids en lista HTML ordenada.
    Ok(generate_layout(
      "<h2 class='text-xl font-semibold'>Tu lista de Libros</h2>"
      <> "<ol class='flex flex-col items-start w-fit mt-8 ml-36 list-decimal'>"
      <> html
      <> "</ol>"
      <> "<div class='mt-16'>
        <a class='btn btn-secondary btn-outline' href='/'>Página de Inicio ←</a>
      </div>",
    ))
  }

  case result {
    // Cuando todo va bien devolvemos una respuesta 200 con el HTML.
    Ok(html) -> wisp.html_response(html, 200)
    // En un ejemplo posterior veremos cómo devolver errores
    // específicos al usuario según lo que haya fallado.
    // Por ahora, solo devolveremos un error 500.
    Error(Nil) -> wisp.internal_server_error()
  }
}

fn create_book(req: Request, ctx: Context) -> Response {
  // Este middleware parsea un `wisp.FormData`
  // del cuerpo de la solicitud. Devuelve una respuesta de error
  // si el cuerpo no contiene datos de formulario válidos, o
  // si el tipo de contenido no es `application/x-www-form-urlencoded` o
  // `multipart/form-data`, o si el cuerpo es demasiado grande.
  use formdata <- wisp.require_form(req)

  // Los módulos `gleam/list` y `gleam/result` se utilizan aquí para extraer
  // los valores de los datos del formulario.
  // Alternativamente, también puedes hacer una coincidencia de patrones en la
  // lista de valores (están ordenados en orden alfabético) o utilizar una 
  // biblioteca de formularios HTML.
  let result = {
    use title <- result.try(list.key_find(formdata.values, "title"))
    use author <- result.try(list.key_find(formdata.values, "author"))

    let book = Book(title, author)

    // Guarda el objeto `book` en la base de datos
    use id <- result.try(save_to_database(ctx.db, book))

    let html =
      "<h2 class='text-xl font-semibold lowercase'><span class='normal-case'>Libro Guardado con ID: </span>"
      <> id
      <> "</h2>"
      <> "<div class='mt-16'>
      <a class='btn btn-secondary btn-outline' href='/'>Página de Inicio ←</a>
    </div>"

    // Alternativa: construye un payload JSON con el ID del libro recién creado.
    // Ok(json.to_string_tree(json.object([#("id", json.string(id))])))
    Ok(generate_layout(html))
  }

  // Devuelve una respuesta apropiada dependiendo de si todo salió bien o
  // si hubo un error.
  case result {
    Ok(html) -> wisp.html_response(html, 201)
    Error(Nil) -> wisp.unprocessable_entity()
  }
  // let html = string_tree.from_string("¡Created!")
  // wisp.ok() |> wisp.html_body(html)
}

fn read_book(ctx: Context, id: String) -> Response {
  let result = {
    // Lee un `book` con el ID proporcionada desde la base de datos.
    use book <- result.try(read_from_database(ctx.db, id))

    let html = "
    <h2 class='text-xl font-semibold'>Detalle del libro:</h2>

    <ul class='flex flex-col items-start w-fit mt-8 ml-36 list-disc'>
        <li class='lowercase text-amber-700'><span class='uppercase'>ID: </span>" <> id <> "</li>
        <li class='font-medium text-sky-400 italic'><span class='not-italic'>Título: </span>" <> book.title <> "</li>
        <li class='text-sky-400'>Autor: " <> book.author <> "</li>
    </ul>" <> "<div class='mt-16'>
      <a class='btn btn-secondary btn-outline' href='/'>Página de Inicio ←</a>
    </div>"

    // Alternativa: construye un payload HTML con detalles del libro (`book`).
    // Ok(
    //   json.to_string_tree(
    //     json.object([
    //       #("id", json.string(id)),
    //       #("title", json.string(book.title)),
    //       #("author", json.string(book.author)),
    //     ]),
    //   ),
    // )
    Ok(generate_layout(html))
  }

  // Devuelve un `Response` apropiado.
  case result {
    Ok(html) -> wisp.html_response(html, 200)
    Error(Nil) -> wisp.not_found()
  }
}

/// Guarda una persona en la base de datos y devuelve
/// el ID del registro recién creado.
/// 
pub fn save_to_database(
  db: tiny_database.Connection,
  book: Book,
) -> Result(String, Nil) {
  // En una aplicación real, podrías usar un cliente
  // de base de datos con algo de SQL aquí. En lugar de eso,
  // creamos un diccionario simple y lo guardamos.
  let data = dict.from_list([#("title", book.title), #("author", book.author)])

  tiny_database.insert(db, data)
}

/// Recupera de la base de datos un objeto `book` dada su `id`
/// 
pub fn read_from_database(
  db: tiny_database.Connection,
  id: String,
) -> Result(Book, Nil) {
  // En una aplicación real, es posible que utilices
  // un cliente de base de datos con algo de SQL aquí.
  use data <- result.try(tiny_database.read(db, id))
  use title <- result.try(dict.get(data, "title"))
  use author <- result.try(dict.get(data, "author"))

  Ok(Book(title, author))
}
