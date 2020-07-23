import Base: show, getindex, &, |, UInt

const bb_empty = BitBoard(0)

@inline UInt(b::BitBoard) = b.board

@inline (&)(b1::BitBoard, b2::BitBoard) = BitBoard(UInt(b1) & UInt(b2))
@inline (&)(b::BitBoard, s::Square) = b & BitBoard(s)
# (&)(b1::BitBoard, b2::Union{Int64, UInt64}) = BitBoard(b1.board & b2)
# (&)(b1::Union{Int64, UInt64}, b2::BitBoard) = b2 & b1

@inline (|)(b1::BitBoard, b2::BitBoard) = BitBoard(UInt(b1) | UInt(b2))
@inline (|)(b::BitBoard, s::Square) = b | BitBoard(s)
# (|)(b1::BitBoard, b2::Union{Int64, UInt64}) = BitBoard(b1.board | b2)
# (|)(b1::Union{Int64, UInt64}, b2::BitBoard) = b2 | b1

show(io::IO, bb::BitBoard) = print(io, bitstring(bb.board))

@inline getindex(bb::BitBoard, sqr::Square) = bb & BitBoard(sqr) != bb_empty
