struct Basic end

@abstract Basic getfield(m::Const{Module}, f::Const{Symbol}) =
  Const(getfield(m.value, f.value))

@abstract Basic getfield(m::T, f::Const{Symbol}) where T =
  fieldtype(T, f.value)

@abstract Basic Core.apply_type(Ts::Const...) =
  Const(Core.apply_type(map(T -> T.value, Ts)...))

@abstract Basic (<:)(S::Type, T::Type) = Const(widen(S) <: widen(T))

@abstract Basic typeof(x::Const) = Const(widen(x))
@abstract Basic typeof(x::T) where T =
  isconcretetype(T) ? Const(T) : Type

@abstract Basic (isa)(x, ::Type{T}) where T = Const(widen(x) <: T)

@abstract Basic fieldtype(T::Const{<:Type}, f::Const{<:Union{Symbol,Integer}}) =
  Const(fieldtype(T.value, f.value))

@abstract Basic convert(::Const{Type{T}}, x::Const{<:Number}) where T<:Number =
  Const(convert(T, x.value))

@abstract Basic typeassert(x::X, ::Type{T}) where {T,X<:T} = x

@abstract Basic print(args...) = Nothing
@abstract Basic println(args...) = Nothing

@abstract Basic ifelse(c::Const{Bool}, a, b) =
  c.value ? a : b

@abstract Basic ifelse(c::Bool, a, b) = Union{widen(a),widen(b)}

@abstract Basic !(::Bool) = Bool
@abstract Basic !(x::Const{Bool}) = Const(!x.value)

effectful(::AType{typeof(print)}, args...) = true
effectful(::AType{typeof(println)}, args...) = true
effectful(::AType{typeof(setindex!)}, args...) = true

@pure Basic repr, isdefined

@abstract Basic Core.sizeof(s::Const{String}) = Const(Core.sizeof(s.value))
@abstract Basic length(s::Const{String}) = Const(length(s.value))
@abstract Basic getindex(s::Const{String}, i::Const{<:Integer}) = Const(getindex(s.value, i.value))

# Tweaked kwarg func handling

struct KwFunc{F} end

@abstract Basic Core.kwfunc(::T) where T = Const(KwFunc{T}())

instead(::Basic, args, ::AType{KwFunc{F}}, kw, f, xs...) where F =
  args, (Core.kwftype(widen(f)), kw, f, xs...)
