module Model

import Base: size, show, getindex, iterate, &, |

struct BitBoard <: AbstractArray{Bool, 1}
    board :: UInt64
end

size(bb::BitBoard) = (64,)

# TODO: not really sure how the @inline macro works here
# Also speed up / no bounds?
# https://discourse.julialang.org/t/fast-way-to-access-bits-of-float64/11098
function getindex(bb::BitBoard, i::UInt64)
    bb.board & (1 << (63 & (i - 1)))
end

getindex(bb::BitBoard, i::Integer) = getindex(bb, i % UInt64)

function Base.iterate(bb::BitBoard, state=1)
    state > 64 ? nothing : (bb[state], state + 1)
end

function Base.show(io::IO, bb::BitBoard)
    print(io, bitstring(bb.board))
end

(&)(b1::BitBoard, b2::BitBoard) = BitBoard(b1.board & b2.board)
(&)(b1::BitBoard, b2::Union{Int64, UInt64}) = BitBoard(b1.board & b2)
(&)(b1::Union{Int64, UInt64}, b2::BitBoard) = b2 & b1

(|)(b1::BitBoard, b2::BitBoard) = BitBoard(b1.board | b2.board)
(|)(b1::BitBoard, b2::Union{Int64, UInt64}) = BitBoard(b1.board | b2)
(|)(b1::Union{Int64, UInt64}, b2::BitBoard) = b2 | b1

const SQUARES = [
    "a1", "b1", "c1", "d1", "e1", "f1", "g1", "h1",
    "a2", "b2", "c2", "d2", "e2", "f2", "g2", "h2",
    "a3", "b3", "c3", "d3", "e3", "f3", "g3", "h3",
    "a4", "b4", "c4", "d4", "e4", "f4", "g4", "h4",
    "a5", "b5", "c5", "d5", "e5", "f5", "g5", "h5",
    "a6", "b6", "c6", "d6", "e6", "f6", "g6", "h6",
    "a7", "b7", "c7", "d7", "e7", "f7", "g7", "h7",
    "a8", "b8", "c8", "d8", "e8", "f8", "g8", "h8"
]

const SQUARE_MAPPING = Dict(sqr => idx for (sqr, idx) in zip(SQUARES, 1:64))

alg_sqr_to_board(s::AbstractString) = SQUARE_MAPPING[s]
board_to_alg_sqr(bb::BitBoard) = SQUARES[trailing_zeros(bb.board) + 1]

# TODO: Castling should be some sort of enum
# @enum Castling begin
#   neither = 0
#   king = 1
#   queen = 2
#   both = 3
# end

struct ChessBoard
    w_pawns         :: BitBoard
    w_knights       :: BitBoard
    w_bishops       :: BitBoard
    w_rooks         :: BitBoard
    w_queens        :: BitBoard
    w_kings         :: BitBoard
    b_pawns         :: BitBoard
    b_knights       :: BitBoard
    b_bishops       :: BitBoard
    b_rooks         :: BitBoard
    b_queens        :: BitBoard
    b_kings         :: BitBoard

    w_castle        :: Int64
    b_castle        :: Int64

    whose_move      :: Bool
    en_passant_sqr  :: Union{BitBoard, Nothing}
    half_move_count :: Int64
    move_count      :: Int64
end

const BOARDS = [
    :w_pawns, :w_knights, :w_bishops, :w_rooks, :w_queens, :w_kings,
    :b_pawns, :b_knights, :b_bishops, :b_rooks, :b_queens, :b_kings
]

const piece_to_symbol = Dict(
    :w_pawns => "♙",
    :w_knights => "♘",
    :w_bishops => "♗",
    :w_rooks => "♖",
    :w_queens => "♕",
    :w_kings => "♔",
    :b_pawns => "♟",
    :b_knights => "♞",
    :b_bishops => "♝",
    :b_rooks => "♜",
    :b_queens => "♛",
    :b_kings => "♚"
)
const piece_to_char = Dict(
    :w_pawns => "P",
    :w_knights => "N",
    :w_bishops => "B",
    :w_rooks => "R",
    :w_queens => "Q",
    :w_kings => "K",
    :b_pawns => "p",
    :b_knights => "n",
    :b_bishops => "b",
    :b_rooks => "r",
    :b_queens => "q",
    :b_kings => "k"
)

function to_mailbox(cb::ChessBoard)
    mb = Dict{Int64, Symbol}()
    for board in BOARDS
        b::BitBoard = getfield(cb, board)
        for sqr in 1:64
            if b[sqr] ≠ 0
                other_board = get(mb, sqr, nothing)
                if other_board == nothing
                    mb[sqr] = board
                else
                    throw(ParseError("Chessboard has two pieces ($board, $other_board) in square $sqr"))
                end
            end
        end
    end
    mb
end

# ┌ ─ ┬ ┐ │ └ ─ ┴ ┘ ├ ─ ┼ ┤
function Base.show(io::IO, cb::ChessBoard)
    mb = to_mailbox(cb)
    function piece(sqr)
        p = get(mb, sqr, nothing)
        if p == nothing
            " "
        else
            piece_to_symbol[p]
        end
    end

    # board representation
    s = "┌───" * repeat("┬───", 7) * "┐\n"
    for row in 8:-1:1
        for col in 1:8
            s *= "│ $(piece((row - 1) * 8 + col)) "
        end
        s *= "│\n"
        if row ≠ 1
            s *= "├───" * repeat("┼───", 7) * "┤\n"
        end
    end
    s *= "└───" * repeat("┴───", 7) * "┘\n"

    # additional info
    s *= board_to_fen_extras(cb)
    print(io, s)
end

function board_to_fen(cb::ChessBoard)
    mb = to_mailbox(cb)
    s = ""
    for row in 8:-1:1
        empties = 0
        for col in 1:8
            sqr = (row - 1) * 8 + col
            piece = get(mb, sqr, nothing)
            if piece ≠ nothing
                if empties > 0
                    s *= "$empties"
                    empties = 0
                end
                s *= piece_to_char[piece]
            else
                empties += 1
            end
        end
        if empties > 0
            s *= "$empties"
        end
        if row ≠ 1
            s *= "/"
        else
            s *= " "
        end
    end
    s *= board_to_fen_extras(cb)
    s
end

function board_to_fen_extras(cb::ChessBoard)
    s = ""
    # move
    s *= "$(cb.whose_move ? "b" : "w") "
    # castling
    if cb.w_castle == cb.b_castle == 0
        s *= "- "
    else
        s *= "$(cb.w_castle == 2 || cb.w_castle == 3 ? "K" : "")"
        s *= "$(cb.w_castle == 1 || cb.w_castle == 3 ? "Q" : "")"
        s *= "$(cb.b_castle == 2 || cb.b_castle == 3 ? "k" : "")"
        s *= "$(cb.b_castle == 1 || cb.b_castle == 3 ? "q" : "") "
    end
    # en passant
    s *= "$(cb.en_passant_sqr == nothing ? "-" : board_to_alg_sqr(cb.en_passant_sqr)) "
    # moves
    s *= "$(cb.half_move_count) $(cb.move_count)"
    s
end

struct ParseError <: Exception
    msg :: AbstractString
end

function ChessBoard()
    ChessBoard(BitBoard(0), BitBoard(0), BitBoard(0), BitBoard(0),
               BitBoard(0), BitBoard(0), BitBoard(0), BitBoard(0),
               BitBoard(0), BitBoard(0), BitBoard(0), BitBoard(0),
               0, 0, false, nothing, 0, 0)
end

function ChessBoard(fen::AbstractString)
    split_fen = split(fen, " ")
    if length(split_fen) != 6
        throw(ParseError("Malformed FEN"))
    end

    # boards
    boards = parse_fen_board(split_fen[1])

    # move
    move = parse_fen_move(split_fen[2])

    # castling
    castling = parse_fen_castling(split_fen[3])

    # en passant
    en_passant = parse_fen_en_passant(split_fen[4])

    # half move count
    half_move_count = parse_fen_int(split_fen[5])

    #  move count
    move_count = parse_fen_int(split_fen[6])

    ChessBoard(boards..., castling..., move,
               en_passant, half_move_count, move_count)
end

function parse_fen_board(board_str::AbstractString)
    rows = split(board_str, "/")
    if length(rows) != 8
        throw(ParseError("Board must have 8 rows"))
    end

    w_pawns     = BitBoard(0)
    w_knights   = BitBoard(0)
    w_bishops   = BitBoard(0)
    w_rooks     = BitBoard(0)
    w_queens    = BitBoard(0)
    w_kings     = BitBoard(0)
    b_pawns     = BitBoard(0)
    b_knights   = BitBoard(0)
    b_bishops   = BitBoard(0)
    b_rooks     = BitBoard(0)
    b_queens    = BitBoard(0)
    b_kings     = BitBoard(0)

    for row in 1:8
        col = 1
        for val in rows[row]
            if col > 8
                throw(ParseError("Row does not add to 8 squares"))
            end
            if '1' ≤ val ≤ '8'
                col += val - '0'
                continue
            end
            # FEN and our representation are opposite, the 9 inverts
            square = (8 - row) * 8 + col - 1
            if     val == 'p'
                b_pawns = b_pawns | (1 << square)
            elseif val == 'n'
                b_knights = b_knights | (1 << square)
            elseif val == 'b'
                b_bishops = b_bishops | (1 << square)
            elseif val == 'r'
                b_rooks = b_rooks | (1 << square)
            elseif val == 'q'
                b_queens = b_queens | (1 << square)
            elseif val == 'k'
                b_kings = b_kings | (1 << square)
            elseif val == 'P'
                w_pawns = w_pawns | (1 << square)
            elseif val == 'N'
                w_knights = w_knights | (1 << square)
            elseif val == 'B'
                w_bishops = w_bishops | (1 << square)
            elseif val == 'R'
                w_rooks = w_rooks | (1 << square)
            elseif val == 'Q'
                w_queens = w_queens | (1 << square)
            elseif val == 'K'
                w_kings = w_kings | (1 << square)
            else
                throw(ParseError("Invalid character"))
            end
            col += 1
        end
        if col != 9
            throw(ParseError("Row does not add to 8 squares"))
        end
    end
    (w_pawns, w_knights, w_bishops, w_rooks, w_queens, w_kings,
     b_pawns, b_knights, b_bishops, b_rooks, b_queens, b_kings)
end

function parse_fen_move(move_str::AbstractString)
    if move_str == "w"
        false
    elseif move_str == "b"
        true
    else
        throw(ParseError("Active color must be either w or b"))
    end
end

function parse_fen_castling(castle_str::AbstractString)
    w_castle, b_castle = 0, 0
    if castle_str == "-"
        w_castle, b_castle
    end
    m = match(r"^(K?)(Q?)(k?)(q?)$", castle_str)
    if m == nothing
        throw(ParseError("Malformed Castling string"))
    end
    if m[1] != ""
        w_castle += 2
    end
    if m[2] != ""
        w_castle += 1
    end
    if m[3] != ""
        b_castle += 2
    end
    if m[4] != ""
        b_castle += 1
    end
    w_castle, b_castle
end

function parse_fen_en_passant(en_passant_str::AbstractString)
    if en_passant_str == "-"
        return nothing
    end
    try
        BitBoard(1 << (alg_sqr_to_board(en_passant_str) - 1))
    catch e
        throw(ParseError("En Passant square malformed"))
    end
end

function parse_fen_int(int_str::AbstractString)
    try
        parse(Int64, int_str)
    catch e
        throw(ParseError("Move value malformed"))
    end
end

end # module
