import Base: UInt, show, summary, union, intersect, -, symdiff, in, first, last, iterate, empty, ==, length, <<, >>
import Combinatorics: combinations

# implementation of AbstractSet
#   + union
#   + intersect
#   + setdiff
#   + symdiff
# extras
#   + complement
#   + empty

@inline UInt(b::BitBoard) = b.board
# show(bb::BitBoard) = show(io::IO, ::MIME"text/plain", bb::BitBoard)
function show(io::IO, bb::BitBoard)
    s = ""
    for rank in 8:-1:1
        for file in 1:8
            s *= (Square(rank, file) ∈ bb) ? "x" : "."
        end
        s *= (rank ≠ 1) ? "\n" : ""
    end
    print(io, s)
end
show(io::IO, ::MIME"text/plain", bb::BitBoard) = show(io, bb)
# summary(io::IO, bb::BitBoard) = print(io, "BitBoard")

@inline union(b1::BitBoard, b2::BitBoard) = BitBoard(UInt(b1) | UInt(b2))
@inline union(b::BitBoard, sqr::Square) = b ∪ BitBoard(sqr)
@inline union(sqrs) = reduce(∪, sqrs, init=BitBoard(0))

@inline intersect(b1::BitBoard, b2::BitBoard) = BitBoard(UInt(b1) & UInt(b2))
@inline intersect(b::BitBoard, sqr::Square) = b ∩ BitBoard(sqr)

@inline complement(b::BitBoard) = BitBoard(~UInt(b))
@inline (-)(b::BitBoard) = complement(b)

@inline setdiff(b1::BitBoard, b2::BitBoard) = b1 ∩ -b2
@inline (-)(b1::BitBoard, b2::BitBoard) = setdiff(b1, b2)
@inline setdiff(b::BitBoard, s::Square) = b - BitBoard(s)
@inline (-)(b::BitBoard, s::Square) = setdiff(b, s)

@inline symdiff(b1::BitBoard, b2::BitBoard) = BitBoard(UInt(b1) ⊻ UInt(b2))

@inline in(s::Square, b::BitBoard) = UInt(b ∩ s) ≠ 0
# @inline in(::Integer, b::BitBoard) = throw("Use a Square")

@inline first(b::BitBoard) = Square(trailing_zeros(UInt(b)) + 1)
@inline last(b::BitBoard) = Square(64 - leading_zeros(UInt(b)))

@inline length(b::BitBoard) = count_ones(UInt(b))

function iterate(b::BitBoard, idx=1)
    if idx ≥ 65
        return nothing
    end
    while Square(idx) ∉ b
        if idx == 64
            return nothing
        end
        idx += 1
    end
    Square(idx), idx + 1
end

@inline eltype(::BitBoard) = Square

@inline empty(::BitBoard) = BitBoard(0x0)

@inline (==)(b1::BitBoard, b2::BitBoard) = UInt(b1) == UInt(b2)

@inline (<<)(b::BitBoard, i::Integer) = BitBoard(UInt(b) << i)
@inline (>>)(b::BitBoard, i::Integer) = BitBoard(UInt(b) >> i)

# https://www.chessprogramming.org/Flipping_Mirroring_and_Rotating
# vertically flips the board, inspiration from lc0
# function flip(b::BitBoard)
#     k1 = 0x00FF00FF00FF00FF
#     k2 = 0x0000FFFF0000FFFF
#     x = UInt(b)
#     x = ((x >> 8 ) & k1) | ((x & k1) << 8)
#     x = ((x >> 16) & k2) | ((x & k2) << 16)
#     x =  (x >> 32)       |  (x       << 32)
#     BitBoard(x)
# end

function combinations(b::BitBoard)
    indexed_squares = [(i, s) for (i, s) in enumerate(b)]
    reduce_by_idx(indices) = ∪(s for (i, s) in indexed_squares if Square(i) ∈ BitBoard(indices))
    [reduce_by_idx(indices) for indices in 0:2^length(b)-1]
end
