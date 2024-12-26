import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/json
import gleam/list
import gleam/result
import simplifile
import youid/uuid

// La palabra clave `opaque` hace que el tipo sea público pero fuera
// del módulo solo se puede construir el tipo utilizando un constructor
// que realice algún tipo de restricción o acción específica. VER:
// https://tour.gleam.run/advanced-features/opaque-types/
//
pub opaque type Connection {
  Connection(root: String)
}

pub fn connect(root: String) -> Connection {
  let assert Ok(_) = simplifile.create_directory_all(root)

  Connection(root)
}

pub fn disconnect(_connection: Connection) -> Nil {
  // Aquí no hacemos nada, pero una base de datos real
  // cerraría la conexión o haría algún otro `desmontaje`.

  Nil
}

pub fn with_connection(root: String, f: fn(Connection) -> t) -> t {
  let connection = connect(root)
  let result = f(connection)
  disconnect(connection)

  result
}

pub fn truncate(connection: Connection) -> Result(Nil, Nil) {
  let assert Ok(_) = simplifile.delete(connection.root)

  Ok(Nil)
}

pub fn list(connection: Connection) -> Result(List(String), Nil) {
  let assert Ok(_) = simplifile.create_directory_all(connection.root)

  simplifile.read_directory(connection.root) |> result.replace_error(Nil)
}

pub fn insert(
  connection: Connection,
  values: Dict(String, String),
) -> Result(String, Nil) {
  let assert Ok(_) = simplifile.create_directory_all(connection.root)

  let id = uuid.v4_string()
  let values =
    values
    |> dict.to_list
    |> list.map(fn(pair) { #(pair.0, json.string(pair.1)) })
  let json = json.to_string(json.object(values))

  use _ <- result.try(
    simplifile.write(file_path(connection, id), json)
    |> result.replace_error(Nil),
  )

  Ok(id)
}

pub fn read(
  connection: Connection,
  id: String,
) -> Result(Dict(String, String), Nil) {
  use data <- result.try(
    simplifile.read(file_path(connection, id))
    |> result.replace_error(Nil),
  )

  let decoder = dynamic.dict(dynamic.string, dynamic.string)

  use data <- result.try(
    json.decode(data, decoder)
    |> result.replace_error(Nil),
  )

  Ok(data)
}

fn file_path(connection: Connection, id: String) -> String {
  connection.root <> "/" <> id
}