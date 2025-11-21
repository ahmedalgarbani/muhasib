abstract class BaseSqfliteRepository<T> {
  Future<int> insert(T entity);
  Future<int> update(T entity);
  Future<int> delete(int id);
  Future<T?> getById(int id);
  Future<List<T>> getAll();
  Future<List<T>> getByQuery(String where, List<dynamic> whereArgs);
}
