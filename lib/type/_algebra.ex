defprotocol Type.Algebra do
  @spec usable_as(Type.t, Type.t, keyword) :: Type.ternary
  def usable_as(subject, target, meta)

  @spec subtype?(Type.t, Type.t) :: boolean
  def subtype?(subject, target)

  @spec compare(Type.t, Type.t) :: :gt | :eq | :lt
  def compare(a, b)

  @spec typegroup(Type.t) :: Type.group
  def typegroup(type)

  @spec intersect(Type.t, Type.t) :: Type.t
  def intersect(ltype, rtype)

  @spec subtract(Type.t, Type.t) :: Type.t
  def subtract(ltype, rtype)

  @spec normalize(Type.t) :: Type.t
  def normalize(type)

  @spec merge(Type.t, Type.t) :: :nomerge | {:merge, [Type.t]}
  def merge(ltype, rtype)
end
