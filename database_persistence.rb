require "pg"
require "pry-byebug"

class DatabasePersistence
  def initialize(logger)
    # @database = PG.connect("postgres://postgres:hKwNmkuPct45C32@rb185-todo-db.internal:5432")
    @database = PG.connect(dbname: "todos")
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement} : #{params}"
    @database.exec_params(statement, params)
  end

  def find_list(id)
    sql = <<-SQL
    SELECT lists.*,
      COUNT(todos.id) AS todos_count,
      COUNT(NULLIF(todos.completed, true)) AS todos_remaining_count
      FROM lists LEFT OUTER JOIN todos
      ON lists.id = todos.list_id
      WHERE lists.id = $1
      GROUP BY lists.id;
  SQL

    tuple = query(sql, id).first
    tuple_to_list_hash(tuple)
  end

  # list format : {name: "list name", id: integer, todos_count: integer, todos_remaining_count: integer}
  def all_lists
    sql = <<-SQL
      SELECT lists.*,
        COUNT(todos.id) AS todos_count,
        COUNT(NULLIF(todos.completed, true)) AS todos_remaining_count
        FROM lists LEFT OUTER JOIN todos
        ON lists.id = todos.list_id
        GROUP BY lists.id
        ORDER BY lists.name;
    SQL

    result = query(sql)
    result.map do |tuple|
      tuple_to_list_hash(tuple)
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
  
  # retrieves all todos for list with matching id
  # formats results into proper todo hash : {id: integer, name: "todo name", completed: boolean}
  def all_todos_from_list(list_id)
    sql = "SELECT * FROM todos WHERE list_id = $1"
    todos = query(sql, list_id)
    todos.map do |tuple|
      {id: tuple["id"].to_i, name: tuple["name"], completed: tuple["completed"] == "t"}
    end
  end

  private

  def tuple_to_list_hash(tuple)
    { id: tuple["id"].to_i, 
    name: tuple["name"], 
    todos_count: tuple["todos_count"].to_i, 
    todos_remaining_count: tuple["todos_remaining_count"].to_i }
  end
end
