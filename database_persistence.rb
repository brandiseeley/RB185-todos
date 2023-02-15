require "pg"

class DatabasePersistence
  def initialize(logger)
    @database = PG.connect("postgres://postgres:7k6wIiOdZjgYKM7@rb185-todos-db.internal:5432")
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement} : #{params}"
    @database.exec_params(statement, params)
  end

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1"
    tuple = query(sql, id).first
    {id: id, name: tuple["name"], todos: all_todos_from_list(id)}
  end

  # list format : {name: "list name", id: integer, todos: [array of todo hashes]}
  def all_lists
    result = query("SELECT * FROM lists")
    result.map do |tuple|
      list_id = tuple["id"].to_i
      {id: list_id, name: tuple["name"], todos: all_todos_from_list(list_id)}
    end
  end
  
  def create_new_list(list_name)
    sql = "INSERT INTO lists (name) VALUES ($1);"
    query(sql, list_name)
  end
  
  def delete_list(id)
    sql = "DELETE FROM lists WHERE id = $1"
    query(sql, id)
  end
  
  def update_list_name(id, new_name)
    sql = "UPDATE lists SET name = $1 WHERE id = $2"
    query(sql, new_name, id)
  end

  def create_new_todo(list_id, todo_name)
    sql = "INSERT INTO todos (list_id, name) VALUES ($1, $2)"
    query(sql, list_id, todo_name)
  end
  
  def delete_todo_from_list(list_id, todo_id)
    sql = "DELETE FROM todos WHERE list_id = $1 AND id = $2"
    query(sql, list_id, todo_id)
  end
  
  def update_todo_status(list_id, todo_id, new_status)
    sql = "UPDATE todos SET completed = $1 WHERE list_id = $2 AND id = $3"
    query(sql, new_status, list_id, todo_id)
  end
  
  def mark_all_todos_complete(list_id)
    sql = "UPDATE todos SET completed = true WHERE list_id = $1"
    query(sql, list_id)
  end
  
  private

  # retrieves all todos for list with matching id
  # formats results into proper todo hash : {id: integer, name: "todo name", completed: boolean}
  def all_todos_from_list(list_id)
    sql = "SELECT * FROM todos WHERE list_id = $1"
    todos = query(sql, list_id)
    todos.map do |tuple|
      {id: tuple["id"].to_i, name: tuple["name"], completed: tuple["completed"] == "t"}
    end
  end
end
