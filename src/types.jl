##### Definitions
abstract type Color end
struct White <: Color end
struct Black <: Color end

abstract type Piece end
abstract type Pawn <: Piece end
abstract type Knight <: Piece end
abstract type Bishop <: Piece end
abstract type Rook <: Piece end
abstract type Queen <: Piece end
abstract type King <: Piece end

struct BitBoard
    board :: UInt64
end

struct Square
    sqr_idx :: UInt8

    function Square(sqr_idx::Integer)
        @assert 1 ≤ sqr_idx ≤ 64
        new(UInt8(sqr_idx))
    end
end


struct ChessBoard
    our_pieces      :: BitBoard
    their_pieces    :: BitBoard
    pawns           :: BitBoard
    knights         :: BitBoard
    bishops         :: BitBoard
    rooks           :: BitBoard
    queens          :: BitBoard
    our_king        :: Square
    their_king      :: Square

    castling        :: UInt8

    active_color    :: Type{T} where {T <: Color}
    # TODO: look into having Square(0) be a sentinel value
    en_passant_sqr  :: Union{Square, Nothing}
    half_move_count :: Int64
    move_count      :: Int64
end

##### Constructors
BitBoard(board::Integer) = BitBoard(UInt64(board))
# TODO: look into the efficitency of the 63 &
BitBoard(sqr::Square) = BitBoard(UInt64(1) << (63 & (sqr.sqr_idx - 1)))

Square(rank::Integer, file::Integer) = Square((rank - 1) * 8 + file)
function Square(s::AbstractString)
    if length(s) ≠ 2 || !('a' ≤ s[1] ≤ 'h') || !('1' ≤ s[2] ≤ '8')
        raise("Invalid square string: $s")
    end
    Square(UInt8(s[2] - '1') + 1, UInt8(s[1] - 'a') + 1)
end
