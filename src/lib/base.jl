struct Basic end

abstract(::Basic, ::AType{typeof(getfield)}, m::Const{Module}, f::Const{Symbol}) =
  Const(getfield(m.value, f.value))

abstract(::Basic, ::AType{typeof(getfield)}, m::AType{T}, f::Const{Symbol}) where T =
  fieldtype(T, f.value)

abstract(::Basic, ::AType{typeof(Core.apply_type)}, Ts::Const...) =
  Const(Core.apply_type(map(T -> T.value, Ts)...))

abstract(::Basic, ::AType{typeof(typeof)}, x::Const) = Const(widen(x))
abstract(::Basic, ::AType{typeof(typeof)}, x::AType{T}) where T =
  isconcretetype(T) ? Const(T) : Type

abstract(::Basic, ::AType{typeof(fieldtype)}, T::Const{<:Type}, f::Const{<:Union{Symbol,Integer}}) =
  Const(fieldtype(T.value, f.value))

abstract(::Basic, ::AType{typeof(convert)}, ::Const{Type{T}}, x::Const{<:Number}) where T<:Number =
  Const(convert(T, x.value))

abstract(::Basic, ::AType{typeof(typeassert)}, x::Const, T::Const) =
  Const(typeassert(x.value, T.value))

abstract(::Basic, ::AType{typeof(print)}, args...) = Nothing
abstract(::Basic, ::AType{typeof(println)}, args...) = Nothing

effectful(::AType{typeof(print)}, args...) = true
effectful(::AType{typeof(println)}, args...) = true
effectful(::AType{typeof(setindex!)}, args...) = true

@pure Basic repr, Core.kwfunc, isdefined
