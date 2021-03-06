##### TODO: consider the performance ramifications of making everything immutable
##### Definitions
abstract type Color end
struct White <: Color end
struct Black <: Color end
Color_T = Type{T} where {T<:Color}

abstract type Piece end
abstract type Pawn <: Piece end
abstract type Knight <: Piece end
abstract type Bishop <: Piece end
abstract type Rook <: Piece end
abstract type Queen <: Piece end
abstract type King <: Piece end
Piece_T = Type{T} where {T<:Piece}


# NOTE: Square(0) is a sentinel value for no square
struct Square
    sqr_idx :: UInt8

    function Square(sqr_idx::Integer)
        @assert 0 ≤ sqr_idx ≤ 64
        new(UInt8(sqr_idx))
    end
end

struct BitBoard <: AbstractSet{Square}
    board :: UInt64
    BitBoard(board) = new(board)
end

struct Move
    # https://www.chessprogramming.org/Encoding_Moves
    # stored as
    #   0-5: from square
    #   6-11: to square
    #   12: promotion?
    #   12: capture?
    #   13-14: special bits
    packed_move :: UInt16
end

struct Castling
    data::UInt8
end

mutable struct ChessBoard
    white_pieces    :: BitBoard
    black_pieces    :: BitBoard
    pawns           :: BitBoard
    knights         :: BitBoard
    bishops         :: BitBoard
    rooks           :: BitBoard
    queens          :: BitBoard
    white_king      :: Square
    black_king      :: Square

    castling        :: Castling

    active_color    :: Color_T
    en_passant_sqr  :: Square
    half_move_count :: Int64
    move_count      :: Int64
end

abstract type Direction end
abstract type UpLeft <: Direction end
abstract type Up <: Direction end
abstract type UpRight <: Direction end
abstract type Right <: Direction end
abstract type Left <: Direction end
abstract type DownRight <: Direction end
abstract type Down <: Direction end
abstract type DownLeft <: Direction end
Direction_T = Type{T} where {T<:Direction}

struct MasksAndMagic
    king_attacks         :: Array{BitBoard}
    knight_attacks       :: Array{BitBoard}

    bishop_blocker_masks :: Array{BitBoard}
    bishop_magics        :: Array{UInt64}
    bishop_shifts        :: Array{UInt8}
    bishop_attacks       :: Array{Array{BitBoard}}

    rook_blocker_masks   :: Array{BitBoard}
    rook_magics          :: Array{UInt64}
    rook_shifts          :: Array{UInt8}
    rook_attacks         :: Array{Array{BitBoard}}
end

##### Constructors
# BitBoard(board::Integer) = BitBoard(UInt64(board))
# TODO: look into the efficiency of the 63 &
BitBoard(sqr::Square) = BitBoard(UInt64(1) << (63 & (sqr.sqr_idx - 1)))

Square(rank::Integer, file::Integer) = Square((rank - 1) * 8 + file)
function Square(s::AbstractString)
    if length(s) ≠ 2 || !('a' ≤ s[1] ≤ 'h') || !('1' ≤ s[2] ≤ '8')
        raise("Invalid square string: $s")
    end
    Square(UInt8(s[2] - '1') + 1, UInt8(s[1] - 'a') + 1)
end

Move(from::Square, to::Square) = Move(UInt(from) - 1 + ((UInt(to) - 1) << 6))
Castling(K::Bool, Q::Bool, k::Bool, q::Bool) = Castling(
    (0b0000
     | (K ? 0b0001 : 0b0000)
     | (Q ? 0b0010 : 0b0000)
     | (k ? 0b0100 : 0b0000)
     | (q ? 0b1000 : 0b0000))
)

ChessBoard() = ChessBoard(
        BitBoard(0),
        BitBoard(0),
        BitBoard(0),
        BitBoard(0),
        BitBoard(0),
        BitBoard(0),
        BitBoard(0),
        Square(0),
        Square(0),
        Castling(0),
        White,
        Square(0),
        0,
        1)
